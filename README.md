# Google Photos ReVanced Patcher

Automated GitHub Actions workflow to patch Google Photos APK with ReVanced.

## Features

- 🔧 Automatically downloads latest ReVanced CLI and patches
- 📱 Patches Google Photos APK from APK Mirror URLs
- ⚡ Manual workflow trigger for on-demand patching
- 📦 Downloads patched APK as workflow artifacts
- 🔑 Includes keystore for consistency
- 🤖 **Automated script for trigger + install**

## Quick Start (Automated Script)

Use the included script for complete automation:

```bash
./patch-and-install.sh "https://your-apk-mirror-download-url"
```

Or run interactively:
```bash
./patch-and-install.sh
```

### What the script does:
1. ✅ Triggers the GitHub Actions workflow
2. ⏳ Waits for patching to complete
3. 📥 Downloads the patched APK
4. 🔍 Checks for connected Android devices
5. 📲 Installs the patched APK via ADB

### Prerequisites:
- [GitHub CLI](https://cli.github.com/) installed and authenticated
- `jq` installed (`sudo apt install jq`)
- Android SDK with ADB at `~/Android/Sdk/platform-tools/adb`
- Android device with USB debugging enabled

## Manual Usage (GitHub Web)

1. Go to the **Actions** tab in this repository
2. Select **"Patch Google Photos with ReVanced"** workflow
3. Click **"Run workflow"**
4. Enter the Google Photos APK download URL from APK Mirror
5. Optionally specify ReVanced CLI/patches versions (leave blank for latest)
6. Click **"Run workflow"** to start
7. Download the patched APK from the workflow artifacts when complete

## Finding APK URLs

1. Visit [APK Mirror](https://www.apkmirror.com/apk/google-inc/photos/)
2. Choose your desired Google Photos version
3. Click on the APK variant you want (e.g., arm64-v8a, nodpi)
4. Click the "Download APK" button
5. On the download page, **right-click the download button** and **"Copy link address"**
6. Use this direct download URL

⚠️ **Important**: Use the direct download URL that looks like:
`https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=...`

## Notes

- Patched APK will be available for 30 days as workflow artifact
- Both the patched APK and keystore are included in downloads
- This modifies the original Google Photos APK - use at your own risk
- The automation script handles everything from trigger to installation