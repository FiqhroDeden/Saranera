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
}
