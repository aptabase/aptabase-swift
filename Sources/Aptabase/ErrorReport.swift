//
//  ErrorReport.swift
//  Aptabase
//
//  Created by Joshua Wolfson on 6/9/2026.
//

import Foundation

/**
 * Severity of a reported error: "fatal" for errors the app cannot recover from.
 */
enum ErrorSeverity: String, Encodable {
    case fatal
    case error
}

/**
 * How the error was captured: "handled" (manual trackError), "unhandled" or
 * "crash" (automatic crash reporting), "taskException" (async task failures).
 */
enum ErrorKind: String, Encodable {
    /// automatic crash reporting
    case crash
    /// automatic crash reporting
    case unhandled
    /// async task failures
    case taskException
    /// Manual `.trackError`
    case handled
}

/**
 * An error report sent to the error ingestion endpoint (one object per request).
 */
struct ErrorReport: Encodable {
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
    
    static func build(
            _ error: Error,
            fatal: Bool,
            sessionId: String,
            sdkVersion: String,
            env: EnvironmentInfo
        ) -> ErrorReport {
            let typeName = String(describing: type(of: error))
            let errorMessage = (error as NSError).localizedDescription
            let prefix = fatal ? "Fatal " : ""
            let severity: ErrorSeverity = fatal ? .fatal : .error
            let kind: ErrorKind = fatal ? .crash : .handled
            let stack = Thread.callStackSymbols.joined(separator: "\n")

            return ErrorReport(
                errorMessage: "\(prefix)\(typeName): \(errorMessage)",
                errorType: typeName,
                stackTrace: stack.isEmpty ? nil : stack,
                timestamp: Date(),
                sessionId: sessionId,
                platform: "Apple",
                osName: env.osName.isEmpty ? nil : env.osName,
                osVersion: env.osVersion.isEmpty ? nil : env.osVersion,
                appVersion: env.appVersion.isEmpty ? nil : env.appVersion,
                sdkVersion: sdkVersion,
                severity: severity,
                kind: kind,
                isDebug: env.isDebug
            )
        }
}
