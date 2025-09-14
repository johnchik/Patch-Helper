#!/bin/bash

# Google Photos ReVanced Patcher & Installer
# Automates workflow trigger, download, and installation

set -e

# Configuration
REPO="johnchik/Patch-Helper"
WORKFLOW_FILE="patch-google-photos.yml"
ADB_PATH="$HOME/Android/Sdk/platform-tools/adb"
MAX_WAIT_TIME=1800  # 30 minutes
POLL_INTERVAL=30    # 30 seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it from: https://cli.github.com/"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it: sudo apt install jq"
        exit 1
    fi
    
    if [ ! -f "$ADB_PATH" ]; then
        print_error "ADB not found at $ADB_PATH"
        print_info "Please install Android SDK or update the ADB_PATH in this script"
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Check GitHub authentication
check_auth() {
    print_info "Checking GitHub authentication..."
    if ! gh auth status --hostname github.com &> /dev/null; then
        print_error "Not authenticated with GitHub CLI for github.com"
        print_info "Run: gh auth login --hostname github.com"
        exit 1
    fi
    print_success "GitHub authentication verified for github.com"
}

# Get APK URL from user
get_apk_url() {
    if [ -n "$1" ]; then
        APK_URL="$1"
    else
        echo -n "Enter APK Mirror download URL: "
        read -r APK_URL
    fi
    
    if [ -z "$APK_URL" ]; then
        print_error "APK URL is required"
        exit 1
    fi
    
    print_info "Using APK URL: $APK_URL"
}

# Trigger the workflow
trigger_workflow() {
    print_info "Triggering GitHub Actions workflow..."
    
    GH_HOST=github.com gh workflow run "$WORKFLOW_FILE" \
        --repo "$REPO" \
        --field apk_url="$APK_URL"
    
    print_success "Workflow triggered successfully"
    sleep 5  # Give GitHub a moment to register the run
}

# Get the latest workflow run ID
get_latest_run_id() {
    print_info "Getting latest workflow run ID..."
    
    RUN_ID=$(GH_HOST=github.com gh run list \
        --repo "$REPO" \
        --workflow="$WORKFLOW_FILE" \
        --limit=1 \
        --json databaseId \
        --jq '.[0].databaseId')
    
    if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
        print_error "Could not get workflow run ID"
        exit 1
    fi
    
    print_info "Monitoring run ID: $RUN_ID"
}

# Wait for workflow completion
wait_for_completion() {
    print_info "Waiting for workflow to complete..."
    print_info "This may take 5-15 minutes depending on download speeds"
    
    local elapsed=0
    
    while [ $elapsed -lt $MAX_WAIT_TIME ]; do
        STATUS=$(GH_HOST=github.com gh run view "$RUN_ID" --repo "$REPO" --json status --jq '.status')
        CONCLUSION=$(GH_HOST=github.com gh run view "$RUN_ID" --repo "$REPO" --json conclusion --jq '.conclusion')
        
        case "$STATUS" in
            "completed")
                if [ "$CONCLUSION" = "success" ]; then
                    print_success "Workflow completed successfully!"
                    return 0
                else
                    print_error "Workflow failed with conclusion: $CONCLUSION"
                    print_info "Check the workflow logs at: https://github.com/$REPO/actions/runs/$RUN_ID"
                    exit 1
                fi
                ;;
            "in_progress"|"queued")
                print_info "Workflow status: $STATUS (elapsed: ${elapsed}s)"
                ;;
            *)
                print_error "Unexpected workflow status: $STATUS"
                exit 1
                ;;
        esac
        
        sleep $POLL_INTERVAL
        elapsed=$((elapsed + POLL_INTERVAL))
    done
    
    print_error "Workflow timed out after $MAX_WAIT_TIME seconds"
    exit 1
}

# Download and extract artifacts
download_artifacts() {
    print_info "Downloading workflow artifacts..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download artifacts
    if ! GH_HOST=github.com gh run download "$RUN_ID" --repo "$REPO"; then
        print_error "Failed to download artifacts"
        exit 1
    fi
    
    # Find the APK file
    APK_FILE=$(find . -name "*.apk" -type f | head -n 1)
    
    if [ -z "$APK_FILE" ]; then
        print_error "No APK file found in artifacts"
        print_info "Available files:"
        find . -type f
        exit 1
    fi
    
    # Move APK to current directory
    APK_NAME=$(basename "$APK_FILE")
    mv "$APK_FILE" "$OLDPWD/$APK_NAME"
    cd "$OLDPWD"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    print_success "Downloaded: $APK_NAME"
    PATCHED_APK="$APK_NAME"
}

# Check ADB devices
check_adb_devices() {
    print_info "Checking connected Android devices..."
    
    "$ADB_PATH" devices
    
    DEVICE_COUNT=$("$ADB_PATH" devices | grep -c "device$" || true)
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_warning "No devices connected"
        print_info "Please connect your Android device and enable USB debugging"
        echo -n "Press Enter when device is connected..."
        read -r
        check_adb_devices
    elif [ "$DEVICE_COUNT" -eq 1 ]; then
        print_success "Found 1 connected device"
    else
        print_success "Found $DEVICE_COUNT connected devices"
    fi
}

# Uninstall existing ReVanced Google Photos
uninstall_existing() {
    print_info "Attempting to uninstall existing ReVanced Google Photos..."
    print_info "This will fail silently if the app is not installed, which is fine."
    
    # Try to uninstall ReVanced Google Photos (will fail silently if not installed)
    if "$ADB_PATH" uninstall app.revanced.android.photos 2>/dev/null; then
        print_success "Successfully uninstalled existing ReVanced Google Photos"
    else
        print_info "No existing ReVanced Google Photos found (or uninstall failed)"
    fi
}

# Install APK
install_apk() {
    print_info "Installing patched Google Photos APK..."
    
    if "$ADB_PATH" install --user 0 "$PATCHED_APK"; then
        print_success "APK installed successfully!"
        print_info "You can now launch Google Photos on your device"
    else
        print_error "Failed to install APK"
        print_info "Trying to install as system app replacement..."
        
        # Try installing with replace flag
        if "$ADB_PATH" install -r --user 0 "$PATCHED_APK"; then
            print_success "APK installed successfully with replace flag!"
            print_info "You can now launch Google Photos on your device"
        else
            print_error "Installation failed even with replace flag"
            print_info "Manual steps you can try:"
            print_info "1. adb uninstall com.google.android.apps.photos"
            print_info "2. adb uninstall app.revanced.android.photos"
            print_info "3. Manually uninstall Google Photos from device settings"
            print_info "4. Enable 'Install unknown apps' in device settings"
            exit 1
        fi
    fi
}

# Cleanup
cleanup() {
    if [ -f "$PATCHED_APK" ]; then
        print_info "Cleaning up downloaded APK..."
        rm -f "$PATCHED_APK"
        print_success "Cleanup complete"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Google Photos ReVanced Patcher & Installer${NC}"
    echo "=============================================="
    
    check_dependencies
    check_auth
    get_apk_url "$1"
    trigger_workflow
    get_latest_run_id
    wait_for_completion
    download_artifacts
    check_adb_devices
    uninstall_existing
    install_apk
    
    echo
    print_success "Process completed successfully! 🎉"
    print_info "Your device now has the patched Google Photos installed"
    
    # Ask if user wants to keep the APK
    echo -n "Keep the downloaded APK file? (y/N): "
    read -r KEEP_APK
    if [[ ! "$KEEP_APK" =~ ^[Yy]$ ]]; then
        cleanup
    fi
}

# Handle Ctrl+C
trap cleanup EXIT

# Run main function
main "$@"