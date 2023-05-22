#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#elseif os(tvOS)
import TVUIKit
#endif

public struct InitOptions {
    let host: String?
    
    public init(host: String? = nil) {
        self.host = host
    }
}

// The Aptabase client used to track events
public class Aptabase {
    private static var SDK_VERSION = "aptabase-swift@0.0.7";
    
    // Session expires after 1 hour of inactivity
    private var SESSION_TIMEOUT: TimeInterval = 1 * 60 * 60
    private var _appKey: String?
    private var _sessionId = UUID()
    private var _env: EnvironmentInfo?
    private var _lastTouched = Date()
    private var _apiURL: URL?

    public static let shared = Aptabase()
    
    private var _hosts = [
        "US": "https://us.aptabase.com",
        "EU": "https://eu.aptabase.com",
        "DEV": "http://localhost:3000",
        "SH": ""
    ]
    
    // Initializes the client with given App Key
    public func initialize(appKey: String, with opts: InitOptions? = nil) {
        let parts = appKey.components(separatedBy: "-")
        if parts.count != 3 || _hosts[parts[1]] == nil {
            print("The Aptabase App Key \(appKey) is invalid. Tracking will be disabled.");
            return
        }
        
        _apiURL = getApiUrl(parts[1], opts)
        _appKey = appKey
        _env = EnvironmentInfo.get()
    }
    
    private func getApiUrl(_ region: String, _ opts: InitOptions?) -> URL? {
        var baseURL = _hosts[region]!
        if region == "SH" {
            guard let host = opts?.host else {
                print("Host parameter must be defined when using Self-Hosted App Key. Tracking will be disabled.");
                return nil
            }
            baseURL = host
        }
        
        return URL(string: "\(baseURL)/api/v0/event")!
    }
    
    // Track an event and its properties
    public func trackEvent(_ eventName: String, with props: [String: Any] = [:]) {
        DispatchQueue.global().async { [self] in
            guard let appKey = _appKey, let env = _env, let apiURL = _apiURL else {
                return
            }
            
            let now = Date()
            if (_lastTouched.distance(to: now) > SESSION_TIMEOUT) {
                _sessionId = UUID()
            }
            
            _lastTouched = now
            
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.addValue(appKey, forHTTPHeaderField: "App-Key")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "timestamp": dateFormatter.string(from: Date()),
                "sessionId": _sessionId.uuidString.lowercased(),
                "eventName": eventName,
                "systemProps": [
                    "isDebug": env.isDebug,
                    "osName": env.osName,
                    "osVersion": env.osVersion,
                    "locale": env.locale,
                    "appVersion": env.appVersion,
                    "appBuildNumber": env.appBuildNumber,
                    "sdkVersion": Aptabase.SDK_VERSION
                ] as [String : Any],
                "props": props
            ]
            
            request.httpBody = try! JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "unknown error")
                    return
                }
                
                if let response = response as? HTTPURLResponse, let body = String(data: data, encoding: .utf8) {
                    if (response.statusCode >= 300) {
                        print("trackEvent failed with status code \(response.statusCode): \(body)")
                    }
                }
            }

            task.resume()
        }
    }
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
