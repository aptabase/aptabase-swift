#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#elseif os(tvOS)
import TVUIKit
#endif

// The Aptabase client used to track events
public class Aptabase {
    private static var SDK_VERSION = "aptabase-swift@0.0.1";
    
    // Session expires after 1 hour of inactivity
    private static var SESSION_TIMEOUT: TimeInterval = 1 * 60 * 60
    private static var _appKey: String?
    private static var _sessionId = UUID()
    private static var _env: EnvironmentInfo?
    private static var _lastTouched = Date()
    private static var _apiURL: URL?
    
    private static var _regions = [
        "US": "https://api-us.aptabase.com",
        "EU": "https://api-eu.aptabase.com",
        "DEV": "http://localhost:5251"
    ]
    
    // Initializes the client with given App Key
    public static func initialize(appKey: String) {
        let parts = appKey.components(separatedBy: "-")
        if parts.count != 3 {
            print("The Aptabase App Key \(appKey) is invalid. Tracking will be disabled.");
            return
        }
        
        let region = parts[1]
        let baseURL = _regions[region] ?? _regions["DEV"]!
        
        _apiURL = URL(string: "\(baseURL)/v0/event")!
        _appKey = appKey
        _env = EnvironmentInfo.get()
    }
    
    // Track an event and its properties
    public static func trackEvent(_ eventName: String, with props: [String: Any] = [:]) {
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
                    "osName": env.osName,
                    "osVersion": env.osVersion,
                    "locale": env.locale,
                    "appVersion": env.appVersion,
                    "appBuildNumber": env.appBuildNumber,
                    "sdkVersion": SDK_VERSION
                ],
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
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
