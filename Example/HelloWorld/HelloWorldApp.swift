import SwiftUI
import Aptabase

@main
struct HelloWorldApp: App {
    init() {
        Aptabase.initialize(appKey: "A-DEV-7654387617");
    }
    
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}
