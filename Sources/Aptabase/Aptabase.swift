import Foundation

/// Initialization options for the client.
public final class InitOptions: NSObject {
    let host: String?

    /// - Parameter host: The custom host to use. If none provided will use Aptabase's servers.
    @objc public init(host: String? = nil) {
        self.host = host
    }
}

/// The Aptabase client used to track events.
public class Aptabase: NSObject {
    private static var sdkVersion = "aptabase-swift@0.2.1";
    
    // Session expires after 1 hour of inactivity
    private var sessionTimeout: TimeInterval = 1 * 60 * 60
    private var appKey: String?
    private var sessionId = UUID()
    private var env: EnvironmentInfo?
    private var lastTouched = Date()
    private var apiURL: URL?

    /// The shared client instance.
    @objc public static let shared = Aptabase()
    
    private var hosts = [
        "US": "https://us.aptabase.com",
        "EU": "https://eu.aptabase.com",
        "DEV": "http://localhost:3000",
        "SH": ""
    ]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
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
        
        apiURL = getApiUrl(parts[1], options?.host)
        self.appKey = appKey
        env = EnvironmentInfo.get()
    }
    
    /// Track an event using given properties.
    /// - Parameters:
    ///   - eventName: The name of the event to track.
    ///   - props: Additional given properties.
    public func trackEvent(_ eventName: String, with props: [String: Value] = [:]) {
        sendEvent(eventName, with: props)
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
        sendEvent(eventName, with: props)
    }
    
    private func sendEvent(_ eventName: String, with props: [String: Any] = [:]) {
        DispatchQueue(label: "com.aptabase.aptabase").async { [self] in
            guard let appKey = appKey, let env = env, let apiURL = apiURL else {
                return
            }
            
            let now = Date()
            if lastTouched.distance(to: now) > sessionTimeout {
                sessionId = UUID()
            }
            
            lastTouched = now

            let body: [String: Any] = [
                "timestamp": dateFormatter.string(from: Date()),
                "sessionId": sessionId.uuidString.lowercased(),
                "eventName": eventName,
                "systemProps": [
                    "isDebug": env.isDebug,
                    "osName": env.osName,
                    "osVersion": env.osVersion,
                    "locale": env.locale,
                    "appVersion": env.appVersion,
                    "appBuildNumber": env.appBuildNumber,
                    "sdkVersion": Aptabase.sdkVersion
                ] as [String : Any],
                "props": props
            ]
            
            if !JSONSerialization.isValidJSONObject(props) {
                debugPrint("Aptabase: unable to serialize custom props. Event will be discarded.")
                return
            }
            
            guard let body = try? JSONSerialization.data(withJSONObject: body) else { return }

            var request = URLRequest(url: apiURL)
            request.httpBody = body
            request.httpMethod = "POST"
            request.addValue(appKey, forHTTPHeaderField: "App-Key")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    debugPrint(error?.localizedDescription ?? "unknown error")
                    return
                }
                
                if let response = response as? HTTPURLResponse,
                   let body = String(data: data, encoding: .utf8),
                   response.statusCode >= 300 {
                    debugPrint("trackEvent failed with status code \(response.statusCode): \(body)")
                }
            }

            task.resume()
        }
    }
    
    private func getApiUrl(_ region: String, _ host: String?) -> URL? {
        guard var baseURL = hosts[region] else { return nil }
        if region == "SH" {
            guard let host = host else {
                debugPrint("Host parameter must be defined when using Self-Hosted App Key. Tracking will be disabled.")
                return nil
            }
            baseURL = host
        }
        
        return URL(string: "\(baseURL)/api/v0/event")
    }
}
