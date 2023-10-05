import XCTest
@testable import Aptabase

final class EventDispatcherTests: XCTestCase {
    var dispatcher: EventDispatcher!
    var configuration: URLSessionConfiguration!
    let env = EnvironmentInfo(
        isDebug: true,
        osName: "iOS",
        osVersion: "17.0",
        appVersion: "1.0.0"
    )

    override func setUp() {
        super.setUp()
        configuration = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            return config
        }()
        dispatcher = EventDispatcher(
            appKey: "A-DEV-000",
            baseUrl: "http://localhost:3000",
            env: env,
            configuration: configuration
        )
    }

    override func tearDown() {
        dispatcher = nil
        configuration = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testFlushEmptyQueue() async {
        await dispatcher.flush()
        XCTAssertEqual(MockURLProtocol.requestCount, 0)
    }
    
    func testFlushSingleItem() async {
        dispatcher.enqueue(newEvent("app_started"))
        
        await dispatcher.flush()
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testFlushShouldBatchMultipleItems() async {
        dispatcher.enqueue(newEvent("app_started"))
        dispatcher.enqueue(newEvent("item_created"))
        dispatcher.enqueue(newEvent("item_deleted"))
        
        await dispatcher.flush()
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
        
        await dispatcher.flush()
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testFlushShouldRetryAfterFailure() async {
        dispatcher.enqueue(newEvent("app_started"))
        dispatcher.enqueue(newEvent("item_created"))
        dispatcher.enqueue(newEvent("item_deleted"))
        
        MockURLProtocol.responseStatusCode = 500
        await dispatcher.flush()
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
        
        MockURLProtocol.responseStatusCode = 200
        await dispatcher.flush()
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
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
