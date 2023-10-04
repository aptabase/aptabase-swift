import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#elseif os(tvOS)
import TVUIKit
#endif

/// The Aptabase client used to track events.
public class Aptabase: NSObject {
    private static var sdkVersion = "aptabase-swift@0.3.0";
    
    private var env = EnvironmentInfo.current()
    private var client: AptabaseClient?

    /// The shared client instance.
    @objc public static let shared = Aptabase()
    
    /// Initializes the client with given App Key.
    /// - Parameters:
    ///   - appKey: The App Key to use.
    ///   - options: Optional initialization options.
    public func initialize(appKey: String, with options: InitOptions? = nil) {
        let parts = appKey.components(separatedBy: "-")
        if parts.count != 3 || hosts[parts[1]] == nil {
            debugPrint("The Aptabase App Key \(appKey) is invalid. Tracking will be disabled.")
            return
        }
        
        guard let baseUrl = self.getBaseUrl(parts[1], options?.host) else {
            return
        }
        
        self.client = AptabaseClient(appKey: appKey, baseUrl: baseUrl, env: env, options: options)
        
        let notifications = NotificationCenter.default
        #if os(tvOS) || os(iOS)
        notifications.addObserver(self, selector: #selector(startPolling), name: UIApplication.willEnterForegroundNotification, object: nil)
        notifications.addObserver(self, selector: #selector(stopPolling), name: UIApplication.didEnterBackgroundNotification, object: nil)
        #elseif os(macOS)
        notifications.addObserver(self, selector: #selector(stopPolling), name: NSApplication.willTerminateNotification, object: nil)
        #elseif os(watchOS)
        notifications.addObserver(self, selector: #selector(startPolling), name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        notifications.addObserver(self, selector: #selector(stopPolling), name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
        #endif
    }
    
    /// Track an event using given properties.
    /// - Parameters:
    ///   - eventName: The name of the event to track.
    ///   - props: Additional given properties.
    public func trackEvent(_ eventName: String, with props: [String: Value] = [:]) {
        enqueueEvent(eventName, with: props)
    }
    
    /// Initializes the client with given App Key.
    /// - Parameter appKey: The App Key to use.
    @objc public func initialize(appKey: String) {
        initialize(appKey: appKey, with: nil)
    }

    /// Initializes the client with given App Key.
    /// - Parameters:
    ///   - appKey: The App Key to use.
    ///   - options: Optional initialization options.
    @objc public func initialize(appKey: String, options: InitOptions?) {
        initialize(appKey: appKey, with: options)
    }
    
    /// Track an event using given properties.
    /// - Parameters:
    ///   - eventName: The name of the event to track.
    ///   - props: Additional given properties.
    @objc public func trackEvent(_ eventName: String, with props: [String: Any] = [:]) {
        enqueueEvent(eventName, with: props)
    }
    
    /// Forces all queued events to be sent to the server
    @objc public func flush() {
        Task {
            await self.client?.flush()
        }
    }
    
    private func enqueueEvent(_ eventName: String, with props: [String: Any] = [:]) {
        guard let client = self.client else {
            return
        }
        
        client.trackEvent(eventName, with: props)
    }
    
    @objc private func startPolling() {
        self.client?.startPolling()
    }
    
    @objc private func stopPolling() {
        self.client?.startPolling()
    }
    
    private var hosts = [
        "US": "https://us.aptabase.com",
        "EU": "https://eu.aptabase.com",
        "DEV": "http://localhost:3000",
        "SH": ""
    ]
    
    private func getBaseUrl(_ region: String, _ host: String?) -> String? {
        guard var baseURL = hosts[region] else { return nil }
        if region == "SH" {
            guard let host = host else {
                debugPrint("Host parameter must be defined when using Self-Hosted App Key. Tracking will be disabled.")
                return nil
            }
            baseURL = host
        }
        
        return baseURL
    }
}
