import Foundation

/// Represents the tracking mode (release/debug) for the client.
@objc public class TrackingMode: NSObject {
    @objc public static let asDebug = TrackingMode(rawValue: 0)
    @objc public static let asRelease = TrackingMode(rawValue: 1)
    @objc public static let readFromEnvironment = TrackingMode(rawValue: 2)
    
    private let rawValue: Int
    
    private init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    @objc public var isDebug: Bool {
        return self.rawValue == 0
    }
    
    @objc public var isRelease: Bool {
        return self.rawValue == 1
    }
    
    @objc public var isReadFromEnvironment: Bool {
        return self.rawValue == 2
    }
}