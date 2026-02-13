import Foundation
import AppKit

// MARK: - API Response Models

struct QuotaLimitResponse: Codable {
    let limits: [QuotaLimitItem]
}

struct QuotaLimitItem: Codable {
    let type: String
    let percentage: Double
    let currentValue: Int?
    let total: Int?
    let usageDetails: [UsageDetail]?
    let nextResetTime: Int64?
    
    enum CodingKeys: String, CodingKey {
        case type, percentage, total, usageDetails
        case currentValue = "currentValue"
        case nextResetTime
    }
}

struct UsageDetail: Codable {
    let modelCode: String
    let usage: Int
}

// MARK: - Domain Models

enum QuotaType: String {
    case tokens = "TOKENS_LIMIT"
    case time = "TIME_LIMIT"
    
    var displayName: String {
        switch self {
        case .tokens: return "Token Usage"
        case .time: return "MCP Usage"
        }
    }
    
    var cycleDescription: String {
        switch self {
        case .tokens: return "5 Hour Cycle"
        case .time: return "Monthly"
        }
    }
}

struct QuotaInfo: Identifiable {
    let id = UUID()
    let type: QuotaType
    let percentage: Double
    let currentValue: Int?
    let total: Int?
    let usageDetails: [UsageDetail]?
    let nextResetTime: Date?
    
    var status: UsageStatus {
        switch percentage {
        case 0..<50: return .normal
        case 50..<70: return .warning
        case 70..<90: return .high
        default: return .critical
        }
    }
    
    init(from item: QuotaLimitItem) {
        self.type = item.type == "TOKENS_LIMIT" ? .tokens : .time
        self.percentage = item.percentage
        self.currentValue = item.currentValue
        self.total = item.total
        self.usageDetails = item.usageDetails
        self.nextResetTime = item.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
    }
}

enum UsageStatus {
    case normal, warning, high, critical
    
    var color: NSColor {
        switch self {
        case .normal: return .systemGreen
        case .warning: return .systemYellow
        case .high: return .systemOrange
        case .critical: return .systemRed
        }
    }
}
