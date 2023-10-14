import Foundation

class AptabaseClient {
    private static let sdkVersion = "aptabase-swift@0.3.3"
    // Session expires after 1 hour of inactivity
    private static let sessionTimeout: TimeInterval = 1 * 60 * 60

    private var sessionId = UUID()
    private var lastTouched = Date()
    private var flushTimer: Timer?
    private let dispatcher: EventDispatcher
    private let env: EnvironmentInfo
    private let flushInterval: Double

    init(appKey: String, baseUrl: String, env: EnvironmentInfo, options: InitOptions?) {
        flushInterval = options?.flushInterval ?? (env.isDebug ? 2.0 : 60.0)
        self.env = env

        dispatcher = EventDispatcher(appKey: appKey, baseUrl: baseUrl, env: env)
    }

    public func trackEvent(_ eventName: String, with props: [String: AnyCodableValue] = [:]) {
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
                        ),
                        props: props)
        dispatcher.enqueue(evt)
    }

    public func startPolling() {
        stopPolling()

        flushTimer = Timer.scheduledTimer(timeInterval: flushInterval, target: self, selector: #selector(flushSync), userInfo: nil, repeats: true)
    }

    public func stopPolling() {
        flushTimer?.invalidate()
        flushTimer = nil

        flushSync()
    }

    public func flush() async {
        await dispatcher.flush()
    }

    @objc private func flushSync() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await self.flush()
            semaphore.signal()
        }
        semaphore.wait()
    }
}
