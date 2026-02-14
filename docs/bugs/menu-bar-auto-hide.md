# Menu Bar Auto-Hides When Popover Opens

## Status
**Resolved** - February 2026

## Issue Description

When the user has macOS configured to automatically hide and show the menu bar (System Settings → Desktop & Dock → Automatically hide and show the menu bar), clicking the menu bar icon to open the popover causes the menu bar to immediately hide while the popover remains visible.

**Expected Behavior:** The menu bar should stay visible while the popover is open, similar to native macOS menu bar items (Clock, Battery, Wi-Fi, etc.).

**Actual Behavior:** The menu bar slides up/hides as soon as the popover window opens.

## Root Cause

When `MenuBarExtra` with `.menuBarExtraStyle(.window)` opens, SwiftUI creates an `NSWindow` that becomes key, which activates the application. macOS's auto-hide mechanism interprets this as the user "leaving the menu bar area" and triggers the hide animation.

Additionally, the popover window is created as a child window of the status bar window (`NSStatusBarWindow`). When the menu bar moves (hides), child windows move with it, causing the popover to shift position.

## Strategies Researched

### 1. Configure Window to Not Become Key

**Approach:** Access the underlying `NSWindow` and set properties to prevent it from activating the app.

**Code Pattern:**
```swift
window.canBecomeKey = false
// or
window.styleMask.insert(.nonactivatingPanel)
```

**Pros:** Direct solution to the root cause
**Cons:** Requires accessing internal SwiftUI window

### 2. Use NSPanel with Nonactivating Style

**Approach:** Create a custom `NSPanel` with `.nonactivatingPanel` style mask and `becomesKeyOnlyIfNeeded = true`.

**Reference:** [Apple Developer Documentation - NSPanel](https://developer.apple.com/documentation/appkit/nspanel)

**Key insight from [Phil Zakharchenko's blog](https://philz.blog/nspanel-nonactivating-style-mask-flag/):**
> The nonactivating panel behavior allows the window to receive key events without activating the owning application. Among other things, this will cause it to not acquire the menu bar.

**Pros:** Native macOS pattern for utility panels
**Cons:** Requires replacing SwiftUI's `MenuBarExtra` with custom AppKit implementation

### 3. Detach Popover from Parent Window

**Approach:** Remove the popover window as a child of the status bar window so it doesn't move when the menu bar hides.

**Reference:** [Stack Overflow - Prevent menu bar from moving down](https://stackoverflow.com/questions/34913405)

```swift
let popoverWindow = popup.contentViewController.view.window
popoverWindow?.parent?.removeChildWindow(popoverWindow!)
```

**Pros:** Prevents popover from moving with menu bar
**Cons:** Hacky, prone to breaking with OS updates, doesn't prevent menu bar from hiding

### 4. Replace MenuBarExtra with FluidMenuBarExtra

**Approach:** Use a third-party library that creates its own `NSPanel` with proper configuration.

**Library:** [FluidMenuBarExtra](https://github.com/lfroms/fluid-menu-bar-extra) (now archived)

**Pros:**
- Solves multiple issues (animation, highlighting, menu bar hiding)
- Drop-in replacement for `MenuBarExtra`

**Cons:**
- Requires `AppDelegate` setup
- Repository is archived
- Larger refactor

### 5. Use MenuBarExtraAccess Library

**Approach:** Use a library that provides introspection of the underlying `NSWindow` from SwiftUI's `MenuBarExtra`.

**Library:** [MenuBarExtraAccess](https://github.com/orchetect/MenuBarExtraAccess) (actively maintained)

**Features:**
- `.introspectMenuBarExtraWindow { window in }` modifier
- No private APIs (Mac App Store safe)
- Works with existing `MenuBarExtra` code

**Pros:**
- Minimal code changes
- Actively maintained
- Clean API

**Cons:**
- Adds external dependency

## Solution Implemented

**Chosen Approach:** Option 5 - MenuBarExtraAccess library

### Implementation

1. Added Swift Package dependency:
   - Package URL: `https://github.com/orchetect/MenuBarExtraAccess`
   - Version: 1.2.2

2. Updated `ZaiUsageTrackerApp.swift`:

```swift
import MenuBarExtraAccess

var body: some Scene {
    MenuBarExtra(viewModel.menuBarTitle, systemImage: menuBarIcon) {
        PopoverView(viewModel: viewModel)
            .introspectMenuBarExtraWindow { window in
                // Prevent menu bar from auto-hiding when popover is open
                window.styleMask.insert(.nonactivatingPanel)
                
                // Allow window to appear on all spaces and over full-screen apps
                window.collectionBehavior.insert(.canJoinAllSpaces)
                window.collectionBehavior.insert(.fullScreenAuxiliary)
                
                // Ensure window floats above standard windows
                window.level = .popUpMenu
            }
    }
    .menuBarExtraStyle(.window)
    // ...
}
```

### How It Works

The solution combines several window configuration flags to ensure the popover behaves as a proper system overlay:

1. **`.nonactivatingPanel`**: Tells macOS that this window should receive key events without activating the application. This prevents the menu bar from auto-hiding because the app doesn't become "active" in a way that dismisses the menu bar.
2. **`.canJoinAllSpaces`**: Ensures the popover is visible on all Mission Control spaces.
3. **`.fullScreenAuxiliary`**: Allows the popover to appear over full-screen apps.
4. **`.popUpMenu` window level**: Ensures the window floats above standard application windows.

This combination ensures the menu bar remains visible and the popover is correctly layered above other content.

## Related Resources

- [Apple Developer Forums - Auto Hide Menu Bar](https://developer.apple.com/forums/thread/124849)
- [Stack Overflow - NSPopover and menu bar hiding](https://stackoverflow.com/questions/34913405)
- [The Curious Case of NSPanel's Nonactivating Style Mask Flag](https://philz.blog/nspanel-nonactivating-style-mask-flag/)
- [MenuBarExtraAccess GitHub Repository](https://github.com/orchetect/MenuBarExtraAccess)
