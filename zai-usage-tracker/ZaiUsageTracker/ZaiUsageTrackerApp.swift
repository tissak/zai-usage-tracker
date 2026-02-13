import SwiftUI
import UserNotifications

@main
struct ZaiUsageTrackerApp: App {
    @StateObject private var viewModel = UsageViewModel()
    
    var body: some Scene {
        MenuBarExtra(viewModel.menuBarTitle, systemImage: menuBarIcon) {
            PopoverView(viewModel: viewModel)
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
