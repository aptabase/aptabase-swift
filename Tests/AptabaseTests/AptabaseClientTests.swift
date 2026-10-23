import XCTest
@testable import Aptabase

private enum ClientTestError: Error { case failed }

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

private actor RecordingSession: URLSessionProtocol {
    let received: XCTestExpectation
    private(set) var bodies: [[String: Any]] = []

    init(received: XCTestExpectation) { self.received = received }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        bodies.append(try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any])
        received.fulfill()
        return (Data(), HTTPURLResponse(url: request.url!, statusCode: 202, httpVersion: nil, headerFields: nil)!)
    }
}

final class AptabaseClientTests: XCTestCase {
    private let env = EnvironmentInfo(isDebug: true, osName: "macOS", osVersion: "14.0", appVersion: "1.0", deviceModel: "Mac")

    @MainActor func testInitializationRetriesWithoutActivationNotification() async {
        let delivered = expectation(description: "Timer retries an event without app activation or manual flush")
        let session = DeliverySession(delivered: delivered)
        let client = AptabaseClient(appKey: "A-DEV-000", baseUrl: "http://localhost:3000", env: env,
                                    options: InitOptions(flushInterval: 0.05), session: session)
        defer { client.stopPolling() }
        await client.trackEvent("finder_operation")
        await fulfillment(of: [delivered], timeout: 2)
        let names = await session.eventNames()
        XCTAssertEqual(names, ["finder_operation"])
    }

    @MainActor func testTrackErrorSendsImmediatelyWithCallerStack() async throws {
        let received = expectation(description: "Error report is sent without waiting for the flush timer")
        let session = RecordingSession(received: received)
        let client = AptabaseClient(appKey: "A-DEV-000", baseUrl: "http://localhost:3000", env: env,
                                    options: InitOptions(flushInterval: 3600), session: session)
        defer { client.stopPolling() }

        // the synchronous entry point used by Aptabase.shared.trackError
        let trackError: (any Error, Bool) -> Void = client.trackError
        trackError(ClientTestError.failed, false)

        await fulfillment(of: [received], timeout: 2)
        let bodies = await session.bodies
        let body = try XCTUnwrap(bodies.first)
        XCTAssertEqual(body["errorType"] as? String, "ClientTestError")
        XCTAssertEqual(body["errorMessage"] as? String, "ClientTestError: failed")
        XCTAssertEqual(body["kind"] as? String, "handled")

        let stack = try XCTUnwrap(body["stackTrace"] as? String)
        let firstFrame = stack.split(separator: "\n").first.map(String.init) ?? ""
        XCTAssertTrue(firstFrame.contains("testTrackErrorSendsImmediatelyWithCallerStack"), "first frame should be the caller, got: \(firstFrame)")
        XCTAssertFalse(stack.contains("$s8Aptabase0A6ClientC10trackError"), "SDK frames should be stripped")
    }
}
