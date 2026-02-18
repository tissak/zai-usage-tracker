#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_NAME="zai-usage-tracker/ZaiUsageTracker.xcodeproj"
SCHEME_NAME="ZaiUsageTracker"
TEST_RESULT_PATH="./TestResults.xcresult"
OUTPUT_DIR="./docs/images"
SCREENSHOT_NAME="PopoverScreenshot"

# Clean previous results
rm -rf "$TEST_RESULT_PATH"
mkdir -p "$OUTPUT_DIR"

echo "🚀 Running UI Tests to capture screenshots..."

# Run tests and capture results
xcodebuild test \
    -project "$PROJECT_NAME" \
    -scheme "$SCHEME_NAME" \
    -destination 'platform=macOS' \
    -resultBundlePath "$TEST_RESULT_PATH" \
    -quiet

echo "✅ Tests completed. Extracting screenshot..."

# Run the python extraction script
python3 scripts/extract_screenshot.py \
    --path "$TEST_RESULT_PATH" \
    --output "$OUTPUT_DIR" \
    --name "$SCREENSHOT_NAME"

# Clean up
rm -rf "$TEST_RESULT_PATH"
