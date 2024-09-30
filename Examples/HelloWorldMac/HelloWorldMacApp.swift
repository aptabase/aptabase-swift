import SwiftUI
import Aptabase

@main
struct HelloWorldMacApp: App {
    init() {
        Aptabase.shared.initialize(
            appKey: "A-DEV-0000000000", 
            // optionally track events as release, avoiding the default environment variable
            options: InitOptions(trackingMode: .asRelease) 
        )
    }
    
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}
