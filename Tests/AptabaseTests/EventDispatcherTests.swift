import XCTest
@testable import Aptabase

class MockURLSession: URLSessionProtocol {
    var requestCount: Int = 0
    var statusCode: Int = 200
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestCount += 1
        
        let data = "{}".data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

final class EventDispatcherTests: XCTestCase {
    var dispatcher: EventDispatcher!
    var session: MockURLSession!
    let env = EnvironmentInfo(
        isDebug: true,
        osName: "iOS",
        osVersion: "17.0",
        appVersion: "1.0.0"
    )

    override func setUp() {
        super.setUp()
        session = MockURLSession()
        dispatcher = EventDispatcher(
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
        dispatcher.enqueue(newEvent("app_started"))
        
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
    }
    
    func testFlushShouldBatchMultipleItems() async {
        dispatcher.enqueue(newEvent("app_started"))
        dispatcher.enqueue(newEvent("item_created"))
        dispatcher.enqueue(newEvent("item_deleted"))
        
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
        
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
    }
    
    func testFlushShouldRetryAfterFailure() async {
        dispatcher.enqueue(newEvent("app_started"))
        dispatcher.enqueue(newEvent("item_created"))
        dispatcher.enqueue(newEvent("item_deleted"))
        
        
        session.statusCode = 500
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 1)
        
        session.statusCode = 200
        await dispatcher.flush()
        XCTAssertEqual(session.requestCount, 2)
    }
    
    private func newEvent(_ eventName: String) -> Event {
        return Event(timestamp: Date(),
                     sessionId: UUID(),
                     eventName: eventName,
                     systemProps: Event.SystemProps(isDebug: env.isDebug,
                                                    locale: env.locale,
                                                    osName: env.osName,
                                                    osVersion: env.osVersion,
                                                    appVersion: env.appVersion,
                                                    appBuildNumber: env.appBuildNumber,
                                                    sdkVersion: "aptabase-swift@0.0.0")
        )
    }
}
