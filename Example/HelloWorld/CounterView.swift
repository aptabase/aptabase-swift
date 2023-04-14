import SwiftUI
import Aptabase

struct CounterView: View {
    @State var count: Int = 0
    
    var body: some View {
        VStack {
            Text("Count = \(count)")
            Button(action: {
                self.count += 1
                Aptabase.shared.trackEvent("Increment", with: ["count": self.count])
            }) {
                Text("Increment")
            }.padding()
        }
    }
}

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView()
    }
}
