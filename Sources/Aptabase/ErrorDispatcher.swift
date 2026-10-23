import Foundation

// Errors have their own dispatcher because the error endpoint takes a single object per request and
// has different retry semantics than the events endpoint: 408/429 must be retried, while 403
// (monthly error quota exhausted) must never be retried.
actor ErrorDispatcher: Dispatcher {
    typealias Item = ErrorReport

    var queue = ConcurrentQueue<ErrorReport>()
    let maximumBatchSize = 1
    let headers: [String: String]
    let apiUrl: URL
    let session: URLSessionProtocol
    let encoder = makeDispatcherEncoder()

    // Max number of unsent reports kept in memory. New reports are dropped when full, so the first
    // occurrences (closest to the root cause) are kept.
    private let maximumQueueSize = 25

    init(appKey: String, baseUrl: String, env: EnvironmentInfo, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        apiUrl = URL(string: "\(baseUrl)/api/v0/error")!
        headers = [
            "Content-Type": "application/json",
            "App-Key": appKey,
            "User-Agent": "\(env.osName)/\(env.osVersion) \(env.locale)"
        ]
    }

    func enqueue(_ report: ErrorReport) {
        enqueue([report])
    }

    func enqueue(_ reports: [ErrorReport]) {
        let capacity = max(0, maximumQueueSize - queue.count)
        if reports.count > capacity {
            debugPrint("Aptabase: Error report queue is full. Dropping \(reports.count - capacity) report(s).")
        }
        queue.enqueue(contentsOf: Array(reports.prefix(capacity)))
    }

    func sendItems(_ items: [ErrorReport]) async throws {
        // the error endpoint takes one report per request
        guard let errorReport = items.first else {
            return
        }

        do {
            let body = try encoder.encode(errorReport)

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

            // The server reports an exhausted monthly error quota as 403 (not 429) precisely so
            // clients drop the report instead of retrying it
            if statusCode == 403 {
                debugPrint("Aptabase: Error report rejected because of \(reason). Will not retry.")
                return
            }

            if statusCode == 408 || statusCode == 429 || statusCode >= 500 {
                debugPrint("Aptabase: Failed to send error report because of \(reason). Will retry later.")
                throw NSError(domain: "AptabaseError", code: statusCode, userInfo: ["reason": reason])
            }

            debugPrint("Aptabase: Failed to send error report because of \(reason). Will not retry.")
            return
        } catch {
            debugPrint("Aptabase: Failed to send error report. Reason: \(error)")
            throw error
        }
    }
}
