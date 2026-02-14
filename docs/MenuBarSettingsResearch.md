# Opening Preferences/Settings from MenuBarExtra in macOS SwiftUI Apps

## Executive Summary

**The short answer**: `SettingsLink` **does NOT work reliably** inside `MenuBarExtra` content. The console warning "Please use SettingsLink for opening the Settings scene" indicates that private API selectors have been deprecated in favor of SwiftUI's scene-based approach, but this approach has fundamental limitations for menu bar apps.

**Recommended approach for macOS 14+ (Sonoma+)**: Use the `openSettings` environment action with a hidden window workaround that provides proper SwiftUI context and window activation.

---

## Question 1: Does SettingsLink work inside MenuBarExtra content?

**Answer: NO - it does not work reliably.**

### Why It Fails

Multiple developers (including Peter Steinberger and Zachary Armstead) have discovered that `SettingsLink` in `MenuBarExtra` simply doesn't function properly:

```swift
// This does NOT reliably work:
MenuBarExtra("My App", systemImage: "star.fill") {
    SettingsLink {
        Text("Open settings")
    }
}
```

**Root causes:**
- Menu bar apps use `NSApplication.ActivationPolicy.accessory` (no dock icon by default)
- They don't have proper window management context that SettingsLink requires
- `NSApplication` treats menu bar apps as background utilities, not foreground apps
- Windows may appear behind other apps without proper activation
- The SwiftUI graph isn't fully initialized in the menu bar context

---

## Question 2: What does the console warning imply?

**Answer: It indicates deprecated private APIs.**

### The Warning

```
Please use SettingsLink for opening the Settings scene.
```

### Historical Context

**Old approach (pre-macOS 13):**
```swift
// Worked but used private selectors
NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
```

**macOS 13+ (Ventura):**
```swift
// Slight rename
NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
```

**macOS 14+ (Sonoma):**
- These selectors were deprecated
- Apple forced use of SwiftUI's `SettingsLink`
- The warning appeared because developers were still using the old approach

### What the Warning Means

1. **Not a bug** - Apple is enforcing the correct, SwiftUI-based approach
2. **Private API deprecation** - The selectors were never public APIs, just widely used
3. **Future-proofing** - Forces you to use the modern, supported approach
4. **Challenge**: Apple didn't account for menu bar apps' unique constraints

---

## Question 3: Recommended Alternatives

### Option 1: `openSettings` Environment Action (RECOMMENDED for macOS 14+)

**Approach**: Use a hidden window to provide SwiftUI context, then use the `openSettings` environment action.

```swift
// MARK: - Hidden Window for Settings Context
struct HiddenSettingsWindowView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)  // Tiny, effectively hidden
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsRequest)) { _ in
                Task { @MainActor in
                    // Show dock icon for proper window activation
                    NSApp.setActivationPolicy(.regular)
                    try? await Task.sleep(for: .milliseconds(100))

                    // Activate the app
                    NSApp.activate(ignoringOtherApps: true)

                    // Open settings
                    openSettings()

                    // Bring settings window to front
                    try? await Task.sleep(for: .milliseconds(200))
                    if let settingsWindow = findSettingsWindow() {
                        settingsWindow.makeKeyAndOrderFront(nil)
                        settingsWindow.orderFrontRegardless()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .settingsWindowClosed)) { _ in
                // Restore menu bar app state
                NSApp.setActivationPolicy(.accessory)
            }
    }
}

// MARK: - Find Settings Window
extension NSApplication {
    private static let settingsWindowIdentifier = "com.apple.SwiftUI.Settings"

    static func findSettingsWindow() -> NSWindow? {
        NSApp.windows.first { window in
            // Check by identifier
            if window.identifier?.rawValue == settingsWindowIdentifier {
                return true
            }
            // Check by title
            if window.isVisible && window.styleMask.contains(.titled) &&
               (window.title.localizedCaseInsensitiveContains("settings") ||
                window.title.localizedCaseInsensitiveContains("preferences")) {
                return true
            }
            return false
        }
    }
}

// MARK: - App Structure
@main
struct MenuBarApp: App {
    var body: some Scene {
        // Menu bar
        MenuBarExtra("My App", systemImage: "star.fill") {
            Button("Settings...") {
                NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        // Standard Settings scene
        Settings {
            SettingsView()
                .onDisappear {
                    NotificationCenter.default.post(name: .settingsWindowClosed, object: nil)
                }
        }

        // Hidden window for context (MUST come before Settings!)
        Window("Hidden", id: "HiddenWindow") {
            HiddenSettingsWindowView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
    }
}

extension Notification.Name {
    static let openSettingsRequest = Notification.Name("openSettingsRequest")
    static let settingsWindowClosed = Notification.Name("settingsWindowClosed")
}
```

