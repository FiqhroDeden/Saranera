import AVFoundation
import Observation

@Observable
final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Public State

    private(set) var activeSoundIDs: Set<String> = []
    let maxSimultaneous = 3

    var isPlaying: Bool {
        !activeSoundIDs.isEmpty
    }

    // MARK: - Internal State

    private var volumes: [String: Float] = [:]
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var engine: AVAudioEngine?
    private var isEngineRunning = false
    private let audioEnabled: Bool

    // MARK: - Frequency mapping for test tones

    private static let frequencyMap: [String: Float] = [
        "rain": 261.63,         // C4
        "thunder": 293.66,      // D4
        "forest": 329.63,       // E4
        "ocean_waves": 349.23,  // F4
        "white_noise": 392.00,  // G4
        "brown_noise": 440.00,  // A4
        "pink_noise": 493.88,   // B4
        "fireplace": 523.25,    // C5
        "wind": 587.33,         // D5
        "night_crickets": 659.25, // E5
        "coffee_shop": 698.46,  // F5
        "library_ambience": 783.99, // G5
    ]

    // MARK: - Init

    init(audioEnabled: Bool = true) {
        self.audioEnabled = audioEnabled
        if audioEnabled {
            engine = AVAudioEngine()
            configureAudioSession()
            observeInterruptions()
        }
    }

    // MARK: - Public API

    func play(sound: Sound) {
        // Toggle: if already playing, stop it
        if activeSoundIDs.contains(sound.id) {
            stop(sound: sound)
            return
        }

        // Reject if at max capacity
        guard activeSoundIDs.count < maxSimultaneous else { return }

        activeSoundIDs.insert(sound.id)
        volumes[sound.id] = 1.0

        guard audioEnabled, let engine else { return }

        do {
            try startEngineIfNeeded()

            let node = AVAudioPlayerNode()
            engine.attach(node)

            let format = engine.mainMixerNode.outputFormat(forBus: 0)
            engine.connect(node, to: engine.mainMixerNode, format: format)

            let frequency = Self.frequencyMap[sound.id] ?? 440.0
            let buffer = generateTestToneBuffer(frequency: frequency, duration: 2.0, format: format)

            node.scheduleBuffer(buffer, at: nil, options: .loops)
            node.volume = 1.0
            node.play()

            playerNodes[sound.id] = node
            buffers[sound.id] = buffer
        } catch {
            print("AudioManager: Failed to play sound \(sound.id): \(error)")
        }
    }

    func stop(sound: Sound) {
        guard activeSoundIDs.contains(sound.id) else { return }

        if let node = playerNodes[sound.id] {
            node.stop()
            engine?.detach(node)
        }

        playerNodes.removeValue(forKey: sound.id)
        buffers.removeValue(forKey: sound.id)
        volumes.removeValue(forKey: sound.id)
        activeSoundIDs.remove(sound.id)

        if activeSoundIDs.isEmpty, let engine {
            engine.stop()
            isEngineRunning = false
        }
    }

    func stopAll() {
        let ids = Array(activeSoundIDs)
        for id in ids {
            if let sound = Sound.catalog.first(where: { $0.id == id }) {
                stop(sound: sound)
            }
        }
    }

    func setVolume(for sound: Sound, to volume: Float) {
        guard activeSoundIDs.contains(sound.id) else { return }
        let clampedVolume = min(max(volume, 0.0), 1.0)
        volumes[sound.id] = clampedVolume
        playerNodes[sound.id]?.volume = clampedVolume
    }

    func volume(for sound: Sound) -> Float {
        volumes[sound.id] ?? 0.0
    }

    func isActive(_ sound: Sound) -> Bool {
        activeSoundIDs.contains(sound.id)
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("AudioManager: Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Engine

    private func startEngineIfNeeded() throws {
        guard !isEngineRunning, let engine else { return }
        try engine.start()
        isEngineRunning = true
    }

    // MARK: - Interruption Handling

    private func observeInterruptions() {
        Task {
            let notifications = NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification)
            for await notification in notifications {
                handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            engine?.pause()
            isEngineRunning = false
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                do {
                    try engine?.start()
                    isEngineRunning = true
                    for id in activeSoundIDs {
                        if let node = playerNodes[id], let buffer = buffers[id] {
                            node.scheduleBuffer(buffer, at: nil, options: .loops)
                            node.play()
                        }
                    }
                } catch {
                    print("AudioManager: Failed to resume after interruption: \(error)")
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Test Tone Generation

    private func generateTestToneBuffer(frequency: Float, duration: TimeInterval, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(sampleRate * Float(duration))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = Int(format.channelCount)
        let omega = 2.0 * Float.pi * frequency / sampleRate

        for channel in 0..<channels {
            let channelData = buffer.floatChannelData![channel]
            for frame in 0..<Int(frameCount) {
                channelData[frame] = 0.3 * sin(omega * Float(frame))
            }
        }

        return buffer
    }
}
