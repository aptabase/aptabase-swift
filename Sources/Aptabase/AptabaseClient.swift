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

internal class AptabaseClient {
    private static let sdkVersion = "aptabase-swift@0.3.0";
    // Session expires after 1 hour of inactivity
    private static let sessionTimeout: TimeInterval = 1 * 60 * 60
    
    private var sessionId = UUID()
    private var lastTouched = Date()
    private var flushTimer: Timer?
    private let dispatcher: EventDispatcher
    private let env: EnvironmentInfo
    private let flushInterval: Double
    
    init(appKey: String, baseUrl: String, env: EnvironmentInfo, options: InitOptions?) {
        flushInterval = options?.flushInterval ?? (env.isDebug ? 60.0 : 2.0)
        
        dispatcher = EventDispatcher(appKey: appKey, baseUrl: baseUrl, env: env)
    }
    
    /// Track an event using given properties.
    /// - Parameters:
    ///   - eventName: The name of the event to track.
    ///   - props: Additional given properties.
    public func trackEvent(_ eventName: String, with props: [String: AnyEncodable] = [:]) {
        if !JSONSerialization.isValidJSONObject(props) {
            debugPrint("Aptabase: unable to serialize custom props. Event will be discarded.")
            return
        }
        
        let now = Date()
        if lastTouched.distance(to: now) > AptabaseClient.sessionTimeout {
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
                            sdkVersion: AptabaseClient.sdkVersion
                        ))
        dispatcher.enqueue(evt)
    }
    
    public func startPolling() {
        stopPolling();
        
        flushTimer = Timer.scheduledTimer(timeInterval: self.flushInterval, target: self, selector: #selector(flush), userInfo: nil, repeats: true)
    }
    
    public func stopPolling() {
        flushTimer?.invalidate()
        flushTimer = nil
        
        Task {
            await flush()
        }
    }
    
    @objc public func flush() async {
        await dispatcher.flush()
    }
}
