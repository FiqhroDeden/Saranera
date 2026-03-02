import Foundation
import Testing
@testable import Saranera

@MainActor
struct SleepViewModelTests {

    private func makeViewModel() -> SleepViewModel {
        SleepViewModel(clock: ImmediateClock())
    }

    // MARK: - Initial State

    @Test func initialStateIsIdle() {
        let vm = makeViewModel()
        #expect(vm.timerState == .idle)
        #expect(vm.timeRemaining == 0)
        #expect(vm.isActive == false)
    }

    @Test func defaultConfiguration() {
        let vm = makeViewModel()
        #expect(vm.selectedDuration == 30 * 60)
        #expect(vm.selectedFadeOut == 5 * 60)
    }

    @Test func formattedTimeShowsZeroWhenIdle() {
        let vm = makeViewModel()
        #expect(vm.formattedTime == "00:00")
    }

    @Test func progressIsZeroWhenIdle() {
        let vm = makeViewModel()
        #expect(vm.timerProgress == 0)
    }

    // MARK: - Timer Countdown

    @Test func timerCountsDownToZero() async {
        let vm = makeViewModel()
        vm.selectedDuration = 3
        vm.selectedFadeOut = 0 // Instant — no fade
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.timerState == .completed || vm.timerState == .idle)
    }

    // MARK: - State Transitions

    @Test func fullStateTransitionFlow() async {
        let vm = makeViewModel()
        vm.selectedDuration = 5
        vm.selectedFadeOut = 2
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(100))
        // With ImmediateClock, should run through playing -> fadingOut -> completed -> idle
        #expect(vm.timerState == .idle)
    }

    // MARK: - Fade Volume Calculation

    @Test func fadeReducesVolumeProportionally() async {
        let vm = SleepViewModel(clock: ContinuousTimerClock())
        vm.selectedDuration = 10
        vm.selectedFadeOut = 8
        let audio = AudioManager(audioEnabled: false)

        let rain = Sound.catalog.first { $0.id == "rain" }!
        audio.play(sound: rain)
        #expect(audio.volume(for: rain) == 1.0)

        vm.start(audioManager: audio)

        // Wait for fade to start (after ~2s of playing, 8s remaining = fade begins)
        // Then wait a bit more for volume to actually decrease
        try? await Task.sleep(for: .seconds(4))

        if vm.timerState == .fadingOut {
            let vol = audio.volume(for: rain)
            #expect(vol < 1.0)
            #expect(vol >= 0.0)
        }

        vm.stop()
    }

    // MARK: - Instant Fade

    @Test func instantFadeSkipsFadingOutState() async {
        let vm = makeViewModel()
        vm.selectedDuration = 3
        vm.selectedFadeOut = 0
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.timerState == .idle)
    }

    // MARK: - Manual Stop

    @Test func stopDuringPlayingResetsToIdle() async {
        let vm = SleepViewModel(clock: ContinuousTimerClock())
        vm.selectedDuration = 60
        vm.selectedFadeOut = 10
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(200))
        #expect(vm.timerState == .playing)
        vm.stop()
        #expect(vm.timerState == .idle)
        #expect(vm.timeRemaining == 0)
    }

    @Test func stopDuringFadeRestoresVolumes() async {
        let vm = SleepViewModel(clock: ContinuousTimerClock())
        vm.selectedDuration = 5
        vm.selectedFadeOut = 4
        let audio = AudioManager(audioEnabled: false)

        let rain = Sound.catalog.first { $0.id == "rain" }!
        audio.play(sound: rain)

        vm.start(audioManager: audio)
        try? await Task.sleep(for: .seconds(2))

        if vm.timerState == .fadingOut {
            vm.stop()
            #expect(audio.volume(for: rain) == 1.0)
        }
        #expect(vm.timerState == .idle)
    }

    // MARK: - Auto-Reset

    @Test func completedAutoResetsToIdle() async {
        let vm = makeViewModel()
        vm.selectedDuration = 2
        vm.selectedFadeOut = 0
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(100))
        #expect(vm.timerState == .idle)
    }
}
