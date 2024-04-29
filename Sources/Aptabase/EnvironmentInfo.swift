import Foundation

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#elseif os(tvOS)
import TVUIKit
#endif

struct EnvironmentInfo {
    var isDebug = false
    var osName = ""
    var osVersion = ""
    var locale = ""
    var appVersion = ""
    var appBuildNumber = ""
    var deviceModel = ""

    static func current() -> EnvironmentInfo {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appBuildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

        return EnvironmentInfo(
            isDebug: isDebug,
            osName: osName,
            osVersion: osVersion,
            locale: Locale.current.languageCode ?? "",
            appVersion: appVersion ?? "",
            appBuildNumber: appBuildNumber ?? "",
            deviceModel: deviceModel
        )
    }

    private static var isDebug: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private static var osName: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        "macOS"
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "iPadOS"
        }
        return "iOS"
        #elseif os(watchOS)
        "watchOS"
        #elseif os(tvOS)
        "tvOS"
        #elseif os(visionOS)
        "visionOS"
        #else
        ""
        #endif
    }

    private static var osVersion: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        #elseif os(iOS) || os(tvOS) || os(visionOS)
        UIDevice.current.systemVersion
        #elseif os(watchOS)
        WKInterfaceDevice.current().systemVersion
        #else
        ""
        #endif
    }

    private static var deviceModel: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        // `uname` returns x86_64 (or Apple Silicon equivalent) for Macs.
        // Use `sysctlbyname` here instead to get actual model name. If it fails, fall back to `uname`.
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        if size > 0 {
            var model = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.model", &model, &size, nil, 0)
            let deviceModel = String(cString: model)
            // If we got a deviceModel, use it. Else continue to "default" logic.
            if !deviceModel.isEmpty {
                return deviceModel
            }
        }
        #endif

        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        } else {
            var systemInfo = utsname()
            if uname(&systemInfo) == 0 {
                let identifier = withUnsafePointer(to: &systemInfo.machine) { ptr in
                    ptr.withMemoryRebound(to: CChar.self, capacity: 1) { machinePtr in
                        String(cString: machinePtr)
                    }
                }
                return identifier
            }
            return ""
        }
    }
}
