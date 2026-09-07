import Foundation

public class EventDispatcher: Dispatcher<Event> {
    internal var queue = ConcurrentQueue<Event>()
    internal let maximumBatchSize = 25
    internal let headers: [String: String]
    internal let apiUrl: URL
    internal let session: URLSessionProtocol
    
    required init(appKey: String, baseUrl: String, env: EnvironmentInfo, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        apiUrl = URL(string: "\(baseUrl)/api/v0/events")!
        headers = [
            "Content-Type": "application/json",
            "App-Key": appKey,
            "User-Agent": "\(env.osName)/\(env.osVersion) \(env.locale)"
        ]
    }
    
    internal func sendItems(_ items: [Event]) async throws {
        if items.isEmpty {
            return
        }

        do {
            let body = try encoder.encode(items)

            var request = URLRequest(url: apiUrl)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = body

            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode < 300 {
                return
            }

            let responseText = String(data: data, encoding: .utf8) ?? ""
            let reason = "\(statusCode) \(responseText)"

            if statusCode < 500 {
                debugPrint("Aptabase: Failed to send \(queue.count) events because of \(reason). Will not retry.")
                return
            }

            throw NSError(domain: "AptabaseError", code: statusCode, userInfo: ["reason": reason])
        } catch {
            debugPrint("Aptabase: Failed to send \(queue.count) events. Reason: \(error)")
            throw error
        }
    }
}
