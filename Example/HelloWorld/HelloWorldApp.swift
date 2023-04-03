import SwiftUI
import Aptabase

@main
struct HelloWorldApp: App {
    init() {
        Aptabase.initialize(appKey: "A-DEV-000");
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
