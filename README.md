# Google Photos ReVanced Patcher

Automated GitHub Actions workflow to patch Google Photos APK with ReVanced.

## Features

- 🔧 Automatically downloads latest ReVanced CLI and patches
- 📱 Patches Google Photos APK from APK Mirror URLs
- ⚡ Manual workflow trigger for on-demand patching
- 📦 Downloads patched APK as workflow artifacts
- 🔑 Includes keystore for consistency

## How to Use

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
3. Download the APK and copy the direct download URL
4. Use this URL in the workflow input

## Notes

- Patched APK will be available for 30 days as workflow artifact
- Both the patched APK and keystore are included in downloads
- This modifies the original Google Photos APK - use at your own risk