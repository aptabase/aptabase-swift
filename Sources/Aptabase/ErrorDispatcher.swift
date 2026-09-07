//
//  File.swift
//  Aptabase
//
//  Created by Joshua Wolfson on 5/9/2026.
//

import Foundation

// Errors have their own dispatcher because the error endpoint takes a single object per request and has different retry semantics than the events endpoint: 408/429 must be retried, while 403 (monthly error quota exhausted) must never be retried.
public class ErrorDispatcher: Dispatcher<ErrorReport> {
    internal var queue = ConcurrentQueue<ErrorReport>()
    internal let maximumBatchSize = 1
    internal let headers: [String: String]
    internal let apiUrl: URL
    internal let session: URLSessionProtocol
    
    private let maximumQueueSize: Int = 25
    
    required init(appKey: String, baseUrl: String, env: EnvironmentInfo, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        apiUrl = URL(string: "\(baseUrl)/api/v0/error")!
        headers = [
            "Content-Type": "application/json",
            "App-Key": appKey,
            "User-Agent": "\(env.osName)/\(env.osVersion) \(env.locale)"
        ]
    }
    
    func enqueue(_ report: ErrorReport) {
        if queue.count >= maximumQueueSize {
            debugPrint("Aptabase: Error report queue is full. Dropping report.")
            return
        }

        queue.enqueue(report)
    }
    
    func sendItems(_ items: [ErrorReport]) async throws {
        // only send the first error report
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
             
             // The server reports an exhausted monthly error quota as 403
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
