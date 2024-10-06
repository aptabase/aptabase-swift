import Foundation

/// Initialization options for the client.
public final class InitOptions: NSObject {
    let host: String?
    let flushInterval: Double?
    let trackingMode: TrackingMode

    /// - Parameters:
    ///   - host: The custom host to use. If none provided will use Aptabase's servers.
    ///   - flushInterval: Defines a custom interval for flushing events.
    ///   - trackingMode: Use TrackingMode.asDebug for debug events, TrackingMode.asRelease for release events, or TrackingMode.readFromEnvironment to use the environment setting. Defaults to .readFromEnvironment if omitted.
    @objc public init(host: String? = nil, flushInterval: NSNumber? = nil, trackingMode: TrackingMode = .readFromEnvironment) {
        self.host = host
        self.flushInterval = flushInterval?.doubleValue
        self.trackingMode = trackingMode
    }
}
