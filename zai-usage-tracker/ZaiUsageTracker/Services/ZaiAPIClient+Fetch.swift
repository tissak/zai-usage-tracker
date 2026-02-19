import Foundation

actor ZaiAPIClient {
    static let shared = ZaiAPIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
    }
    
    func fetchQuotaLimit(platform: Platform, apiKey: String) async throws -> QuotaLimitResponse {
        return try await fetch(endpoint: .quotaLimit, platform: platform, apiKey: apiKey)
    }
    
    func fetchModelUsage(platform: Platform, apiKey: String) async throws -> ModelUsageResponse {
        let (startTime, endTime) = getTimeWindow()
        return try await fetch(endpoint: .modelUsage(startTime: startTime, endTime: endTime), platform: platform, apiKey: apiKey)
    }
    
    func fetchToolUsage(platform: Platform, apiKey: String) async throws -> ToolUsageResponse {
        let (startTime, endTime) = getTimeWindow()
        return try await fetch(endpoint: .toolUsage(startTime: startTime, endTime: endTime), platform: platform, apiKey: apiKey)
    }
    
    func fetchWeeklyModelUsage(platform: Platform, apiKey: String) async throws -> ModelUsageResponse {
        let (startTime, endTime) = getWeeklyTimeWindow()
        return try await fetch(endpoint: .modelUsage(startTime: startTime, endTime: endTime), platform: platform, apiKey: apiKey)
    }

    func fetchWeeklyToolUsage(platform: Platform, apiKey: String) async throws -> ToolUsageResponse {
        let (startTime, endTime) = getWeeklyTimeWindow()
        return try await fetch(endpoint: .toolUsage(startTime: startTime, endTime: endTime), platform: platform, apiKey: apiKey)
    }

    func fetchAll(platform: Platform, apiKey: String) async throws -> (
        QuotaLimitResponse, ModelUsageResponse, ToolUsageResponse,
        ModelUsageResponse, ToolUsageResponse
    ) {
        async let quota       = fetchQuotaLimit(platform: platform, apiKey: apiKey)
        async let model       = fetchModelUsage(platform: platform, apiKey: apiKey)
        async let tool        = fetchToolUsage(platform: platform, apiKey: apiKey)
        async let weeklyModel = fetchWeeklyModelUsage(platform: platform, apiKey: apiKey)
        async let weeklyTool  = fetchWeeklyToolUsage(platform: platform, apiKey: apiKey)

        return try await (quota, model, tool, weeklyModel, weeklyTool)
    }
    
    private func fetch<T: Decodable>(endpoint: APIEndpoint, platform: Platform, apiKey: String) async throws -> T {
        var components = URLComponents(string: platform.baseURL + endpoint.path)!
        components.queryItems = endpoint.queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("en-US,en", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func getWeeklyTimeWindow() -> (startTime: String, endTime: String) {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!
        let end = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
        let endWithSeconds = calendar.date(byAdding: .second, value: 59, to: end) ?? end
        let start = calendar.date(byAdding: .day, value: -7, to: end)!
        return (startTime: formatDateTime(start), endTime: formatDateTime(endWithSeconds))
    }

    private func getTimeWindow() -> (startTime: String, endTime: String) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current hour
        let currentHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!
        
        // End: end of current hour (e.g., 15:00)
        let end = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
        let endWithSeconds = calendar.date(byAdding: .second, value: 59, to: end) ?? end
        
        // Start: 24 hours before end
        let start = calendar.date(byAdding: .day, value: -1, to: end)!
        
        return (
            startTime: formatDateTime(start),
            endTime: formatDateTime(endWithSeconds)
        )
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
