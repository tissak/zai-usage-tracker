import Foundation

@MainActor
final class UsageService: ObservableObject {
    @Published var state: LoadingState = .idle
    @Published var lastError: String?
    
    private let apiClient = ZaiAPIClient.shared
    
    var platform: Platform = .global
    
    func refresh(apiKey: String? = nil) async {
        // Use provided apiKey directly - never fallback to keychain in UsageService
        // The caller (ViewModel) should handle keychain access and caching
        guard let key = apiKey, !key.isEmpty else {
            state = .error("API key not configured. Please add your API key in Settings.")
            return
        }
        
        state = .loading
        lastError = nil
        
        do {
            let (quotaResponse, modelResponse, toolResponse, weeklyModelResponse, weeklyToolResponse) = try await apiClient.fetchAll(
                platform: platform,
                apiKey: key
            )

            // Log all quota types so we can discover any weekly quota item the API returns
            for item in quotaResponse.data.limits {
                let resetDate = item.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
                print("[QuotaDebug] type=\(item.type) pct=\(item.percentage) reset=\(resetDate.map { "\($0)" } ?? "nil")")
            }

            let quotaInfos = quotaResponse.data.limits.map { QuotaInfo(from: $0) }

            // Two TOKENS_LIMIT items exist: the 5h quota (no reset time) and the weekly
            // quota (furthest reset time). Pick the one with the largest nextResetTime.
            let weeklyTokenItem = quotaResponse.data.limits
                .filter { $0.type == "TOKENS_LIMIT" }
                .max(by: { ($0.nextResetTime ?? 0) < ($1.nextResetTime ?? 0) })
            let weeklyResetTime: Date? = weeklyTokenItem.flatMap { item in
                item.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            }

            let modelUsage = ModelUsageInfo(from: modelResponse)
            let toolUsage = ToolUsageInfo(from: toolResponse)
            let weeklyModelUsage = ModelUsageInfo(from: weeklyModelResponse)
            let weeklyToolUsage = ToolUsageInfo(from: weeklyToolResponse)

            let (startTime, endTime) = getTimeWindowDates()

            let usageData = UsageData(
                quotaLimits: quotaInfos,
                modelUsage: modelUsage,
                toolUsage: toolUsage,
                weeklyModelUsage: weeklyModelUsage,
                weeklyToolUsage: weeklyToolUsage,
                weeklyResetTime: weeklyResetTime,
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
        
        // End: end of current hour (e.g., 15:00)
        let end = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
        
        // Start: 24 hours before end
        let start = calendar.date(byAdding: .day, value: -1, to: end)!
        return (start, end)
    }
}
