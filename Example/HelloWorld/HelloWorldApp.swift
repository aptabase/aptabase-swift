import SwiftUI
import Aptabase

@main
struct HelloWorldApp: App {
    init() {
        Aptabase.shared.initialize(appKey: "A-US-0928558097");
    }
    
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}