**⚠️ Critical Caveat**: Scene order matters! The hidden `Window` **MUST be declared before** the `Settings` scene for this to work.

---

### Option 2: Custom WindowGroup with `openWindow` (ALTERNATIVE)

Create a custom settings window instead of using the native Settings scene.

```swift
struct MyView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Settings") {
            openWindow(id: "AppSettings")
        }
    }
}

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Custom settings window
        Window("Settings", id: "AppSettings") {
            SettingsView()
        }
        .windowResizability(.contentSize)

        // Original settings scene if needed
        Settings {
            SettingsView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the custom settings window on launch
        getWindowById(id: "AppSettings")?.close()
    }

    func getWindowById(id: String) -> NSWindow? {
        NSApp.windows.first { window in
            window.identifier?.rawValue == id
        }
    }
}
```

**Pros**:
- More control over appearance and behavior
- No activation policy juggling
- Works reliably in MenuBarExtra

**Cons**:
- Doesn't use native system settings appearance
- Requires custom window management
- More code to maintain

---

### Option 3: NSApp.sendAction with Fallbacks (DEPRECATED but still works in macOS < 14)

```swift
func openSettings() {
    if #available(macOS 13.0, *) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
```

**⚠️ Deprecated**: This will trigger warnings on macOS 14+ and may be removed in future versions. Use only for backward compatibility.

---

### Option 4: Custom NSWindowController (ADVANCED)

Create a custom NSWindowController subclass:

```swift
class SettingsWindowController: NSWindowController {
    init() {
        let window = NSWindow(...)
        super.init(window: window)

        window.center()
        window.setFrameAutosaveName("Settings")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Usage from MenuBarExtra
@IBAction func openSettings(_ sender: Any?) {
    let controller = SettingsWindowController()
    controller.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
}
```

**Pros**:
- Full control over window
- No SwiftUI ecosystem dependency
- Classic macOS approach

**Cons**:
- More boilerplate
- Doesn't use Settings scene
- Less maintainable with SwiftUI

---

## Question 4: What is the recommended approach and caveats for macOS 14/Xcode 15?

### RECOMMENDED APPROACH

**For macOS 14+ (Sonoma and later), use Option 1 (hidden window with openSettings)**:

```swift
// 1. Create hidden window view with openSettings context
// 2. Add Settings scene
// 3. Add MenuBarExtra with button that posts notification
// 4. IMPORTANT: Hidden Window scene must come BEFORE Settings scene
```

### Critical Caveats

#### 1. **Scene Order is Critical**
The hidden `Window` scene **must be declared before** the `Settings` scene in `@main` body. If reversed, `openSettings()` will fail silently.

```swift
var body: some Scene {
    // ✅ Correct order
    Window("Hidden", id: "HiddenWindow") { ... }
    Settings { ... }

    // ❌ Wrong order (won't work)
    Settings { ... }
    Window("Hidden", id: "HiddenWindow") { ... }
}
```

#### 2. **Activation Policy Juggling**
You must temporarily switch between:
- `.regular` (with dock icon) → to properly activate windows
- `.accessory` (without dock icon) → for authentic menu bar app behavior

#### 3. **Timing Issues**
Delays are required:
- 100ms delay after showing dock icon
- 200ms delay before bringing window to front

These ensure the system properly activates and opens the window.

#### 4. **Window Detection**
Finding the settings window isn't straightforward:
- Check by identifier: `"com.apple.SwiftUI.Settings"`
- Check by title: contains "settings" or "preferences"
- May need to check content view controller type

