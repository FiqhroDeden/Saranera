import Foundation
import Observation

@Observable
final class DownloadManager {

    // MARK: - Types

    enum DownloadState: Equatable, Sendable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case failed(String)
    }

    // MARK: - State

    var downloads: [String: DownloadState] = [:]

    // MARK: - File System

    var soundsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    private func packDirectory(for packID: String) -> URL {
        soundsDirectory.appendingPathComponent(packID, isDirectory: true)
    }

    // MARK: - Download

    func downloadPack(_ packID: String) async {
        downloads[packID] = .downloading(progress: 0)

        guard let pack = SoundPack.catalog.first(where: { $0.id == packID }) else {
            downloads[packID] = .failed("Pack not found")
            return
        }

        let request = NSBundleResourceRequest(tags: [pack.odrTag])

        // Observe progress
        let progressTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let fraction = request.progress.fractionCompleted
                self?.downloads[packID] = .downloading(progress: fraction)
                if fraction >= 1.0 { break }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }

        do {
            try await request.beginAccessingResources()
            progressTask.cancel()

            // Copy files to Documents
            let packDir = packDirectory(for: packID)
            try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

            for soundID in pack.soundIDs {
                guard let sound = Sound.catalog.first(where: { $0.id == soundID }) else { continue }
                let baseName = sound.fileName.replacingOccurrences(of: ".m4a", with: "")
                if let sourceURL = Bundle.main.url(forResource: baseName, withExtension: "m4a") {
                    let destURL = packDir.appendingPathComponent(sound.fileName)
                    if !FileManager.default.fileExists(atPath: destURL.path()) {
                        try FileManager.default.copyItem(at: sourceURL, to: destURL)
                    }
                }
            }

            request.endAccessingResources()
            downloads[packID] = .downloaded
        } catch {
            progressTask.cancel()
            downloads[packID] = .failed(error.localizedDescription)
        }
    }

    // MARK: - Cancel

    func cancelDownload(_ packID: String) {
        downloads[packID] = .notDownloaded
    }

    // MARK: - Delete

    func deletePack(_ packID: String) throws {
        let packDir = packDirectory(for: packID)
        if FileManager.default.fileExists(atPath: packDir.path()) {
            try FileManager.default.removeItem(at: packDir)
        }
        downloads[packID] = .notDownloaded
    }

    // MARK: - Check Existing Downloads

    func checkDownloadedPacks() {
        for pack in SoundPack.catalog {
            let packDir = packDirectory(for: pack.id)
            if FileManager.default.fileExists(atPath: packDir.path()) {
                downloads[pack.id] = .downloaded
            }
        }
    }

    // MARK: - Queries

    func isDownloaded(_ packID: String) -> Bool {
        downloads[packID] == .downloaded
    }

    func isDownloaded(soundID: String) -> Bool {
        guard let pack = SoundPack.pack(for: soundID) else { return false }
        return isDownloaded(pack.id)
    }

    func fileURL(for soundID: String) -> URL? {
        guard let sound = Sound.catalog.first(where: { $0.id == soundID }),
              let packID = sound.packID,
              isDownloaded(packID) else { return nil }
        return packDirectory(for: packID).appendingPathComponent(sound.fileName)
    }

    func downloadedSize() -> String {
        let totalBytes = SoundPack.catalog.reduce(into: 0) { total, pack in
            let packDir = packDirectory(for: pack.id)
            guard FileManager.default.fileExists(atPath: packDir.path()) else { return }
            if let enumerator = FileManager.default.enumerator(at: packDir, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    total += size
                }
            }
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
}
