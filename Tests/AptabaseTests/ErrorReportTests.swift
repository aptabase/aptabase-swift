import XCTest
@testable import Aptabase

private enum SampleError: Error { case boom }
private struct DescribedError: LocalizedError {
    let errorDescription: String? = "Could not save the document"
}
private struct LongError: LocalizedError {
    let errorDescription: String? = String(repeating: "m", count: 6000)
}

final class ErrorReportTests: XCTestCase {
    private let env = EnvironmentInfo(isDebug: true, osName: "iOS", osVersion: "17.0", appVersion: "1.0.0", appBuildNumber: "1", deviceModel: "iPhone16,2")

    private func build(_ error: Error, fatal: Bool = false, sessionId: String = "1", stackTrace: String? = "frame") -> ErrorReport {
        ErrorReport.build(error, fatal: fatal, sessionId: sessionId, sdkVersion: "aptabase-swift@0.0.0", env: env, stackTrace: stackTrace)
    }

    func testSwiftErrorUsesTypeNameAndDescription() {
        let report = build(SampleError.boom)
        XCTAssertEqual(report.errorType, "SampleError")
        XCTAssertEqual(report.errorMessage, "SampleError: boom")
        XCTAssertEqual(report.severity, .error)
        XCTAssertEqual(report.kind, .handled)
    }

    func testLocalizedErrorUsesErrorDescription() {
        let report = build(DescribedError())
        XCTAssertEqual(report.errorType, "DescribedError")
        XCTAssertEqual(report.errorMessage, "DescribedError: Could not save the document")
    }

    func testNSErrorGroupsByDomainAndCode() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "Offline"])
        let report = build(error)
        XCTAssertEqual(report.errorType, "NSURLErrorDomain -1009")
        XCTAssertEqual(report.errorMessage, "NSURLErrorDomain -1009: Offline")
    }

    func testFoundationErrorStructIsReportedAsItsNSError() {
        // URLError passed as `Error` is boxed as its underlying NSError
        let report = build(URLError(.notConnectedToInternet))
        XCTAssertEqual(report.errorType, "NSURLErrorDomain -1009")
        XCTAssertTrue(report.errorMessage.hasPrefix("NSURLErrorDomain -1009: "), report.errorMessage)
    }

    func testPlainSwiftErrorUsesItsOwnDescription() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "Expected a number")
        let report = build(DecodingError.dataCorrupted(context))
        XCTAssertEqual(report.errorType, "DecodingError")
        XCTAssertTrue(report.errorMessage.contains("Expected a number"), report.errorMessage)
    }

    func testFatalPrefixSeverityAndKind() {
        let report = build(SampleError.boom, fatal: true)
        XCTAssertEqual(report.errorMessage, "Fatal SampleError: boom")
        XCTAssertEqual(report.severity, .fatal)
        XCTAssertEqual(report.kind, .crash)
    }

    func testFieldsAreTruncatedToServerLimits() {
        let longEnv = EnvironmentInfo(isDebug: false,
                                      osName: String(repeating: "o", count: 40),
                                      osVersion: String(repeating: "v", count: 120),
                                      appVersion: String(repeating: "a", count: 60),
                                      appBuildNumber: "1", deviceModel: "x")
        let report = ErrorReport.build(LongError(), fatal: false,
                                       sessionId: String(repeating: "s", count: 150),
                                       sdkVersion: String(repeating: "k", count: 50),
                                       env: longEnv,
                                       stackTrace: String(repeating: "f", count: 12000))
        XCTAssertEqual(report.errorMessage.count, ErrorReport.maxErrorMessage)
        XCTAssertEqual(report.stackTrace?.count, ErrorReport.maxStackTrace)
        XCTAssertEqual(report.sessionId.count, ErrorReport.maxSessionId)
        XCTAssertEqual(report.sdkVersion.count, ErrorReport.maxSdkVersion)
        XCTAssertEqual(report.osName?.count, ErrorReport.maxOSName)
        XCTAssertEqual(report.osVersion?.count, ErrorReport.maxOSVersion)
        XCTAssertEqual(report.appVersion?.count, ErrorReport.maxAppVersion)
    }

    func testEmptyEnvironmentFieldsAreOmitted() {
        let report = ErrorReport.build(SampleError.boom, fatal: false, sessionId: "1", sdkVersion: "s",
                                       env: EnvironmentInfo(), stackTrace: "")
        XCTAssertNil(report.osName)
        XCTAssertNil(report.osVersion)
        XCTAssertNil(report.appVersion)
        XCTAssertNil(report.stackTrace)
    }

    func testStackTraceDropsLeadingSDKFrames() {
        let frames = [
            "0   App   0x0001 $s8Aptabase11ErrorReportV17captureStackTraceSSyFZ + 20",
            "1   App   0x0002 $s8Aptabase0A6ClientC10trackError_5fatalys0D0_p_SbtF + 40",
            "2   App   0x0003 $s8Aptabase0A0C10trackError_5fatalys0D0_p_SbtF + 60",
            "3   App   0x0004 $s3App9ViewModelC4saveyyF + 80",
            "4   App   0x0005 $s8Aptabase9UnrelatedV + 100"
        ]
        XCTAssertEqual(ErrorReport.format(frames), frames[3...].joined(separator: "\n"))
    }

    func testStackTraceKeepsAllFramesWhenOnlySDKFramesAreKnown() {
        let frames = ["0   App   0x0001 $s8Aptabase11ErrorReportV17captureStackTraceSSyFZ + 20"]
        XCTAssertEqual(ErrorReport.format(frames), frames[0])
    }

    func testCapturedStackStartsAtTheCaller() {
        let stack = ErrorReport.captureStackTrace()
        let first = stack.split(separator: "\n").first.map(String.init) ?? ""
        XCTAssertTrue(first.contains("testCapturedStackStartsAtTheCaller"), first)
    }
}
