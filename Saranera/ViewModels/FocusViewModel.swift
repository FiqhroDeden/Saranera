import Foundation
import Observation
import SwiftData

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
    private(set) var totalFocusMinutesToday: Int = 0
    private(set) var sessionsCompletedToday: Int = 0

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

    // MARK: - Actions

    func startPomodoro() {
        guard timerState == .idle || timerState == .completed else { return }
        currentSession = 1
        totalFocusSecondsAccumulated = 0
        isPaused = false
        transitionTo(.focusing)
    }

    func pause() {
        guard isTimerActive, !isPaused else { return }
        isPaused = true
        timerTask?.cancel()
        timerTask = nil
    }

    func resume() {
        guard isTimerActive, isPaused else { return }
        isPaused = false
        startTicking()
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .idle
        timeRemaining = 0
        currentSession = 0
        isPaused = false
    }

    func skip() {
        switch timerState {
        case .shortBreak:
            currentSession += 1
            transitionTo(.focusing)
        case .longBreak:
            timerState = .completed
            timerTask?.cancel()
            timerTask = nil
        case .focusing, .idle, .completed:
            break // skip does nothing outside breaks
        }
    }

    // MARK: - Persistence

    func saveSession(to context: ModelContext) {
        let focusMinutes = Int(totalFocusSecondsAccumulated / 60)
        guard focusMinutes > 0 else { return }

        let session = FocusSession(
            date: Date(),
            focusMinutes: focusMinutes,
            sessionsCompleted: currentSession,
            focusDuration: Int(focusDuration / 60),
            shortBreakDuration: Int(shortBreakDuration / 60),
            longBreakDuration: Int(longBreakDuration / 60)
        )
        context.insert(session)
        do {
            try context.save()
        } catch {
            print("FocusViewModel: Failed to save session: \(error)")
        }
    }

    func loadTodayStats(from context: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        var descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { session in
                session.date >= startOfDay && session.date < endOfDay
            }
        )
        descriptor.fetchLimit = 100

        do {
            let sessions = try context.fetch(descriptor)
            totalFocusMinutesToday = sessions.reduce(0) { $0 + $1.focusMinutes }
            sessionsCompletedToday = sessions.reduce(0) { $0 + $1.sessionsCompleted }
        } catch {
            totalFocusMinutesToday = 0
            sessionsCompletedToday = 0
        }
    }

    // MARK: - Timer Engine

    private func transitionTo(_ state: FocusTimerState) {
        timerState = state
        switch state {
        case .focusing:
            timeRemaining = focusDuration
            startTicking()
        case .shortBreak:
            timeRemaining = shortBreakDuration
            startTicking()
        case .longBreak:
            timeRemaining = longBreakDuration
            startTicking()
        case .completed, .idle:
            timerTask?.cancel()
            timerTask = nil
        }
    }

    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await clock.sleep(for: .seconds(1))
                } catch {
                    return // Task cancelled
                }
                guard !Task.isCancelled else { return }
                tick()
            }
        }
    }

    private func tick() {
        guard timeRemaining > 0 else { return }

        timeRemaining -= 1

        if timerState == .focusing {
            totalFocusSecondsAccumulated += 1
        }

        if timeRemaining <= 0 {
            handlePhaseCompletion()
        }
    }

    private func handlePhaseCompletion() {
        switch timerState {
        case .focusing:
            if currentSession >= sessionsBeforeLongBreak {
                transitionTo(.longBreak)
            } else {
                transitionTo(.shortBreak)
            }
        case .shortBreak:
            currentSession += 1
            transitionTo(.focusing)
        case .longBreak:
            timerState = .completed
            timerTask?.cancel()
            timerTask = nil
        case .idle, .completed:
            break
        }
    }
}
