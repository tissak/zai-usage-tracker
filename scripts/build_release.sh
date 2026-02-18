#!/bin/bash

#
# build_release.sh - Build, sign, notarize, and package ZaiUsageTracker
#
# Usage:
#   ./scripts/build_release.sh [keychain-profile]
#
# Examples:
#   ./scripts/build_release.sh              # Prompts for keychain profile
#   ./scripts/build_release.sh zai-notary   # Uses "zai-notary" profile
#
# Prerequisites:
#   - Developer ID Application certificate installed in Keychain
#   - Hardened Runtime enabled in Xcode project
#   - Notarization credentials stored in keychain (see release-guide.md)
#

set -e

# MARK: - Configuration

PROJECT_NAME="ZaiUsageTracker"
PROJECT_PATH="zai-usage-tracker/ZaiUsageTracker.xcodeproj"
SCHEME="ZaiUsageTracker"
INFO_PLIST="zai-usage-tracker/ZaiUsageTracker/Info.plist"
BUILD_DIR="./build"
EXPORT_OPTIONS_PLIST="exportOptions.plist"

# MARK: - Colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# MARK: - Helper Functions

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

die() {
    print_error "$1"
    exit 1
}

# MARK: - Prerequisite Checks

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for Developer ID certificate
    echo "Checking for Developer ID Application certificate..."
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        die "Developer ID Application certificate not found in Keychain.\n   Please follow the release-guide.md to create one."
    fi
    print_step "Developer ID Application certificate found"
    
    # Check for exportOptions.plist
    echo "Checking for exportOptions.plist..."
    if [[ ! -f "$EXPORT_OPTIONS_PLIST" ]]; then
        die "exportOptions.plist not found in project root.\n   Please create it with your team ID (see release-guide.md)."
    fi
    print_step "exportOptions.plist found"
    
    # Check for Hardened Runtime
    echo "Checking Hardened Runtime setting..."
    HARDENED_RUNTIME=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "ENABLE_HARDENED_RUNTIME" | tr -d ' ' | cut -d'=' -f2)
    if [[ "$HARDENED_RUNTIME" != "YES" ]]; then
        die "Hardened Runtime is not enabled.\n   Enable it in Xcode: Target → Signing & Capabilities → + Capability → Hardened Runtime"
    fi
    print_step "Hardened Runtime is enabled"
    
    # Get or prompt for keychain profile
    if [[ -z "$KEYCHAIN_PROFILE" ]]; then
        echo ""
        echo -e "${YELLOW}Notarization requires a keychain profile with stored credentials.${NC}"
        echo "If you haven't set one up, run:"
        echo ""
        echo "  xcrun notarytool store-credentials \"zai-notary\" \\"
        echo "    --apple-id \"your-email@example.com\" \\"
        echo "    --team-id \"YOUR_TEAM_ID\" \\"
        echo "    --password \"xxxx-xxxx-xxxx-xxxx\""
        echo ""
        read -p "Enter your keychain profile name [zai-notary]: " KEYCHAIN_PROFILE
        KEYCHAIN_PROFILE=${KEYCHAIN_PROFILE:-zai-notary}
    fi
    
    # Verify keychain profile works
    echo ""
    echo "Verifying keychain profile '$KEYCHAIN_PROFILE'..."
    if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" &>/dev/null; then
        die "Keychain profile '$KEYCHAIN_PROFILE' not found or invalid.\n   Store credentials first using: xcrun notarytool store-credentials"
    fi
    print_step "Keychain profile '$KEYCHAIN_PROFILE' verified"
}

# MARK: - Build Functions

get_version() {
    plutil -extract CFBundleShortVersionString raw "$INFO_PLIST"
}

clean_build() {
    print_header "Cleaning Build Directory"
    
    if [[ -d "$BUILD_DIR" ]]; then
        echo "Removing existing build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_step "Build directory ready: $BUILD_DIR"
}

