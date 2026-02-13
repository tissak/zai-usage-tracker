import Foundation

// MARK: - API Response Model

struct ToolUsageResponse: Codable {
    let data: ToolUsageData?
}

struct ToolUsageData: Codable {
    let totalUsage: ToolTotalUsage?
}

struct ToolTotalUsage: Codable {
    let totalNetworkSearchCount: Int?
    let totalWebReadMcpCount: Int?
    let totalZreadMcpCount: Int?
}

// MARK: - Domain Model

struct ToolUsageInfo {
    let networkSearches: Int
    let webReads: Int
    let zreadCalls: Int
    
    var hasData: Bool {
        networkSearches > 0 || webReads > 0 || zreadCalls > 0
    }
    
    init(from response: ToolUsageResponse) {
        self.networkSearches = response.data?.totalUsage?.totalNetworkSearchCount ?? 0
        self.webReads = response.data?.totalUsage?.totalWebReadMcpCount ?? 0
        self.zreadCalls = response.data?.totalUsage?.totalZreadMcpCount ?? 0
    }
    
    func formatted(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