#### 5. **macOS 15+ vs 26 (Tahoe)**
- Works on macOS 15 (Sequoia)
- **Does NOT work on macOS 26 (Tahoe)** according to some reports
- The logic requires an existing SwiftUI render tree

#### 6. **Code Complexity**
What should be a simple operation requires:
- Hidden window view
- NotificationCenter communication
- Activation policy management
- Timing delays
- Window detection logic
- App state restoration

#### 7. **App Store Compliance**
While the `NSApp.sendAction` approach **has passed App Review**, the workaround approach uses private API patterns (activation policy manipulation) that may raise concerns in future review cycles.

### Alternative: Consider Not Using MenuBarExtra(.window)

For simple settings access, use the app menu instead:

```swift
var body: some Scene {
    // Remove MenuBarExtra entirely
    Settings {
        SettingsView()
    }
}
```

Users can access Settings via the app menu:
- macOS 13+: "Settings" → Settings
- macOS 12 and earlier: "Preferences" → Settings

This is the simplest, most reliable approach.

---

## Comparison Table

| Approach | macOS 14+ Support | MenuBarExtra Support | Code Complexity | App Store Safe? | Recommended |
|----------|-------------------|---------------------|-----------------|-----------------|-------------|
| `SettingsLink` in MenuBarExtra | No | **No** (unreliable) | Low | N/A | ❌ Do not use |
| `NSApp.sendAction` (deprecated) | No (deprecated) | Yes | Very low | ✅ Yes (so far) | ⚠️ Use with caution |
| `openSettings` + hidden window | Yes | Yes | High | ⚠️ Uncertain | ✅ Recommended for 14+ |
| `openWindow` with custom WindowGroup | Yes | Yes | Medium | ✅ Yes | ✅ Good alternative |
| Custom NSWindowController | Yes | Yes | High | ✅ Yes | ✅ For advanced needs |

---

## Migration Guide

### From Old Way to New Way

**Old code (macOS 12-13):**
```swift
Button("Settings") {
    if #available(macOS 13, *) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
```

**New code (macOS 14+):**
```swift
// 1. Create HiddenSettingsWindowView
// 2. Add notification in MenuBarExtra
NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
```

### If You're Starting Fresh

**For Menu Bar Apps:**
1. Use app menu for Settings access (simplest)
2. Or use `openWindow` with custom WindowGroup (more control)

**For Regular Apps with MenuBarExtra:**
1. Use `openWindow` with custom WindowGroup for settings
2. Keep `Settings` scene for menu integration

---

## Best Practices

1. **Always handle deprecation**: Check `#available(macOS 14, *)` before using old approaches
2. **Test on multiple macOS versions**: Behaviors differ between 14, 15, and 26
3. **Add user feedback**: Show loading indicator while activating app
4. **Handle window events**: Restore proper activation policy when settings close
5. **Consider accessibility**: Ensure keyboard shortcuts work in MenuBarExtra
6. **Test on real hardware**: Different macOS versions behave differently

---

## Resources

- [Peter Steinberger's detailed journey](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items/)
- [Zachary Armstead's comprehensive guide](https://zacharmstead.com/posts/2025/showing-settings-from-macos-menu-bar-items/)
- [Stack Overflow discussion](https://stackoverflow.com/questions/65355696/how-to-programatically-open-settings-preferences-window-in-a-macos-swiftui-app)
- [Sindresorhus/Settings package](https://github.com/sindresorhus/Settings) - Alternative settings management

---

## Conclusion

The `SettingsLink` in `MenuBarExtra` is fundamentally broken for menu bar apps. The recommended solution is to use `openSettings` environment action with a hidden window workaround, but be aware of the significant caveats:

1. Scene order is critical
2. Activation policy manipulation is required
3. Timing delays are necessary
4. The approach is complex and fragile
5. May not work on future macOS versions

For most use cases, using the native app menu for Settings access is the simplest, most reliable solution. Only use the workaround if you specifically need programmatic access from MenuBarExtra content.
