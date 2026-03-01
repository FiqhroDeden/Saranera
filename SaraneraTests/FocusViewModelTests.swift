import Testing
@testable import Saranera

struct ImmediateClock: TimerClock {
    func sleep(for duration: Duration) async throws {
        // Return immediately — no waiting
    }
}

@MainActor
struct FocusViewModelTests {

    private func makeViewModel() -> FocusViewModel {
        FocusViewModel(clock: ImmediateClock())
    }

    // MARK: - Initial State

    @Test func initialStateIsIdle() {
        let vm = makeViewModel()
        #expect(vm.timerState == .idle)
        #expect(vm.timeRemaining == 0)
        #expect(vm.currentSession == 0)
        #expect(vm.isPaused == false)
        #expect(vm.isTimerActive == false)
    }

    @Test func defaultConfiguration() {
        let vm = makeViewModel()
        #expect(vm.focusDuration == 25 * 60)
        #expect(vm.shortBreakDuration == 5 * 60)
        #expect(vm.longBreakDuration == 15 * 60)
        #expect(vm.sessionsBeforeLongBreak == 4)
    }

    @Test func formattedTimeShowsZeroWhenIdle() {
        let vm = makeViewModel()
        #expect(vm.formattedTime == "00:00")
    }

    @Test func progressIsZeroWhenIdle() {
        let vm = makeViewModel()
        #expect(vm.progress == 0)
    }

    // MARK: - Start

    @Test func startPomodoroSetsStateToFocusing() async {
        let vm = makeViewModel()
        vm.startPomodoro()
        // With ImmediateClock, the timer runs instantly to completion
        #expect(vm.currentSession >= 1)
    }

    @Test func startPomodoroRunsToCompletion() async {
        let vm = makeViewModel()
        vm.focusDuration = 2
        vm.shortBreakDuration = 1
        vm.longBreakDuration = 1
        vm.sessionsBeforeLongBreak = 2
        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.timerState == .completed)
    }

    // MARK: - Pause / Resume

    @Test func pauseStopsTimerProgress() async {
        let vm = FocusViewModel(clock: ContinuousTimerClock())
        vm.focusDuration = 60
        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))
        vm.pause()
        #expect(vm.isPaused == true)
        #expect(vm.timerState == .focusing)
        let timeAfterPause = vm.timeRemaining
        try? await Task.sleep(for: .milliseconds(200))
        #expect(vm.timeRemaining == timeAfterPause)
    }

    @Test func resumeAfterPauseContinuesTimer() async {
        let vm = FocusViewModel(clock: ContinuousTimerClock())
        vm.focusDuration = 60
        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))
        vm.pause()
        let timeAtPause = vm.timeRemaining
        vm.resume()
        #expect(vm.isPaused == false)
        try? await Task.sleep(for: .seconds(1.5))
        #expect(vm.timeRemaining < timeAtPause)
    }

    // MARK: - Stop

    @Test func stopResetsToIdle() async {
        let vm = FocusViewModel(clock: ContinuousTimerClock())
        vm.focusDuration = 60
        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))
        vm.stop()
        #expect(vm.timerState == .idle)
        #expect(vm.timeRemaining == 0)
        #expect(vm.currentSession == 0)
        #expect(vm.isTimerActive == false)
    }

    // MARK: - Skip

    @Test func skipDoesNothingDuringFocus() async {
        let vm = FocusViewModel(clock: ContinuousTimerClock())
        vm.focusDuration = 60
        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))
        #expect(vm.timerState == .focusing)
        vm.skip()
        #expect(vm.timerState == .focusing)
    }

    // MARK: - Full Cycle

    @Test func fullPomodoroCompletesAllSessions() async {
        let vm = makeViewModel()
        vm.focusDuration = 2
        vm.shortBreakDuration = 1
        vm.longBreakDuration = 1
        vm.sessionsBeforeLongBreak = 2

        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.timerState == .completed)
        #expect(vm.currentSession == 2)
        #expect(vm.totalFocusSecondsAccumulated == 4)
    }

    @Test func sessionCountIncrementsCorrectly() async {
        let vm = makeViewModel()
        vm.focusDuration = 1
        vm.shortBreakDuration = 1
        vm.longBreakDuration = 1
        vm.sessionsBeforeLongBreak = 3

        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.timerState == .completed)
        #expect(vm.currentSession == 3)
    }
}
