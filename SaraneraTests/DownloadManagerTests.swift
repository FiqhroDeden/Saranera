import Testing
import Foundation
@testable import Saranera

@MainActor
struct DownloadManagerTests {

    private func makeManager() -> DownloadManager {
        DownloadManager()
    }

    // MARK: - Initial State

    @Test func initialStateIsEmpty() {
        let manager = makeManager()
        #expect(manager.downloads.isEmpty)
    }

    // MARK: - Download State

    @Test func defaultStateIsNotDownloaded() {
        let manager = makeManager()
        #expect(!manager.isDownloaded("app.fiqhrodedhen.Saranera.pack.rainy_day"))
    }

    // MARK: - Sound File URL

    @Test func fileURLReturnsNilForUndownloaded() {
        let manager = makeManager()
        #expect(manager.fileURL(for: "drizzle") == nil)
    }

    @Test func fileURLReturnsPathForDownloaded() {
        let manager = makeManager()
        manager.downloads["app.fiqhrodedhen.Saranera.pack.rainy_day"] = .downloaded
        let url = manager.fileURL(for: "drizzle")
        #expect(url != nil)
        #expect(url!.path().contains("Sounds"))
        #expect(url!.path().contains("drizzle.m4a"))
    }

    // MARK: - isDownloaded for sound ID

    @Test func isSoundDownloadedWhenPackIsDownloaded() {
        let manager = makeManager()
        manager.downloads["app.fiqhrodedhen.Saranera.pack.rainy_day"] = .downloaded
        #expect(manager.isDownloaded(soundID: "drizzle"))
    }

    @Test func isSoundNotDownloadedWhenPackIsNotDownloaded() {
        let manager = makeManager()
        #expect(!manager.isDownloaded(soundID: "drizzle"))
    }

    @Test func isSoundDownloadedReturnsFalseForFreeSound() {
        let manager = makeManager()
        #expect(!manager.isDownloaded(soundID: "rain"))
    }

    // MARK: - Documents Directory

    @Test func soundsDirectoryIsInDocuments() {
        let manager = makeManager()
        let dir = manager.soundsDirectory
        #expect(dir.path().contains("Documents"))
        #expect(dir.path().contains("Sounds"))
    }

    // MARK: - DownloadState Equality

    @Test func downloadStatesAreEquatable() {
        #expect(DownloadManager.DownloadState.notDownloaded == .notDownloaded)
        #expect(DownloadManager.DownloadState.downloaded == .downloaded)
        #expect(DownloadManager.DownloadState.downloading(progress: 0.5) == .downloading(progress: 0.5))
        #expect(DownloadManager.DownloadState.downloading(progress: 0.5) != .downloading(progress: 0.7))
        #expect(DownloadManager.DownloadState.failed("err") == .failed("err"))
    }
}
