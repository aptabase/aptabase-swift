import XCTest
@testable import Aptabase

final class InitOptionsTests: XCTestCase {
    func testAppVersionDefaultsToNil() {
        XCTAssertNil(InitOptions().appVersion)
    }

    func testAppVersionIsKept() {
        XCTAssertEqual(InitOptions(appVersion: "2.0.0-beta3").appVersion, "2.0.0-beta3")
    }

    func testEmptyAppVersionIsIgnored() {
        XCTAssertNil(InitOptions(appVersion: "").appVersion)
        XCTAssertNil(InitOptions(appVersion: "  ").appVersion)
    }

    func testThreeArgumentInitStillWorks() {
        let options = InitOptions(host: "https://example.com", flushInterval: 30, trackingMode: .asRelease)
        XCTAssertEqual(options.host, "https://example.com")
        XCTAssertEqual(options.flushInterval, 30)
        XCTAssertEqual(options.trackingMode, .asRelease)
        XCTAssertNil(options.appVersion)
    }
}
