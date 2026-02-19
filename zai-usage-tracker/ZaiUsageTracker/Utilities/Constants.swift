import Foundation

struct Constants {
    // App Info
    static let appName = "Z.ai Usage Tracker"
    static let appBundleId = "com.zaiusagetracker"
    
    // Refresh Intervals (in seconds)
    struct RefreshInterval {
        static let fiveMinutes: TimeInterval = 300
        static let tenMinutes: TimeInterval = 600
        static let fifteenMinutes: TimeInterval = 900
        static let thirtyMinutes: TimeInterval = 1800
        
        static let `default`: TimeInterval = tenMinutes
        static let all: [TimeInterval] = [fiveMinutes, tenMinutes, fifteenMinutes, thirtyMinutes]
        
        static func label(_ interval: TimeInterval) -> String {
            switch interval {
            case fiveMinutes: return "5 minutes"
            case tenMinutes: return "10 minutes"
            case fifteenMinutes: return "15 minutes"
            case thirtyMinutes: return "30 minutes"
            default: return "\(Int(interval / 60)) minutes"
            }
        }
    }
    
    // Notification Thresholds
    struct NotificationThreshold {
        static let fiftyPercent = 50.0
        static let seventyPercent = 70.0
        static let eightyPercent = 80.0
        static let ninetyPercent = 90.0
        
        static let `default`: Double = eightyPercent
        static let all: [Double] = [fiftyPercent, seventyPercent, eightyPercent, ninetyPercent]
        
        static func label(_ threshold: Double) -> String {
            return "\(Int(threshold))%"
        }
    }
    
    // Token Limits
    static let defaultTokenLimit = 40_000_000

    struct WeeklyTokenLimit {
        static let `default` = 40_000_000
        static let all = [5_000_000, 10_000_000, 20_000_000, 40_000_000, 80_000_000, 100_000_000, 200_000_000]

        static func label(_ value: Int) -> String {
            if value >= 1_000_000 {
                return "\(value / 1_000_000)M tokens"
            } else if value >= 1_000 {
                return "\(value / 1_000)K tokens"
            } else {
                return "\(value) tokens"
            }
        }
    }

    // UserDefaults Keys
    struct UserDefaultsKeys {
        static let platform = "selectedPlatform"
        static let refreshInterval = "refreshInterval"
        static let notificationThreshold = "notificationThreshold"
        static let notificationsEnabled = "notificationsEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let storageBackend = "storageBackend"
        static let weeklyTokenLimit = "weeklyTokenLimit"
    }

    // File Paths
    struct FilePaths {
        static let configDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("zai-usage-tracker")

        static let configFile = configDirectory.appendingPathComponent("config.json")
    }
}
