import Foundation
import Observation

enum FocusTimerState: Sendable, Equatable {
    case idle
    case focusing
    case shortBreak
    case longBreak
    case completed
}

protocol TimerClock: Sendable {
    func sleep(for duration: Duration) async throws
}

struct ContinuousTimerClock: TimerClock {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

@Observable
final class FocusViewModel {

    // MARK: - Configuration

    var focusDuration: TimeInterval = 25 * 60
    var shortBreakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval = 15 * 60
    var sessionsBeforeLongBreak: Int = 4

    // MARK: - Runtime State

    private(set) var timerState: FocusTimerState = .idle
    private(set) var timeRemaining: TimeInterval = 0
    private(set) var currentSession: Int = 0
    private(set) var totalFocusSecondsAccumulated: TimeInterval = 0
    private(set) var isPaused: Bool = false

    // MARK: - Dependencies

    private let clock: TimerClock
    private var timerTask: Task<Void, Never>?

    init(clock: TimerClock = ContinuousTimerClock()) {
        self.clock = clock
    }

    // MARK: - Computed

    var progress: Double {
        let total = totalDurationForCurrentState
        guard total > 0 else { return 0 }
        return 1.0 - (timeRemaining / total)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var isTimerActive: Bool {
        switch timerState {
        case .focusing, .shortBreak, .longBreak:
            return true
        case .idle, .completed:
            return false
        }
    }

    private var totalDurationForCurrentState: TimeInterval {
        switch timerState {
        case .focusing: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        case .idle, .completed: return 0
        }
    }
}
