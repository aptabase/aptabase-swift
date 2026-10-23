import Foundation

/// Severity of a reported error: `fatal` for errors the app cannot recover from, otherwise `error`.
enum ErrorSeverity: String, Encodable {
    case fatal
    case error
}

/// How an error was captured. The SDK currently produces `handled` (manual `trackError`) and
/// `crash` (manual `trackError` with `fatal: true`). `unhandled` and `taskException` are part of
/// the server contract and reserved for automatic crash reporting.
enum ErrorKind: String, Encodable {
    case crash
    case unhandled
    case taskException
    case handled
}

/// An error report sent to the error ingestion endpoint (one object per request).
struct ErrorReport: Encodable {
    // Field limits enforced by the error ingestion endpoint. Exceeding any of them rejects the
    // whole report with 400, so values are truncated at capture time.
    static let maxErrorMessage = 5000
    static let maxErrorType = 100
    static let maxStackTrace = 10000
    static let maxPlatform = 30
    static let maxOSName = 30
    static let maxOSVersion = 100
    static let maxAppVersion = 50
    static let maxSdkVersion = 40
    static let maxSessionId = 100

    // Identifies the SDK platform server-side; deliberately distinct from osName.
    static let platform = "Apple"

    var errorMessage: String
    var errorType: String
    var stackTrace: String?
    var timestamp: Date
    var sessionId: String
    var platform: String
    var osName: String?
    var osVersion: String?
    var appVersion: String?
    var sdkVersion: String
    var severity: ErrorSeverity
    var kind: ErrorKind
    var isDebug: Bool

    /// Builds a report, stamping the timestamp and session at capture time so retried sends keep
    /// their original attribution, and clamping every field to the server's limits.
    /// - Parameter stackTrace: A stack captured at the call site. When nil the current stack is used,
    ///   which is only meaningful when called synchronously from the reporting thread.
    static func build(
        _ error: Error,
        fatal: Bool,
        sessionId: String,
        sdkVersion: String,
        env: EnvironmentInfo,
        stackTrace: String? = nil
    ) -> ErrorReport {
        let (typeName, message) = describe(error)
        let prefix = fatal ? "Fatal " : ""
        let stack = stackTrace ?? captureStackTrace()

        return ErrorReport(
            errorMessage: truncate("\(prefix)\(typeName): \(message)", maxErrorMessage),
            errorType: truncate(typeName, maxErrorType),
            stackTrace: stack.isEmpty ? nil : truncate(stack, maxStackTrace),
            timestamp: Date(),
            sessionId: truncate(sessionId, maxSessionId),
            platform: truncate(platform, maxPlatform),
            osName: truncateOptional(env.osName, maxOSName),
            osVersion: truncateOptional(env.osVersion, maxOSVersion),
            appVersion: truncateOptional(env.appVersion, maxAppVersion),
            sdkVersion: truncate(sdkVersion, maxSdkVersion),
            severity: fatal ? .fatal : .error,
            kind: fatal ? .crash : .handled,
            isDebug: env.isDebug
        )
    }

    /// Derives a type name the dashboard can group on and a readable message from any error.
    static func describe(_ error: Error) -> (type: String, message: String) {
        // An NSError carries no useful Swift type, so group by domain and code the way Xcode prints
        // them. This covers errors thrown by Objective-C APIs and Swift's Foundation error structs
        // (URLError, CocoaError, POSIXError), which are boxed as their NSError when passed as `Error`.
        if type(of: error) is NSError.Type {
            let nsError = error as NSError
            return ("\(nsError.domain) \(nsError.code)", nsError.localizedDescription)
        }

        let typeName = String(describing: type(of: error))

        if let description = (error as? LocalizedError)?.errorDescription, !description.isEmpty {
            return (typeName, description)
        }

        // Bridging a plain Swift error to NSError only yields "The operation couldn't be completed.",
        // so its own description (the enum case, or the struct's fields) is more useful.
        return (typeName, String(describing: error))
    }

    /// Captures the current call stack with the SDK's own leading frames removed, so the first
    /// frame is the caller of `trackError`.
    static func captureStackTrace() -> String {
        return format(Thread.callStackSymbols)
    }

    static func format(_ frames: [String]) -> String {
        let callerFrames = frames.drop(while: isSDKFrame)
        return (callerFrames.isEmpty ? frames[...] : callerFrames).joined(separator: "\n")
    }

    // Symbols from this module are mangled with the module name, e.g. "$s8Aptabase11ErrorReportV…".
    private static func isSDKFrame(_ frame: String) -> Bool {
        return frame.contains("$s8Aptabase")
    }

    private static func truncate(_ value: String, _ maxLength: Int) -> String {
        return value.count > maxLength ? String(value.prefix(maxLength)) : value
    }

    private static func truncateOptional(_ value: String, _ maxLength: Int) -> String? {
        return value.isEmpty ? nil : truncate(value, maxLength)
    }
}
