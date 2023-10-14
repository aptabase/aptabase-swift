import Foundation

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
