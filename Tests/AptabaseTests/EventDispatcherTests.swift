import XCTest
@testable import Aptabase

// NOTE: This can be as the URLSessionProtocol should declare the `data` fn when we drop Swift 5.6
class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}

class MockURLSession: URLSessionProtocol {
    var requestCount: Int = 0
    var statusCode: Int = 200
    
    func dataTask(
      with request: URLRequest,
      completionHandler: @escaping DataTaskResult
    ) -> URLSessionDataTask {
        requestCount += 1
        
        let data = "{}".data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        
        return MockURLSessionDataTask {
            completionHandler(data, response, nil)
        }
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
