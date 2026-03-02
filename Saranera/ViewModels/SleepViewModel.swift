import Foundation
import Observation

enum SleepTimerState: Sendable, Equatable {
    case idle
    case playing
    case fadingOut
    case completed
}

@Observable
final class SleepViewModel {

    // MARK: - Configuration

    var selectedDuration: TimeInterval = 30 * 60
    var selectedFadeOut: TimeInterval = 5 * 60

    // MARK: - Runtime State

    private(set) var timerState: SleepTimerState = .idle
    private(set) var timeRemaining: TimeInterval = 0

    // MARK: - Fade State

    private var originalVolumes: [String: Float] = [:]

    // MARK: - Dependencies

    private let clock: TimerClock
    private var timerTask: Task<Void, Never>?
    private var resetTask: Task<Void, Never>?
    private weak var audioManager: AudioManager?

    init(clock: TimerClock = ContinuousTimerClock()) {
        self.clock = clock
    }

    // MARK: - Computed

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var isActive: Bool {
        switch timerState {
        case .playing, .fadingOut:
            return true
        case .idle, .completed:
            return false
        }
    }

    var timerProgress: Double {
        guard selectedDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / selectedDuration)
    }

    // MARK: - Actions

    func start(audioManager: AudioManager) {
        guard timerState == .idle || timerState == .completed else { return }
        self.audioManager = audioManager
        timeRemaining = selectedDuration
        originalVolumes = [:]
        timerState = .playing
        startTicking()
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        resetTask?.cancel()
        resetTask = nil

        // Restore original volumes if we were fading
        if timerState == .fadingOut, let audioManager {
            for (soundID, volume) in originalVolumes {
                if let sound = Sound.catalog.first(where: { $0.id == soundID }) {
                    audioManager.setVolume(for: sound, to: volume)
                }
            }
        }

        originalVolumes = [:]
        timerState = .idle
        timeRemaining = 0
        audioManager = nil
    }

    // MARK: - Timer Engine

    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await clock.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                tick()
            }
        }
    }

    private func tick() {
        guard timeRemaining > 0 else { return }

        timeRemaining -= 1

        // Check if we should enter fade-out
        if timerState == .playing && selectedFadeOut > 0 && timeRemaining <= selectedFadeOut {
            enterFadeOut()
        }

        // Apply fade volume if fading
        if timerState == .fadingOut {
            applyFadeVolume()
        }

        // Check completion
        if timeRemaining <= 0 {
            complete()
        }
    }

    private func enterFadeOut() {
        guard timerState == .playing, let audioManager else { return }
        timerState = .fadingOut
        // Capture current volumes
        for soundID in audioManager.activeSoundIDs {
            if let sound = Sound.catalog.first(where: { $0.id == soundID }) {
                originalVolumes[soundID] = audioManager.volume(for: sound)
            }
        }
    }

    private func applyFadeVolume() {
        guard selectedFadeOut > 0, let audioManager else { return }
        let fadeProgress = Float(timeRemaining / selectedFadeOut)
        for (soundID, originalVolume) in originalVolumes {
            if let sound = Sound.catalog.first(where: { $0.id == soundID }) {
                audioManager.setVolume(for: sound, to: originalVolume * fadeProgress)
            }
        }
    }

    private func complete() {
        timerTask?.cancel()
        timerTask = nil
        audioManager?.stopAll()
        timerState = .completed
        originalVolumes = [:]

        // Auto-reset after 3 seconds
        resetTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await clock.sleep(for: .seconds(3))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            timerState = .idle
            timeRemaining = 0
            audioManager = nil
        }
    }
}
