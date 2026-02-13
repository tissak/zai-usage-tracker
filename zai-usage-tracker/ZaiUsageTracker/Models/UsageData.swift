import Foundation

// MARK: - Aggregated Usage Data

struct UsageData {
    let quotaLimits: [QuotaInfo]
    let modelUsage: ModelUsageInfo
    let toolUsage: ToolUsageInfo
    let fetchedAt: Date
    let periodStart: Date
    let periodEnd: Date
    
    var tokenQuota: QuotaInfo? {
        quotaLimits.first { $0.type == .tokens }
    }
    
    var mcpQuota: QuotaInfo? {
        quotaLimits.first { $0.type == .time }
    }
    
    var tokenPercentage: Double {
        tokenQuota?.percentage ?? 0
    }
    
    var tokenStatus: UsageStatus {
        tokenQuota?.status ?? .normal
    }
    
    var timeUntilReset: String? {
        guard let resetTime = tokenQuota?.nextResetTime else { return nil }
        let interval = resetTime.timeIntervalSince(Date())
        guard interval > 0 else { return nil }
        return formatTimeRemaining(interval)
    }
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m until reset"
        } else {
            return "\(minutes)m until reset"
        }
    }
    
    static var empty: UsageData {
        UsageData(
            quotaLimits: [],
            modelUsage: ModelUsageInfo(from: ModelUsageResponse(data: nil)),
            toolUsage: ToolUsageInfo(from: ToolUsageResponse(data: nil)),
            fetchedAt: Date(),
            periodStart: Date(),
            periodEnd: Date()
        )
    }
}

// MARK: - Loading State

enum LoadingState {
    case idle
    case loading
    case loaded(UsageData)
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var data: UsageData? {
        if case .loaded(let data) = self { return data }
        return nil
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}
