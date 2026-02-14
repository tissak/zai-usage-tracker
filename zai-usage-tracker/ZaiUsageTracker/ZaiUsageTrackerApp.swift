import SwiftUI
import UserNotifications
import MenuBarExtraAccess

@main
struct ZaiUsageTrackerApp: App {
    @StateObject private var viewModel = UsageViewModel()
    
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
        
        // Settings window (for API key setup)
        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
    
    private var menuBarIcon: String {
        guard viewModel.hasAPIKey else {
            return "key.fill"
        }
        
        switch viewModel.tokenStatus {
        case .normal:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
    
    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
