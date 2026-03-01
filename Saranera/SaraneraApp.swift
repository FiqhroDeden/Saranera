import SwiftUI

@main
struct SaraneraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
        }
    }
}
