//
//  File.swift
//  Aptabase
//
//  Created by Joshua Wolfson on 6/9/2026.
//

import Foundation

struct Event: Encodable {
    var timestamp: Date
    var sessionId: String
    var eventName: String
    var systemProps: SystemProps
    var props: [String: AnyCodableValue]?

    struct SystemProps: Encodable {
        var isDebug: Bool
        var locale: String
        var osName: String
        var osVersion: String
        var appVersion: String
        var appBuildNumber: String
        var sdkVersion: String
        var deviceModel: String
    }
}
