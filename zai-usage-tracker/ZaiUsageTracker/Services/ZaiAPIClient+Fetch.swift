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
    
    func fetchAll(platform: Platform, apiKey: String) async throws -> (QuotaLimitResponse, ModelUsageResponse, ToolUsageResponse) {
        async let quota = fetchQuotaLimit(platform: platform, apiKey: apiKey)
        async let model = fetchModelUsage(platform: platform, apiKey: apiKey)
        async let tool = fetchToolUsage(platform: platform, apiKey: apiKey)
        
        return try await (quota, model, tool)
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
    
    private func getTimeWindow() -> (startTime: Int64, endTime: Int64) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current hour
        let currentHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!
        
        // Start: yesterday at current hour
        let start = calendar.date(byAdding: .day, value: -1, to: currentHour)!
        
        // End: today at end of current hour
        let end = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
        
        return (
            startTime: Int64(start.timeIntervalSince1970 * 1000),
            endTime: Int64(end.timeIntervalSince1970 * 1000)
        )
    }
}
