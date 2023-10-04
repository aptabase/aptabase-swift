import Foundation

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
        self.flushInterval = options?.flushInterval ?? (env.isDebug ? 60.0 : 2.0)
        self.env = env
        
        self.dispatcher = EventDispatcher(appKey: appKey, baseUrl: baseUrl, env: env)
    }
    
    public func trackEvent(_ eventName: String, with props: [String: Any] = [:]) {
        guard JSONSerialization.isValidJSONObject(props) else {
            debugPrint("Aptabase: unable to serialize custom props. Event will be discarded.")
            return
        }
        
        let now = Date()
        if lastTouched.distance(to: now) > AptabaseClient.sessionTimeout {
            sessionId = UUID()
        }
        lastTouched = now
        
        let evt = Event(timestamp: dateFormatter.string(from: Date()),
                        sessionId: sessionId.uuidString,
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
