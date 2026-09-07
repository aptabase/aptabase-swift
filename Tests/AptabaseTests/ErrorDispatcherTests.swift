import XCTest
@testable import Aptabase

private struct TestError: Error {}

final class ErrorDispatcherTests: XCTestCase {
    var dispatcher: ErrorDispatcher!
    var session: MockURLSession!
    let env = EnvironmentInfo(
        isDebug: true,
        osName: "iOS",
        osVersion: "17.0",
        appVersion: "1.0.0",
        appBuildNumber: "1",
        deviceModel: "iPhone16,2"
    )

    override func setUp() {
        super.setUp()
        session = MockURLSession()
        dispatcher = ErrorDispatcher(
            appKey: "A-DEV-000",
            baseUrl: "http://localhost:3000",
            env: env,
            session: session
        )
    }

    override func tearDown() {
        dispatcher = nil
        session = nil
        super.tearDown()
    }

    func testFlushEmptyQueue() async {
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 0)
    }

    func testFlushSingleItem() async {
        dispatcher.enqueue(newReport())

        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
    }

    func testFlushShouldRetryAfterFailure() async {
        dispatcher.enqueue(newReport())

        session.statusCode = 500
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)

        session.statusCode = 200
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 2)
    }

    func testFlushShouldNotRetryForbidden() async {
        dispatcher.enqueue(newReport())

        session.statusCode = 403
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)

        session.statusCode = 200
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
    }

    func testFlushShouldDropWhenQueueIsFull() async {
        session.statusCode = 403
        for _ in 0...25 {
            dispatcher.enqueue(newReport())
        }

        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 25)
    }

    func testFlushShouldPostErrorEndpoint() async throws {
        dispatcher.enqueue(newReport(fatal: true))

        await dispatcher.flush()
        XCTAssertEqual(session.lastRequest?.url?.absoluteString, "http://localhost:3000/api/v0/error")

        let body = try XCTUnwrap(session.lastRequest?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["platform"] as? String, "Apple")
        XCTAssertEqual(json["severity"] as? String, "fatal")
        XCTAssertEqual(json["kind"] as? String, "crash")
    }

    private func newReport(fatal: Bool = false) -> ErrorReport {
        ErrorReport.build(
            TestError(),
            fatal: fatal,
            sessionId: UUID().uuidString,
            sdkVersion: "aptabase-swift@0.0.0",
            env: env
        )
    }
}
