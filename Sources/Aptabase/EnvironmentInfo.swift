#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#elseif os(tvOS)
import TVUIKit
#endif

public struct EnvironmentInfo {
    var osName = ""
    var osVersion = ""
    var locale = ""
    var appVersion = ""
    var appBuildNumber = ""
    
    public static func get() -> EnvironmentInfo{
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appBuildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        return EnvironmentInfo(
            osName: getOSName(),
            osVersion: getOSVersion(),
            locale: Locale.current.languageCode ?? "",
            appVersion: appVersion ?? "",
            appBuildNumber: appBuildNumber ?? ""
        )
    }
    
    private static func getOSName() -> String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        if #available(iOS 13.0, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPadOS"
            }
        }
        return "iOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #else
        return ""
        #endif
    }
    
    private static func getOSVersion() -> String {
        #if os(macOS)
        var os = ProcessInfo.processInfo.operatingSystemVersion;
        return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        #elseif os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(tvOS)
        return UIDevice.current.systemVersion
        #else
        return ""
        #endif
    }
}
