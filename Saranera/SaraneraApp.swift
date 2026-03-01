import SwiftUI
import SwiftData

@main
struct SaraneraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
        }
        .modelContainer(for: FocusSession.self)
    }
}
