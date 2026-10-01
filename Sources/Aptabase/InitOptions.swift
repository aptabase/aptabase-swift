import Foundation

/// Initialization options for the client.
public final class InitOptions: NSObject {
    let host: String?
    let flushInterval: Double?
    let trackingMode: TrackingMode
    let appVersion: String?

    /// - Parameters:
    ///   - host: The custom host to use. If none provided will use Aptabase's servers.
    ///   - flushInterval: Defines a custom interval for flushing events.
    ///   - trackingMode: Use TrackingMode.asDebug for debug events, TrackingMode.asRelease for release events, or TrackingMode.readFromEnvironment to use the environment setting. Defaults to .readFromEnvironment if omitted.
    ///   - appVersion: Override the app version. If none provided will use the version from the app bundle.
    @objc public init(host: String? = nil, flushInterval: NSNumber? = nil, trackingMode: TrackingMode = .readFromEnvironment, appVersion: String? = nil) {
        self.host = host
        self.flushInterval = flushInterval?.doubleValue
        self.trackingMode = trackingMode
        self.appVersion = appVersion
    }
}
