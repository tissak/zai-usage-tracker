import Foundation

@MainActor
final class UsageService: ObservableObject {
    @Published var state: LoadingState = .idle
    @Published var lastError: String?
    
    private let apiClient = ZaiAPIClient.shared
    private let keychain = KeychainService.shared
    
    var platform: Platform = .global
    
    func refresh(apiKey: String? = nil) async {
        let key: String?
        if let apiKey = apiKey, !apiKey.isEmpty {
            key = apiKey
        } else {
            key = try? keychain.getAPIKey()
        }
        
        guard let key = key, !key.isEmpty else {
            state = .error("API key not configured. Please add your API key in Settings.")
            return
        }
        
        state = .loading
        lastError = nil
        
        do {
            let (quotaResponse, modelResponse, toolResponse) = try await apiClient.fetchAll(
                platform: platform,
                apiKey: key
            )
            
            let quotaInfos = quotaResponse.data.limits.map { QuotaInfo(from: $0) }
            let modelUsage = ModelUsageInfo(from: modelResponse)
            let toolUsage = ToolUsageInfo(from: toolResponse)
            
            let (_, endTime) = getTimeWindowDates()
            let startTime = calendar.date(byAdding: .day, value: -1, to: endTime)!
            
            let usageData = UsageData(
                quotaLimits: quotaInfos,
                modelUsage: modelUsage,
                toolUsage: toolUsage,
                fetchedAt: Date(),
                periodStart: startTime,
                periodEnd: endTime
            )
            
            state = .loaded(usageData)
        } catch {
            let errorMessage = error.localizedDescription
            lastError = errorMessage
            state = .error(errorMessage)
        }
    }
    
    func clearError() {
        lastError = nil
    }
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private func getTimeWindowDates() -> (start: Date, end: Date) {
        let now = Date()
        let currentHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!
        let end = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
        let start = calendar.date(byAdding: .day, value: -1, to: currentHour)!
        return (start, end)
    }
}
