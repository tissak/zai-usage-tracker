import Foundation

enum Platform: String, CaseIterable {
    case global = "global"
    case china = "china"
    
    var displayName: String {
        switch self {
        case .global: return "Z.ai Global"
        case .china: return "Zhipu (China)"
        }
    }
    
    var baseURL: String {
        switch self {
        case .global: return "https://api.z.ai"
        case .china: return "https://open.bigmodel.cn"
        }
    }
}

enum APIEndpoint {
    case quotaLimit
    case modelUsage(startTime: String, endTime: String)
    case toolUsage(startTime: String, endTime: String)
    
    var path: String {
        switch self {
        case .quotaLimit:
            return "/api/monitor/usage/quota/limit"
        case .modelUsage:
            return "/api/monitor/usage/model-usage"
        case .toolUsage:
            return "/api/monitor/usage/tool-usage"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .modelUsage(let start, let end), .toolUsage(let start, let end):
            return [
                URLQueryItem(name: "startTime", value: start),
                URLQueryItem(name: "endTime", value: end)
            ]
        case .quotaLimit:
            return nil
        }
    }
}

enum APIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
