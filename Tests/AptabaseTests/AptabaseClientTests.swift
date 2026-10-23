import XCTest
@testable import Aptabase

private actor DeliverySession: URLSessionProtocol {
    let delivered: XCTestExpectation
    private var events: [[String: Any]] = []
    private var attempts = 0

    init(delivered: XCTestExpectation) { self.delivered = delivered }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        attempts += 1
        if attempts == 1 {
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!)
        }
        events += try JSONSerialization.jsonObject(with: request.httpBody!) as! [[String: Any]]
        delivered.fulfill()
        return (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }

    func eventNames() -> [String] { events.compactMap { $0["eventName"] as? String } }
}

final class AptabaseClientTests: XCTestCase {
    @MainActor func testInitializationRetriesWithoutActivationNotification() async {
        let delivered = expectation(description: "Timer retries an event without app activation or manual flush")
        let session = DeliverySession(delivered: delivered)
        let client = AptabaseClient(appKey: "A-DEV-000", baseUrl: "http://localhost:3000",
            env: EnvironmentInfo(isDebug: true, osName: "macOS", osVersion: "14.0", appVersion: "1.0", deviceModel: "Mac"),
            options: InitOptions(flushInterval: 0.05), session: session)
        defer { client.stopPolling() }
        await client.trackEvent("finder_operation")
        await fulfillment(of: [delivered], timeout: 2)
        let names = await session.eventNames()
        XCTAssertEqual(names, ["finder_operation"])
    }
}
