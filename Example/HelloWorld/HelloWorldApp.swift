import SwiftUI
import Aptabase

@main
struct HelloWorldApp: App {
    init() {
        Aptabase.shared.initialize(appKey: "A-DEV-7654387617");
    }
    
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}
