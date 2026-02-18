# Automated Screenshot Generation

## Goal
Automate the creation of app screenshots for the README using UI Tests.

## Implementation Status
- [x] Created `ZaiUsageTrackerUITests` target in Xcode.
- [x] Implemented `ZaiUsageTrackerUITests.swift` to launch app and capture screenshot.
- [x] Created `scripts/generate_screenshots.sh` to run tests.
- [x] Fix `xcresulttool` extraction script (currently failing with JSON/syntax errors).
- [x] Integrate into `README.md`.

## Technical Details
- Uses `XCUITest` to launch the app and interact with the menu bar.
- Uses `xcresulttool` to extract the attachment from the test result bundle.

## Notes
The extraction script was fixed by properly handling the JSON array format returned by `xcresulttool`. The script now correctly parses the nested structure and extracts the screenshot attachment.

## Refinement

### Full-Screen Screenshot Fix

Initial screenshots captured the entire screen rather than just the popover. This was due to a misunderstanding of how `MenuBarExtra` windows appear in the XCUITest accessibility hierarchy.

**Key Discovery:** `MenuBarExtra` windows are represented as `dialogs` in the XCUITest hierarchy, not `windows`. Using `app.windows` would match the entire screen or fail to find the popover.

**Solution:** The test now targets the popover using `app.dialogs.containing(...)`:

```swift
let popover = app.dialogs.containing(.staticText, identifier: "Z.ai Usage").firstMatch
```

This ensures the screenshot captures only the popover content, not the full screen.
