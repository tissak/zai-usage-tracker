import Foundation

// MARK: - API Response Model

struct ModelUsageResponse: Codable {
    let totalUsage: ModelTotalUsage?
}

struct ModelTotalUsage: Codable {
    let totalTokensUsage: Int?
    let totalModelCallCount: Int?
}

// MARK: - Domain Model

struct ModelUsageInfo {
    let totalTokens: Int
    let totalCalls: Int
    
    var formattedTokens: String {
        formatNumber(totalTokens)
    }
    
    var formattedCalls: String {
        formatNumber(totalCalls)
    }
    
    init(from response: ModelUsageResponse) {
        self.totalTokens = response.totalUsage?.totalTokensUsage ?? 0
        self.totalCalls = response.totalUsage?.totalModelCallCount ?? 0
    }
    
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
