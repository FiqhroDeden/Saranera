import Testing
@testable import Saranera

@MainActor
struct AudioManagerTests {

    // Helper: get a fresh AudioManager for each test (audio disabled for unit tests)
    private func makeManager() -> AudioManager {
        AudioManager(audioEnabled: false)
    }

    private var rain: Sound {
        Sound.catalog.first { $0.id == "rain" }!
    }

    private var thunder: Sound {
        Sound.catalog.first { $0.id == "thunder" }!
    }

    private var forest: Sound {
        Sound.catalog.first { $0.id == "forest" }!
    }

    private var ocean: Sound {
        Sound.catalog.first { $0.id == "ocean_waves" }!
    }

    // MARK: - Play / Stop

    @Test func playAddsToActiveSounds() async {
        let manager = makeManager()
        manager.play(sound: rain)
        #expect(manager.isActive(rain))
        #expect(manager.isPlaying)
        #expect(manager.activeSoundIDs.count == 1)
    }

    @Test func stopRemovesFromActiveSounds() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.stop(sound: rain)
        #expect(!manager.isActive(rain))
        #expect(!manager.isPlaying)
        #expect(manager.activeSoundIDs.isEmpty)
    }

    @Test func playingActiveSoundTogglesIt() async {
        let manager = makeManager()
        manager.play(sound: rain)
        #expect(manager.isActive(rain))
        manager.play(sound: rain)
        #expect(!manager.isActive(rain))
    }

    // MARK: - Max Simultaneous

    @Test func maxThreeSimultaneousSounds() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.play(sound: thunder)
        manager.play(sound: forest)
        #expect(manager.activeSoundIDs.count == 3)

        // 4th sound should be rejected
        manager.play(sound: ocean)
        #expect(manager.activeSoundIDs.count == 3)
        #expect(!manager.isActive(ocean))
    }

    // MARK: - Stop All

    @Test func stopAllClearsEverything() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.play(sound: thunder)
        manager.play(sound: forest)
        manager.stopAll()
        #expect(manager.activeSoundIDs.isEmpty)
        #expect(!manager.isPlaying)
    }

    // MARK: - Volume

    @Test func setVolumeUpdatesState() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.setVolume(for: rain, to: 0.5)
        #expect(manager.volume(for: rain) == 0.5)
    }

    @Test func setVolumeClampsToRange() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.setVolume(for: rain, to: 1.5)
        #expect(manager.volume(for: rain) == 1.0)
        manager.setVolume(for: rain, to: -0.5)
        #expect(manager.volume(for: rain) == 0.0)
    }

    // MARK: - isActive

    @Test func isActiveReturnsCorrectState() async {
        let manager = makeManager()
        #expect(!manager.isActive(rain))
        manager.play(sound: rain)
        #expect(manager.isActive(rain))
        manager.stop(sound: rain)
        #expect(!manager.isActive(rain))
    }

    // MARK: - Pause / Resume All

    @Test func pauseAllKeepsSoundsInActiveSet() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.play(sound: thunder)
        manager.pauseAll()
        #expect(manager.activeSoundIDs.count == 2)
        #expect(manager.isSuspended == true)
    }

    @Test func resumeAllRestoresPlayback() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.pauseAll()
        #expect(manager.isSuspended == true)
        manager.resumeAll()
        #expect(manager.isSuspended == false)
        #expect(manager.isActive(rain))
    }
}
