import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Focus", systemImage: "brain.head.profile") {
                FocusView()
            }

            Tab("Sleep", systemImage: "moon.stars") {
                SleepView()
            }

            Tab("Library", systemImage: "square.grid.2x2") {
                LibraryView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AudioManager.shared)
}
