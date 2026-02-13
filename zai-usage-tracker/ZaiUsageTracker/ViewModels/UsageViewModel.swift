import Foundation
import Combine
import AppKit
import UserNotifications

@MainActor
final class UsageViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var state: LoadingState = .idle
    @Published var platform: Platform = .global
    @Published var refreshInterval: TimeInterval = Constants.RefreshInterval.default
    @Published var notificationThreshold: Double = Constants.NotificationThreshold.default
    @Published var notificationsEnabled: Bool = true
    @Published var launchAtLogin: Bool = false
    @Published var showSettings: Bool = false
    @Published var isManuallyRefreshing: Bool = false
    
    // MARK: - Private Properties
    
    private let usageService = UsageService()
    private let keychain = KeychainService.shared
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var _cachedAPIKey: String?
    private var _hasAPIKey: Bool { _cachedAPIKey != nil }
    
    // MARK: - Computed Properties
    
    var usageData: UsageData? {
        state.data
    }
    
    var isLoading: Bool {
        state.isLoading || isManuallyRefreshing
    }
    
    var errorMessage: String? {
        state.errorMessage
    }
    
    var hasAPIKey: Bool {
        _hasAPIKey
    }
    
    var cachedAPIKey: String? {
        _cachedAPIKey
    }
    
    var tokenPercentage: Double {
        usageData?.tokenPercentage ?? 0
    }
    
    var tokenStatus: UsageStatus {
        usageData?.tokenStatus ?? .normal
    }
    
    var statusColor: NSColor {
        tokenStatus.color
    }
    
    var menuBarTitle: String {
        guard hasAPIKey else {
            return "Z.ai: --"
        }
        
        if isLoading && usageData == nil {
            return "Z.ai: ..."
        }
        
        let pct = Int(tokenPercentage.rounded())
        return "Z.ai: \(pct)%"
    }
    
    var lastUpdatedText: String {
        guard let data = usageData else { return "Never" }
        return DateHelper.formatRelativeTime(data.fetchedAt)
    }
    
    // MARK: - Initialization
    
    init() {
        _cachedAPIKey = try? keychain.getAPIKey()
        loadSettings()
        setupBindings()
        
        // Initial refresh if API key exists
        if _hasAPIKey {
            Task {
                await refresh()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func refresh() async {
        isManuallyRefreshing = true
        await usageService.refresh(apiKey: _cachedAPIKey)
        state = usageService.state
        isManuallyRefreshing = false
        
        // Check notification threshold
        checkAndSendNotification()
    }
    
    func saveAPIKey(_ key: String) async throws {
        try keychain.saveAPIKey(key)
        _cachedAPIKey = key
        await refresh()
        startAutoRefresh()
    }
    
    func deleteAPIKey() {
        try? keychain.deleteAPIKey()
        _cachedAPIKey = nil
        state = .idle
        stopAutoRefresh()
    }
    
    func updatePlatform(_ newPlatform: Platform) {
        platform = newPlatform
        usageService.platform = newPlatform
        UserDefaults.standard.set(newPlatform.rawValue, forKey: Constants.UserDefaultsKeys.platform)
        
        Task {
            await refresh()
        }
    }
    
    func updateRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
        UserDefaults.standard.set(interval, forKey: Constants.UserDefaultsKeys.refreshInterval)
        restartAutoRefresh()
    }
    
    func updateNotificationThreshold(_ threshold: Double) {
        notificationThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: Constants.UserDefaultsKeys.notificationThreshold)
    }
    
    func toggleNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Constants.UserDefaultsKeys.notificationsEnabled)
    }
    
    func toggleLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: Constants.UserDefaultsKeys.launchAtLogin)
        // TODO: Implement launch at login using ServiceManagement framework
    }
    
    func openSettings() {
        showSettings = true
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let platformRaw = defaults.string(forKey: Constants.UserDefaultsKeys.platform),
           let savedPlatform = Platform(rawValue: platformRaw) {
            platform = savedPlatform
        }
        
        refreshInterval = defaults.object(forKey: Constants.UserDefaultsKeys.refreshInterval) as? TimeInterval
            ?? Constants.RefreshInterval.default
        
        notificationThreshold = defaults.object(forKey: Constants.UserDefaultsKeys.notificationThreshold) as? Double
            ?? Constants.NotificationThreshold.default
        
        notificationsEnabled = defaults.object(forKey: Constants.UserDefaultsKeys.notificationsEnabled) as? Bool
            ?? true
        
        launchAtLogin = defaults.object(forKey: Constants.UserDefaultsKeys.launchAtLogin) as? Bool
            ?? false
    }
    
    private func setupBindings() {
        usageService.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
        
        usageService.platform = platform
    }
    
    private func startAutoRefresh() {
        guard hasAPIKey else { return }
        
        stopAutoRefresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        
        // Also fire immediately
        RunLoop.current.add(refreshTimer!, forMode: .common)
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func restartAutoRefresh() {
        if hasAPIKey {
            startAutoRefresh()
        }
    }
    
    private func checkAndSendNotification() {
        guard notificationsEnabled, let data = usageData else { return }
        
        if data.tokenPercentage >= notificationThreshold {
            sendUsageNotification(percentage: data.tokenPercentage)
        }
    }
    
    private func sendUsageNotification(percentage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Z.ai Usage Alert"
        content.body = "Token usage has reached \(Int(percentage))%"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "usage-alert",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
