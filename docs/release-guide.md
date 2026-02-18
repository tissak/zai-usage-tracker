# Release Guide for ZaiUsageTracker

This guide walks through building, signing, notarizing, and releasing a production version of **ZaiUsageTracker** for macOS.

Following these steps ensures your app runs on other users' Macs without security warnings ("App is damaged" or "Unidentified developer").

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Create Developer ID Certificate](#step-1-create-developer-id-certificate)
3. [Step 2: Configure Xcode Project](#step-2-configure-xcode-project)
4. [Step 3: Store Notarization Credentials](#step-3-store-notarization-credentials)
5. [Step 4: Build & Release](#step-4-build--release)
6. [Step 5: Upload to GitHub](#step-5-upload-to-github)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

| Item | How to Get |
|------|------------|
| Apple Developer Program membership | [Enroll here](https://developer.apple.com/programs/) ($99/year) |
| Developer ID Application certificate | See [Step 1](#step-1-create-developer-id-certificate) |
| App-Specific Password | See [Step 3](#step-3-store-notarization-credentials) |

### Verify Your Setup

```bash
# Check for code signing certificates
security find-identity -v -p codesigning
```

You should see `Developer ID Application: Your Name (TEAM_ID)` in the output.

---

## Step 1: Create Developer ID Certificate

### 1.1 Generate a Certificate Signing Request (CSR)

1. Open **Keychain Access** (in `/Applications/Utilities/`)
2. Menu: **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**
3. Fill in:
   - **User Email Address**: Your Apple ID email
   - **Common Name**: Your name
   - **Request is**: Saved to disk
4. Click **Continue** and save the `.certSigningRequest` file

### 1.2 Create the Certificate on Apple's Portal

1. Go to [Apple Developer Portal - Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click the **+** button
3. Select **Developer ID Application** (under "Software")
4. Click **Continue**
5. Upload the CSR file you created in step 1.1
6. Click **Continue** → **Download** the certificate

### 1.3 Install the Certificate

1. Double-click the downloaded `.cer` file
2. It will install into your **login** keychain
3. Verify installation:

```bash
security find-identity -v -p codesigning
```

You should now see:
```
1) XXXXXXXX... "Developer ID Application: Your Name (TEAM_ID)"
```

---

## Step 2: Configure Xcode Project

### 2.1 Enable Hardened Runtime (Required for Notarization)

1. Open `zai-usage-tracker/ZaiUsageTracker.xcodeproj` in Xcode
2. Select the **ZaiUsageTracker** target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **Hardened Runtime**

> **Note**: If "Hardened Runtime" is greyed out, ensure your deployment target is macOS 10.15 or later.

### 2.2 Configure Signing

Still in **Signing & Capabilities**:

1. **Team**: Select your team (the one from your Developer ID certificate)
2. **Bundle Identifier**: Should be `com.zaiusagetracker` (or your registered App ID)
3. **Signing Certificate**: Set to **Developer ID Application**

### 2.3 Verify Build Settings

```bash
# Check that Hardened Runtime is enabled
xcodebuild -project zai-usage-tracker/ZaiUsageTracker.xcodeproj \
  -scheme ZaiUsageTracker \
  -showBuildSettings | grep ENABLE_HARDENED_RUNTIME
```

Should output: `ENABLE_HARDENED_RUNTIME = YES`

---

## Step 3: Store Notarization Credentials

Apple requires an **App-Specific Password** for notarization (not your Apple ID password).

### 3.1 Create an App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Scroll to **App-Specific Passwords**
4. Click the **+** button
5. Label it: `NotaryTool` (or similar)
6. **Copy the generated password** (you won't see it again)

### 3.2 Store Credentials in Keychain

This allows `notarytool` to access your credentials without prompting each time:

```bash
xcrun notarytool store-credentials "zai-notary" \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Replace:
- `your-email@example.com` — Your Apple ID email
- `YOUR_TEAM_ID` — Your 10-character team ID (find it in [Developer Portal](https://developer.apple.com/account))
- `xxxx-xxxx-xxxx-xxxx` — The app-specific password from step 3.1

When prompted for a password, enter your **Mac login password** (this stores the credentials in your keychain).

### 3.3 Verify

```bash
xcrun notarytool history --keychain-profile "zai-notary"
```

If successful, you'll see a list of past submissions (may be empty).

---

## Step 4: Build & Release

### Option A: Use the Automated Script (Recommended)

```bash
# From project root
./scripts/build_release.sh zai-notary
```

The script will:
1. Read version from `Info.plist`
2. Archive the app
3. Export with Developer ID signing
4. Submit for notarization
5. Wait for approval
6. Staple the notarization ticket
7. Create final distributable ZIP

Output will be in `./build/ZaiUsageTracker-v{version}.zip`

### Option B: Manual Build

#### 4.1 Clean and Archive

```bash
# Clean previous builds
xcodebuild clean \
  -project zai-usage-tracker/ZaiUsageTracker.xcodeproj \
  -scheme ZaiUsageTracker

# Create archive
xcodebuild archive \
  -project zai-usage-tracker/ZaiUsageTracker.xcodeproj \
  -scheme ZaiUsageTracker \
  -archivePath ./build/ZaiUsageTracker.xcarchive
```

#### 4.2 Export Signed App

First, create your `exportOptions.plist` from the template:

```bash
# Copy the template
cp exportOptions.plist.example exportOptions.plist

# Edit with your Team ID
# Replace YOUR_TEAM_ID with your 10-character team ID
open -e exportOptions.plist
```

Then export:

```bash
xcodebuild -exportArchive \
  -archivePath ./build/ZaiUsageTracker.xcarchive \
  -exportPath ./build/Export \
  -exportOptionsPlist exportOptions.plist
```

#### 4.3 Notarize

```bash
# Create zip for notarization
ditto -c -k --keepParent "./build/Export/ZaiUsageTracker.app" "./build/ZaiUsageTracker.zip"

# Submit for notarization
xcrun notarytool submit "./build/ZaiUsageTracker.zip" \
  --keychain-profile "zai-notary" \
  --wait

# If successful, staple the ticket
xcrun stapler staple "./build/Export/ZaiUsageTracker.app"
```

#### 4.4 Package for Distribution

```bash
# Get version
VERSION=$(plutil -extract CFBundleShortVersionString raw zai-usage-tracker/ZaiUsageTracker/Info.plist)

# Create final distributable
ditto -c -k --keepParent "./build/Export/ZaiUsageTracker.app" "./build/ZaiUsageTracker-v${VERSION}.zip"
```

---

## Step 5: Upload to GitHub

1. Go to your repository on GitHub
2. Click **Releases** (right sidebar) → **Draft a new release**
3. **Choose a tag**: Create new tag (e.g., `v1.0.0`)
4. **Release title**: `v1.0.0` (or descriptive title)
5. **Description**: Add release notes
6. **Attach binaries**: Drag `ZaiUsageTracker-v1.0.0.zip` from `./build/`
7. Click **Publish release**

### Using GitHub CLI (Alternative)

```bash
gh release create v1.0.0 \
  ./build/ZaiUsageTracker-v1.0.0.zip \
  --title "v1.0.0" \
  --notes "Release notes here"
```

---

## Troubleshooting

### "Command CodeSign failed with a nonzero exit code"

- Ensure your Developer ID certificate is in Keychain
- Verify the certificate hasn't expired
- Unlock your keychain: `security unlock-keychain`

### "Hardened Runtime" option not available

- Ensure deployment target is macOS 10.15+
- You're using a Developer ID certificate (not Apple Development)

### Notarization fails with "The signature of the binary is invalid"

- Ensure Hardened Runtime is enabled
- Check that you're signing with Developer ID Application (not Apple Development)
- Verify the app builds without errors before archiving

### Notarization fails with "The binary is not signed"

- Run the export step again with correct signing settings
- Verify `CODE_SIGN_IDENTITY` in build settings

### Users see "App is damaged and can't be opened"

This means the app isn't properly notarized. Ensure:
1. Notarization completed successfully (check `xcrun notarytool history`)
2. Stapling was successful (`xcrun stapler staple`)
3. You're distributing the stapled app (from `./build/Export/`), not the original archive

### Users still see "Unidentified developer"

- Verify the app is signed with Developer ID Application certificate
- Check notarization status: `spctl -a -t exec -vvv ./build/Export/ZaiUsageTracker.app`

---

## Quick Reference

```bash
# Check signing certificates
security find-identity -v -p codesigning

# Check if app is properly signed
codesign -dv --verbose=4 ./build/Export/ZaiUsageTracker.app

# Verify notarization
spctl -a -t exec -vvv ./build/Export/ZaiUsageTracker.app

# Check notarization history
xcrun notarytool history --keychain-profile "zai-notary"

# Get notarization log for a submission
xcrun notarytool log <submission-id> --keychain-profile "zai-notary"
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `exportOptions.plist.example` | Template for Xcode export config (copy to `exportOptions.plist` and add your Team ID) |
| `scripts/build_release.sh` | Automated build, sign, notarize, package script |
| `./build/` | Build output directory (created by script) |
