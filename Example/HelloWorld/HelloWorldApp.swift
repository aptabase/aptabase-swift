import SwiftUI
import Aptabase

@main
struct HelloWorldApp: App {
    init() {
        Aptabase.shared.initialize(appKey: "A-DEV-0000000000");
    }
    
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}
