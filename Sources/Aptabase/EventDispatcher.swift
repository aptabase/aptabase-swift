import Foundation

struct Event: Encodable {
    var timestamp: Date
    var sessionId: UUID
    var eventName: String
    var systemProps: SystemProps
    var props: [String: AnyCodableValue]?

    struct SystemProps: Encodable {
        var isDebug: Bool
        var locale: String
        var osName: String
        var osVersion: String
        var appVersion: String
        var appBuildNumber: String
        var sdkVersion: String
    }
}

typealias DataTaskResult = @Sendable (Data?, URLResponse?, Error?) -> Void

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

public class EventDispatcher {
    private var events = ConcurrentQueue<Event>()
    private let MAX_BATCH_SIZE = 25
    private let headers: [String: String]
    private let apiUrl: URL
    private let session: URLSessionProtocol

    init(appKey: String, baseUrl: String, env: EnvironmentInfo, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.apiUrl = URL(string: "\(baseUrl)/api/v0/events")!
        self.headers = [
            "Content-Type": "application/json",
            "App-Key": appKey,
            "User-Agent": "\(env.osName)/\(env.osVersion) \(env.locale)"
        ]
    }

    func enqueue(_ newEvent: Event) {
        events.enqueue(newEvent)
    }

    func enqueue(_ newEvents: [Event]) {
        events.enqueue(contentsOf: newEvents)
    }

    func flush() async {
        if events.isEmpty {
            return
        }

        var failedEvents: [Event] = []
        while (!events.isEmpty)
        {
            let eventsToSend = events.dequeue(count: MAX_BATCH_SIZE)
            do {
                try await sendEvents(eventsToSend)
            } catch {
                failedEvents.append(contentsOf: eventsToSend)
            }
        }

        if !failedEvents.isEmpty {
            enqueue(failedEvents)
        }
    }

    private func sendEvents(_ events: [Event]) async throws {
        if events.isEmpty {
            return
        }
        
        do {
            let body = try encoder.encode(events)
            
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = body
            
            let (data, response) = try await Post(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if (statusCode < 300) {
                return
            }
            
            let responseText = String(data: data , encoding: .utf8) ?? ""
            let reason = "\(statusCode) \(responseText)"
            
            if statusCode < 500 {
                debugPrint("Aptabase: Failed to send \(events.count) events because of \(reason). Will not retry.")
                return
            }

            throw NSError(domain: "AptabaseError", code: statusCode, userInfo: ["reason": reason])
        } catch {
            debugPrint("Aptabase: Failed to send \(events.count) events. Reason: \(error)")
            throw error
        }
    }
    
    // NOTE: This can be replaced by the new async `session.data` when we drop Swift 5.6
    private func Post(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
    
    private var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }()
}
