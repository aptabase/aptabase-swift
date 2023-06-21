import Foundation

public final class InitOptions: NSObject {
    let host: String?

    @objc public init(host: String? = nil) {
        self.host = host
    }
}

// The Aptabase client used to track events
public class Aptabase: NSObject {
    private static var sdkVersion = "aptabase-swift@0.1.0";
    
    // Session expires after 1 hour of inactivity
    private var sessionTimeout: TimeInterval = 1 * 60 * 60
    private var appKey: String?
    private var sessionId = UUID()
    private var env: EnvironmentInfo?
    private var lastTouched = Date()
    private var apiURL: URL?

    @objc public static let shared = Aptabase()
    
    private var hosts = [
        "US": "https://us.aptabase.com",
        "EU": "https://eu.aptabase.com",
        "DEV": "http://localhost:3000",
        "SH": ""
    ]

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    // Initializes the client with given App Key
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
    
    // Track an event using given properties
    public func trackEvent(_ eventName: String, with props: [String: Value] = [:]) {
        sendEvent(eventName, with: props)
    }
    
    @objc public func initialize(appKey: String) {
        initialize(appKey: appKey, with: nil)
    }
    
    @objc public func initialize(appKey: String, options: InitOptions?) {
        initialize(appKey: appKey, with: options)
    }
    
    @objc public func trackEvent(_ eventName: String, with props: [String: Any] = [:]) {
        sendEvent(eventName, with: props)
    }
    
    private func sendEvent(_ eventName: String, with props: [String: Any] = [:]) {
        DispatchQueue(label: "com.aptabase.aptabase").async { [self] in
            guard let appKey, let env, let apiURL else {
                return
            }
            
            let now = Date()
            if (lastTouched.distance(to: now) > sessionTimeout) {
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
                guard let data, error == nil else {
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
            guard let host else {
                debugPrint("Host parameter must be defined when using Self-Hosted App Key. Tracking will be disabled.")
                return nil
            }
            baseURL = host
        }
        
        return URL(string: "\(baseURL)/api/v0/event")
    }
}
