import Foundation

class AptabaseClient {
    private static let sdkVersion = "aptabase-swift@0.3.11"
    // Session expires after 1 hour of inactivity
    private static let sessionTimeout: TimeInterval = 1 * 60 * 60

    private var sessionId = newSessionId()
    private var lastTouched = Date()
    private var flushTimer: Timer?
    private let eventDispatcher: EventDispatcher
    private let errorDispatcher: ErrorDispatcher
    private let env: EnvironmentInfo
    private let flushInterval: Double
    private var pauseFlushTimer: Bool = false

    init(appKey: String, baseUrl: String, env: EnvironmentInfo, options: InitOptions?) {
        flushInterval = options?.flushInterval ?? (env.isDebug ? 2.0 : 60.0)
        self.env = env

        eventDispatcher = EventDispatcher(appKey: appKey, baseUrl: baseUrl, env: env)
        errorDispatcher = ErrorDispatcher(appKey: appKey, baseUrl: baseUrl, env: env)
    }

    public func trackEvent(_ eventName: String, with props: [String: AnyCodableValue] = [:]) {
        evaluateSessionId()
        
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
                            sdkVersion: AptabaseClient.sdkVersion,
                            deviceModel: env.deviceModel
                        ),
                        props: props)
        eventDispatcher.enqueue(evt)
    }
    
    public func trackError(_ error: any Error, fatal: Bool = false) {
        evaluateSessionId()
        
        let errorReport = ErrorReport.build(error, fatal: fatal, sessionId: sessionId, sdkVersion: AptabaseClient.sdkVersion, env: env)
        
        errorDispatcher.enqueue(errorReport)
    }

    public func startPolling() {
        stopPolling()

        flushTimer = Timer.scheduledTimer(timeInterval: flushInterval, target: self, selector: #selector(timerFlushSync), userInfo: nil, repeats: true)
    }

    public func stopPolling() {
        flushTimer?.invalidate()
        flushTimer = nil
        
        Task {
            await flush()
        }
        
    }

    public func flush() async {
        await eventDispatcher.flush()
        await errorDispatcher.flush()
    }
    
    private func evaluateSessionId() {
        let now = Date()
        if lastTouched.distance(to: now) > AptabaseClient.sessionTimeout {
            sessionId = AptabaseClient.newSessionId()
        }
        lastTouched = now
    }
    
    private static func newSessionId() -> String {
        let epochInSeconds = UInt64(Date().timeIntervalSince1970)
        let random = UInt64.random(in: 0...99999999)
        return String(epochInSeconds * 100000000 + random)
    }

    @objc private func timerFlushSync() {
        if !pauseFlushTimer {
            Task {
                self.pauseFlushTimer = true
                await self.flush()
                self.pauseFlushTimer = false
            }
        }
    }
}