archive_app() {
    print_header "Archiving Application"
    
    echo "Creating archive..."
    xcodebuild archive \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
        | xcpretty --color 2>/dev/null || xcodebuild archive \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive"
    
    print_step "Archive created: $BUILD_DIR/$PROJECT_NAME.xcarchive"
}

export_app() {
    print_header "Exporting Signed Application"
    
    echo "Exporting with Developer ID signing..."
    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
        -exportPath "$BUILD_DIR/Export" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
        | xcpretty --color 2>/dev/null || xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
        -exportPath "$BUILD_DIR/Export" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
    
    if [[ ! -d "$BUILD_DIR/Export/$PROJECT_NAME.app" ]]; then
        die "Export failed. Check the build log for errors."
    fi
    
    print_step "Signed app exported: $BUILD_DIR/Export/$PROJECT_NAME.app"
}

notarize_app() {
    print_header "Notarizing Application"
    
    local APP_PATH="$BUILD_DIR/Export/$PROJECT_NAME.app"
    local ZIP_PATH="$BUILD_DIR/$PROJECT_NAME-notarize.zip"
    
    # Create zip for notarization
    echo "Creating zip for notarization..."
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    print_step "Created: $ZIP_PATH"
    
    # Submit for notarization
    echo ""
    echo "Submitting to Apple for notarization..."
    echo "This may take several minutes..."
    echo ""
    
    SUBMISSION_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait 2>&1)
    
    echo "$SUBMISSION_OUTPUT"
    
    if echo "$SUBMISSION_OUTPUT" | grep -q "status: Accepted"; then
        print_step "Notarization successful!"
    else
        # Extract submission ID for log retrieval
        SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
        if [[ -n "$SUBMISSION_ID" ]]; then
            print_error "Notarization failed. Fetching log..."
            xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$KEYCHAIN_PROFILE"
        fi
        die "Notarization failed. See above for details."
    fi
    
    # Clean up notarization zip
    rm "$ZIP_PATH"
}

staple_app() {
    print_header "Stapling Notarization Ticket"
    
    local APP_PATH="$BUILD_DIR/Export/$PROJECT_NAME.app"
    
    echo "Stapling ticket to app..."
    xcrun stapler staple "$APP_PATH"
    
    print_step "Ticket stapled successfully"
    
    # Verify stapling
    echo "Verifying..."
    spctl -a -t exec -vvv "$APP_PATH" 2>&1 | head -5
}

package_release() {
    print_header "Packaging Release"
    
    local VERSION=$(get_version)
    local APP_PATH="$BUILD_DIR/Export/$PROJECT_NAME.app"
    local FINAL_ZIP="$BUILD_DIR/$PROJECT_NAME-v${VERSION}.zip"
    
    echo "Creating distributable zip..."
    ditto -c -k --keepParent "$APP_PATH" "$FINAL_ZIP"
    
    local SIZE=$(du -h "$FINAL_ZIP" | cut -f1)
    
    print_step "Release package created: $FINAL_ZIP ($SIZE)"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Build Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Version:     v${VERSION}"
    echo "  Location:    ${FINAL_ZIP}"
    echo "  Size:        ${SIZE}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Test the app:"
    echo "     open \"${BUILD_DIR}/Export/${PROJECT_NAME}.app\""
    echo ""
    echo "  2. Create a GitHub release:"
    echo "     gh release create v${VERSION} ${FINAL_ZIP} --title \"v${VERSION}\" --notes \"Release notes here\""
    echo ""
    echo "  Or manually upload at: https://github.com/tissak/usage/releases/new"
    echo ""
}

# MARK: - Main

main() {
    KEYCHAIN_PROFILE="${1:-}"
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ZaiUsageTracker Release Builder                                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    
    check_prerequisites
    clean_build
    archive_app
    export_app
    notarize_app
    staple_app
    package_release
}

# Run main
main "$@"
