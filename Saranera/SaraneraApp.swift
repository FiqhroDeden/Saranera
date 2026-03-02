import SwiftUI
import SwiftData

@main
struct SaraneraApp: App {
    @State private var storeManager = StoreManager()
    @State private var downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
                .environment(storeManager)
                .environment(downloadManager)
                .task {
                    await storeManager.loadProducts()
                    storeManager.listenForTransactions()
                    await storeManager.updateEntitlements()
                    downloadManager.checkDownloadedPacks()
                }
        }
        .modelContainer(for: FocusSession.self)
    }
}
