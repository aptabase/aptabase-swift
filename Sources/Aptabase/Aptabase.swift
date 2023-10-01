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

/// Initialization options for the client.
public final class InitOptions: NSObject {
    let host: String?
    let flushInterval: Double?
    
    /// - Parameters:
    ///   - host: The custom host to use. If none provided will use Aptabase's servers.
    ///   - flushInterval: Defines a custom interval for flushing events.
    @objc public init(host: String? = nil, flushInterval: NSNumber? = nil) {
        self.host = host
        self.flushInterval = flushInterval?.doubleValue
    }
}

/// The Aptabase client used to track events.
public class Aptabase: NSObject {
    private static var sdkVersion = "aptabase-swift@0.3.0";
    
    // Session expires after 1 hour of inactivity
    private var sessionTimeout: TimeInterval = 1 * 60 * 60
    private var sessionId = UUID()
    private var lastTouched = Date()
    private var env = EnvironmentInfo.current()
    private var dispatcher: EventDispatcher?
    private var flushTimer: Timer?
    private var flushInterval: Int

    /// The shared client instance.
    @objc public static let shared = Aptabase()
    
    private var hosts = [
        "US": "https://us.aptabase.com",
        "EU": "https://eu.aptabase.com",
        "DEV": "http://localhost:3000",
        "SH": ""
    ]
    
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
        
        guard let baseUrl = getBaseUrl(parts[1], options?.host) else {
            return
        }
        
        dispatcher = EventDispatcher(appKey: appKey, baseUrl: baseUrl, env: env)
        let defaultFlushInterval = EnvironmentInfo.isDebug ? 60 : 2
        flushInterval = options?.flushInterval ?? defaultFlushInterval
        
        let notifications = NotificationCenter.default
        #if os(tvOS) || os(iOS)
        notifications.addObserver(self, selector: #selector(startPolling), name: UIApplication.willEnterForegroundNotification, object: nil)
        notifications.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        #elseif os(macOS)
        notifications.addObserver(self, selector: #selector(didEnterBackground), name: NSApplication.willTerminateNotification, object: nil)
        #elseif os(watchOS)
        notifications.addObserver(self, selector: #selector(startPolling), name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        notifications.addObserver(self, selector: #selector(didEnterBackground), name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
        #endif
    }
    
    /// Track an event using given properties.
    /// - Parameters:
    ///   - eventName: The name of the event to track.
    ///   - props: Additional given properties.
    public func trackEvent(_ eventName: String, with props: [String: AnyEncodable] = [:]) {
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
            await dispatcher?.flush()
        }
    }
    
    private func enqueueEvent(_ eventName: String, with props: [String: Any] = [:]) {
        guard let dispatcher = dispatcher else {
            return
        }
        
        if !JSONSerialization.isValidJSONObject(props) {
            debugPrint("Aptabase: unable to serialize custom props. Event will be discarded.")
            return
        }
        
        let now = Date()
        if lastTouched.distance(to: now) > sessionTimeout {
            sessionId = UUID()
        }
        lastTouched = now
        
        let evt = Event(timestamp: Date(),
                        sessionId: sessionId,
                        eventName: eventName,
                        systemProps: Event.SystemProps(
                            isDebug: env.isDebug,
                            locale: env.locale,
                            osName: env.osName,
                            osVersion: env.osVersion,
                            appVersion: env.appVersion,
                            appBuildNumber: env.appBuildNumber,
                            sdkVersion: Aptabase.sdkVersion
                        ))
        dispatcher.enqueue(evt)
    }
    
    @objc func willEnterForeground() {
        startPolling()
    }
    
    @objc func didEnterBackground() {
        flushTimer?.invalidate()
        flushTimer = nil
        
        flush()
    }
    
    @objc private func startPolling() {
        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(flush), userInfo: nil, repeats: true)
        flush()
    }
    
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
