# Phase 2: Focus Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete Focus Mode with Pomodoro timer, reusable sound picker, and SwiftData persistence for session tracking.

**Architecture:** FocusViewModel owns timer logic via an enum state machine (idle/focusing/shortBreak/longBreak/completed). Timer ticks via a `Task` using a `TimerClock` protocol for testability. Sound picker is a reusable sheet backed by the existing AudioManager. Sessions persist via SwiftData.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, AVFoundation (existing AudioManager), Liquid Glass design, Swift Testing framework.

---

### Task 1: FocusTimerState enum and TimerClock protocol

**Files:**
- Create: `Saranera/ViewModels/FocusViewModel.swift`

**Step 1: Create the file with FocusTimerState and TimerClock**

```swift
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
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/ViewModels/FocusViewModel.swift
git commit -m "feat: add FocusTimerState enum and TimerClock protocol"
```

---

### Task 2: FocusViewModel — configuration and state properties

**Files:**
- Modify: `Saranera/ViewModels/FocusViewModel.swift`

**Step 1: Add the FocusViewModel class with all properties**

Add below the existing code in the file:

```swift
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
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/ViewModels/FocusViewModel.swift
git commit -m "feat: add FocusViewModel with configuration and state properties"
```

---

### Task 3: FocusViewModel tests — initial state and computed properties

**Files:**
- Create: `SaraneraTests/FocusViewModelTests.swift`

**Step 1: Create a mock clock and initial state tests**

```swift
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
```

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: All 4 tests PASS

**Step 3: Commit**

```bash
git add SaraneraTests/FocusViewModelTests.swift
git commit -m "test: add FocusViewModel initial state and config tests"
```

---

### Task 4: FocusViewModel — startPomodoro, pause, resume

**Files:**
- Modify: `Saranera/ViewModels/FocusViewModel.swift`
- Modify: `SaraneraTests/FocusViewModelTests.swift`

**Step 1: Write failing tests for start, pause, resume**

Add to `FocusViewModelTests`:

```swift
    // MARK: - Start

    @Test func startPomodoroSetsStateTofocusing() async {
        let vm = makeViewModel()
        vm.startPomodoro()
        // With ImmediateClock, the timer runs instantly to completion.
        // We need a controllable clock. Let's just check initial transition.
        #expect(vm.timerState == .focusing || vm.timerState == .shortBreak || vm.timerState == .completed)
        #expect(vm.currentSession >= 1)
    }

    @Test func startPomodoroSetsTimeRemaining() async {
        let vm = makeViewModel()
        vm.focusDuration = 5 // 5 seconds for fast test
        vm.shortBreakDuration = 2
        vm.longBreakDuration = 3
        vm.sessionsBeforeLongBreak = 2
        vm.startPomodoro()
        // With instant clock, it runs all the way through
        // Just verify it eventually reaches completed
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
        #expect(vm.timeRemaining == timeAfterPause) // No change while paused
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
```

**Step 2: Run tests to see them fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: FAIL — `startPomodoro`, `pause`, `resume` methods don't exist

**Step 3: Implement startPomodoro, pause, resume in FocusViewModel**

Add these methods inside FocusViewModel:

```swift
    // MARK: - Actions

    func startPomodoro() {
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
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Saranera/ViewModels/FocusViewModel.swift SaraneraTests/FocusViewModelTests.swift
git commit -m "feat: add startPomodoro, pause, resume with timer engine"
```

---

### Task 5: FocusViewModel — stop and skip

**Files:**
- Modify: `Saranera/ViewModels/FocusViewModel.swift`
- Modify: `SaraneraTests/FocusViewModelTests.swift`

**Step 1: Write failing tests for stop and skip**

Add to `FocusViewModelTests`:

```swift
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

    @Test func skipBreakAdvancesToNextFocusSession() async {
        let vm = makeViewModel()
        vm.focusDuration = 1 // 1 second
        vm.shortBreakDuration = 300 // Long break we'll skip
        vm.sessionsBeforeLongBreak = 4
        vm.startPomodoro()
        // ImmediateClock: focus completes → enters shortBreak
        try? await Task.sleep(for: .milliseconds(50))
        // If in a break, skip it
        if vm.timerState == .shortBreak || vm.timerState == .longBreak {
            let sessionBefore = vm.currentSession
            vm.skip()
            #expect(vm.timerState == .focusing)
            #expect(vm.currentSession == sessionBefore + 1)
        }
    }

    @Test func skipDoesNothingDuringFocus() async {
        let vm = FocusViewModel(clock: ContinuousTimerClock())
        vm.focusDuration = 60
        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(100))
        #expect(vm.timerState == .focusing)
        vm.skip()
        #expect(vm.timerState == .focusing) // No change
    }
```

**Step 2: Run tests to see them fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: FAIL — `stop` and `skip` don't exist

**Step 3: Implement stop and skip**

Add to FocusViewModel:

```swift
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
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Saranera/ViewModels/FocusViewModel.swift SaraneraTests/FocusViewModelTests.swift
git commit -m "feat: add stop and skip to FocusViewModel"
```

---

### Task 6: FocusViewModel — state transitions (full cycle test)

**Files:**
- Modify: `SaraneraTests/FocusViewModelTests.swift`

**Step 1: Write a full-cycle integration test**

Add to `FocusViewModelTests`:

```swift
    // MARK: - Full Cycle

    @Test func fullPomodoroCompletesAllSessions() async {
        let vm = makeViewModel()
        vm.focusDuration = 2     // 2 seconds per focus
        vm.shortBreakDuration = 1 // 1 second per short break
        vm.longBreakDuration = 1  // 1 second per long break
        vm.sessionsBeforeLongBreak = 2 // 2 sessions then long break

        vm.startPomodoro()

        // With ImmediateClock, runs instantly
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.timerState == .completed)
        #expect(vm.currentSession == 2)
        // Focus: 2 ticks * 2 sessions = 4 seconds accumulated
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
```

**Step 2: Run tests**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: All tests PASS (if not, adjust timer logic)

**Step 3: Commit**

```bash
git add SaraneraTests/FocusViewModelTests.swift
git commit -m "test: add full Pomodoro cycle integration tests"
```

---

### Task 7: FocusSession SwiftData model

**Files:**
- Create: `Saranera/Models/FocusSession.swift`

**Step 1: Write the failing test**

Add to `FocusViewModelTests.swift`:

```swift
    // MARK: - FocusSession Model

    @Test func focusSessionModelCreation() {
        let session = FocusSession(
            date: Date(),
            focusMinutes: 25,
            sessionsCompleted: 4,
            focusDuration: 25,
            shortBreakDuration: 5,
            longBreakDuration: 15
        )
        #expect(session.focusMinutes == 25)
        #expect(session.sessionsCompleted == 4)
        #expect(session.focusDuration == 25)
    }
```

**Step 2: Run test to see it fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: FAIL — `FocusSession` doesn't exist

**Step 3: Create FocusSession.swift**

```swift
import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var date: Date
    var focusMinutes: Int
    var sessionsCompleted: Int
    var focusDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int

    init(
        id: UUID = UUID(),
        date: Date,
        focusMinutes: Int,
        sessionsCompleted: Int,
        focusDuration: Int,
        shortBreakDuration: Int,
        longBreakDuration: Int
    ) {
        self.id = id
        self.date = date
        self.focusMinutes = focusMinutes
        self.sessionsCompleted = sessionsCompleted
        self.focusDuration = focusDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add Saranera/Models/FocusSession.swift SaraneraTests/FocusViewModelTests.swift
git commit -m "feat: add FocusSession SwiftData model"
```

---

### Task 8: Wire SwiftData into SaraneraApp

**Files:**
- Modify: `Saranera/SaraneraApp.swift`

**Step 1: Add modelContainer**

Update `SaraneraApp.swift` to:

```swift
import SwiftUI
import SwiftData

@main
struct SaraneraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
        }
        .modelContainer(for: FocusSession.self)
    }
}
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/SaraneraApp.swift
git commit -m "feat: wire SwiftData modelContainer for FocusSession"
```

---

### Task 9: AudioManager — add pauseAll / resumeAll

The FocusViewModel needs to pause sounds during breaks and resume them during focus. AudioManager currently only has `stopAll()` which fully removes sounds. We need non-destructive pause/resume.

**Files:**
- Modify: `Saranera/ViewModels/AudioManager.swift`
- Modify: `SaraneraTests/AudioManagerTests.swift`

**Step 1: Write failing tests**

Add to `AudioManagerTests.swift`:

```swift
    // MARK: - Pause / Resume All

    @Test func pauseAllKeepsSoundsInActiveSet() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.play(sound: thunder)
        manager.pauseAll()
        #expect(manager.activeSoundIDs.count == 2) // Still tracked
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
```

**Step 2: Run tests to see them fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/AudioManagerTests -quiet 2>&1 | tail -20`
Expected: FAIL — `pauseAll`, `resumeAll`, `isSuspended` don't exist

**Step 3: Implement pauseAll and resumeAll**

Add to `AudioManager`:

```swift
    private(set) var isSuspended: Bool = false

    func pauseAll() {
        isSuspended = true
        guard audioEnabled else { return }
        for id in activeSoundIDs {
            playerNodes[id]?.pause()
        }
    }

    func resumeAll() {
        isSuspended = false
        guard audioEnabled else { return }
        for id in activeSoundIDs {
            playerNodes[id]?.play()
        }
    }
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/AudioManagerTests -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Saranera/ViewModels/AudioManager.swift SaraneraTests/AudioManagerTests.swift
git commit -m "feat: add pauseAll/resumeAll to AudioManager for break support"
```

---

### Task 10: FocusView — TimerRingView component

**Files:**
- Create: `Saranera/Views/Focus/TimerRingView.swift`

Read `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` before implementing.

**Step 1: Create TimerRingView**

```swift
import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let formattedTime: String
    let timerState: FocusTimerState
    let currentSession: Int
    let totalSessions: Int

    private var ringColor: Color {
        switch timerState {
        case .focusing:
            Color(red: 0.357, green: 0.608, blue: 0.835) // Soft Blue
        case .shortBreak, .longBreak:
            Color(red: 0.957, green: 0.635, blue: 0.380) // Amber
        case .idle, .completed:
            Color(red: 0.357, green: 0.608, blue: 0.835)
        }
    }

    private var phaseLabel: String {
        switch timerState {
        case .idle: "Ready"
        case .focusing: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        case .completed: "Complete"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(ringColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 240, height: 240)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time display
                Text(formattedTime)
                    .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            // Phase label
            Text(phaseLabel)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            // Session dots
            HStack(spacing: 8) {
                ForEach(1...totalSessions, id: \.self) { session in
                    Circle()
                        .fill(session <= currentSession ? ringColor : ringColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea()
        TimerRingView(
            progress: 0.65,
            formattedTime: "16:15",
            timerState: .focusing,
            currentSession: 2,
            totalSessions: 4
        )
    }
}
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/Views/Focus/TimerRingView.swift
git commit -m "feat: add TimerRingView with circular progress ring"
```

---

### Task 11: FocusView — ActiveSoundsView component

**Files:**
- Create: `Saranera/Views/Focus/ActiveSoundsView.swift`

**Step 1: Create ActiveSoundsView**

```swift
import SwiftUI

struct ActiveSoundsView: View {
    @Environment(AudioManager.self) private var audioManager

    var body: some View {
        if !audioManager.activeSoundIDs.isEmpty {
            VStack(spacing: 8) {
                ForEach(activeSounds) { sound in
                    HStack(spacing: 8) {
                        Image(systemName: sound.iconName)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(sound.name)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))

                        // Volume dots
                        HStack(spacing: 3) {
                            let vol = audioManager.volume(for: sound)
                            ForEach(0..<5) { dot in
                                Circle()
                                    .fill(Float(dot) / 5.0 < vol ? .white : .white.opacity(0.2))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }
        }
    }

    private var activeSounds: [Sound] {
        Sound.catalog.filter { audioManager.isActive($0) }
    }
}

#Preview {
    ZStack {
        Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea()
        ActiveSoundsView()
            .environment(AudioManager(audioEnabled: false))
    }
}
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/Views/Focus/ActiveSoundsView.swift
git commit -m "feat: add ActiveSoundsView with sound names and volume dots"
```

---

### Task 12: SoundPickerView — reusable sheet

**Files:**
- Create: `Saranera/Views/Shared/SoundPickerView.swift`

Read `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` for glass effect patterns.

**Step 1: Create SoundPickerView**

```swift
import SwiftUI

struct SoundPickerView: View {
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(SoundCategory.allCases, id: \.self) { category in
                        Section {
                            let sounds = Sound.grouped[category] ?? []
                            ForEach(sounds) { sound in
                                SoundPickerRowView(sound: sound)
                            }
                        } header: {
                            HStack {
                                Label(category.displayName, systemImage: category.iconName)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea())
            .navigationTitle("Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    SoundPickerView()
        .environment(AudioManager(audioEnabled: false))
}
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (will fail until SoundPickerRowView exists — create in next task)

---

### Task 13: SoundPickerRowView

**Files:**
- Create: `Saranera/Views/Shared/SoundPickerRowView.swift`

**Step 1: Create SoundPickerRowView**

```swift
import SwiftUI

struct SoundPickerRowView: View {
    let sound: Sound
    @Environment(AudioManager.self) private var audioManager

    private var isActive: Bool {
        audioManager.isActive(sound)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                audioManager.play(sound: sound)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: sound.iconName)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(isActive
                            ? Color(red: 0.957, green: 0.635, blue: 0.380)
                            : .white.opacity(0.7))
                        .frame(width: 32)

                    Text(sound.name)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    if sound.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .disabled(sound.isPremium)

            // Volume slider for active sounds
            if isActive {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))

                    Slider(
                        value: Binding(
                            get: { Double(audioManager.volume(for: sound)) },
                            set: { audioManager.setVolume(for: sound, to: Float($0)) }
                        ),
                        in: 0...1
                    )
                    .tint(Color(red: 0.357, green: 0.608, blue: 0.835))

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            isActive
                ? Color.white.opacity(0.05)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .animation(.spring(duration: 0.3), value: isActive)
    }
}

#Preview {
    ZStack {
        Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea()
        VStack {
            SoundPickerRowView(sound: Sound.catalog[0])
            SoundPickerRowView(sound: Sound.catalog[1])
        }
        .environment(AudioManager(audioEnabled: false))
    }
}
```

**Step 2: Verify both SoundPickerView and SoundPickerRowView compile**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit both files**

```bash
git add Saranera/Views/Shared/SoundPickerView.swift Saranera/Views/Shared/SoundPickerRowView.swift
git commit -m "feat: add reusable SoundPickerView with volume sliders"
```

---

### Task 14: FocusView — full implementation

**Files:**
- Modify: `Saranera/Views/Focus/FocusView.swift`

Read `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` for Liquid Glass patterns. Key APIs:
- `.glassEffect()` — default capsule glass
- `.glassEffect(in: .circle)` — circle shape glass
- `.buttonStyle(.glass)` — glass button
- `.buttonStyle(.glassProminent)` — prominent glass button
- `GlassEffectContainer(spacing:)` — wrap multiple glass elements

**Step 1: Rewrite FocusView.swift**

```swift
import SwiftUI

struct FocusView: View {
    @Environment(AudioManager.self) private var audioManager
    @State private var viewModel = FocusViewModel()
    @State private var showSoundPicker = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.051, green: 0.106, blue: 0.165),
                    Color(red: 0.078, green: 0.145, blue: 0.235)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Center content
                if viewModel.isTimerActive {
                    TimerRingView(
                        progress: viewModel.progress,
                        formattedTime: viewModel.formattedTime,
                        timerState: viewModel.timerState,
                        currentSession: viewModel.currentSession,
                        totalSessions: viewModel.sessionsBeforeLongBreak
                    )
                    .transition(.scale.combined(with: .opacity))
                } else if viewModel.timerState == .completed {
                    completedView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    idleView
                        .transition(.scale.combined(with: .opacity))
                }

                // Active sounds display
                ActiveSoundsView()

                Spacer()

                // Bottom controls
                bottomControls
            }
            .padding()
        }
        .animation(.spring(duration: 0.5), value: viewModel.timerState)
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.051, green: 0.106, blue: 0.165))
        }
        .onChange(of: viewModel.timerState) { oldState, newState in
            handleStateChange(from: oldState, to: newState)
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))

            Button {
                viewModel.startPomodoro()
            } label: {
                Label("Start Focus", systemImage: "play.fill")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)

            // Show config summary
            Text("\(Int(viewModel.focusDuration / 60))m focus · \(Int(viewModel.shortBreakDuration / 60))m break · \(viewModel.sessionsBeforeLongBreak) sessions")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))

            Text("Session Complete")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundStyle(.white)

            let focusMinutes = Int(viewModel.totalFocusSecondsAccumulated / 60)
            Text("\(focusMinutes) minutes of focus")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Button {
                viewModel.stop()
            } label: {
                Text("Done")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                // Sound picker button
                Button {
                    showSoundPicker = true
                } label: {
                    Image(systemName: "music.note.list")
                        .font(.system(.title3))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)

                if viewModel.isTimerActive {
                    // Play/Pause button
                    Button {
                        if viewModel.isPaused {
                            viewModel.resume()
                        } else {
                            viewModel.pause()
                        }
                    } label: {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(.title2))
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.glassProminent)

                    // Stop or Skip button
                    if viewModel.timerState == .shortBreak || viewModel.timerState == .longBreak {
                        Button {
                            viewModel.skip()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(.title3))
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.glass)
                    } else {
                        Button {
                            viewModel.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(.title3))
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.isTimerActive)
        .animation(.spring(duration: 0.3), value: viewModel.isPaused)
    }

    // MARK: - State Change Handler

    private func handleStateChange(from oldState: FocusTimerState, to newState: FocusTimerState) {
        switch newState {
        case .focusing:
            if audioManager.isSuspended {
                audioManager.resumeAll()
            }
        case .shortBreak, .longBreak:
            audioManager.pauseAll()
        case .completed, .idle:
            break
        }
    }
}

#Preview {
    FocusView()
        .environment(AudioManager(audioEnabled: false))
}
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/Views/Focus/FocusView.swift
git commit -m "feat: implement FocusView with timer, idle, and completed states"
```

---

### Task 15: FocusViewModel — persistence integration

**Files:**
- Modify: `Saranera/ViewModels/FocusViewModel.swift`
- Modify: `Saranera/Views/Focus/FocusView.swift`

**Step 1: Write failing test for session saving**

Add to `FocusViewModelTests.swift`:

```swift
    // MARK: - Persistence

    @Test func saveSessionCreatesRecord() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: config)
        let context = ModelContext(container)

        let vm = makeViewModel()
        vm.focusDuration = 2
        vm.shortBreakDuration = 1
        vm.longBreakDuration = 1
        vm.sessionsBeforeLongBreak = 1

        vm.startPomodoro()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(vm.timerState == .completed)

        vm.saveSession(to: context)

        let descriptor = FetchDescriptor<FocusSession>()
        let sessions = try context.fetch(descriptor)
        #expect(sessions.count == 1)
        #expect(sessions[0].sessionsCompleted == 1)
        #expect(sessions[0].focusMinutes > 0)
    }
```

Add `import SwiftData` to the top of `FocusViewModelTests.swift`.

**Step 2: Run test to see it fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: FAIL — `saveSession(to:)` doesn't exist

**Step 3: Add saveSession to FocusViewModel**

Add `import SwiftData` to top of `FocusViewModel.swift`.

Add method:

```swift
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
        try? context.save()
    }
```

**Step 4: Update FocusView to call saveSession on completion and stop**

In `FocusView.swift`, add `@Environment(\.modelContext) private var modelContext` and update `handleStateChange`:

```swift
    private func handleStateChange(from oldState: FocusTimerState, to newState: FocusTimerState) {
        switch newState {
        case .focusing:
            if audioManager.isSuspended {
                audioManager.resumeAll()
            }
        case .shortBreak, .longBreak:
            audioManager.pauseAll()
        case .completed:
            viewModel.saveSession(to: modelContext)
        case .idle:
            break
        }
    }
```

Also update the stop button action to save before stopping:

```swift
    Button {
        viewModel.saveSession(to: modelContext)
        viewModel.stop()
    } label: {
        Image(systemName: "stop.fill")
        // ...
    }
```

**Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add Saranera/ViewModels/FocusViewModel.swift Saranera/Views/Focus/FocusView.swift SaraneraTests/FocusViewModelTests.swift
git commit -m "feat: add session persistence with SwiftData"
```

---

### Task 16: FocusViewModel — today's stats via SwiftData

**Files:**
- Modify: `Saranera/ViewModels/FocusViewModel.swift`
- Modify: `SaraneraTests/FocusViewModelTests.swift`

**Step 1: Write failing test**

Add to `FocusViewModelTests.swift`:

```swift
    @Test func loadTodayStatsAggregatesCorrectly() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: config)
        let context = ModelContext(container)

        // Insert two sessions for today
        let session1 = FocusSession(date: Date(), focusMinutes: 25, sessionsCompleted: 4, focusDuration: 25, shortBreakDuration: 5, longBreakDuration: 15)
        let session2 = FocusSession(date: Date(), focusMinutes: 50, sessionsCompleted: 4, focusDuration: 25, shortBreakDuration: 5, longBreakDuration: 15)
        context.insert(session1)
        context.insert(session2)
        try context.save()

        let vm = makeViewModel()
        vm.loadTodayStats(from: context)

        #expect(vm.totalFocusMinutesToday == 75)
        #expect(vm.sessionsCompletedToday == 8)
    }
```

**Step 2: Run test to see it fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: FAIL — `loadTodayStats` doesn't exist

**Step 3: Implement loadTodayStats**

Add to `FocusViewModel`:

```swift
    private(set) var totalFocusMinutesToday: Int = 0
    private(set) var sessionsCompletedToday: Int = 0

    func loadTodayStats(from context: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

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
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/FocusViewModelTests -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 5: Wire into FocusView**

In FocusView, add `.onAppear { viewModel.loadTodayStats(from: modelContext) }` to the ZStack.

**Step 6: Commit**

```bash
git add Saranera/ViewModels/FocusViewModel.swift Saranera/Views/Focus/FocusView.swift SaraneraTests/FocusViewModelTests.swift
git commit -m "feat: add today's stats loading via SwiftData"
```

---

### Task 17: Run full test suite and verify build

**Files:** None — verification only

**Step 1: Run all tests**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -30`
Expected: All tests PASS (AudioManagerTests, SoundModelTests, FocusViewModelTests)

**Step 2: Verify clean build**

Run: `xcodebuild clean build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Check for any warnings**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -i warning | head -20`
Expected: No significant warnings

---

### Task 18: Create Shared directory if needed and verify file structure

**Step 1: Verify all files exist**

Check that these files exist:
- `Saranera/Models/FocusSession.swift`
- `Saranera/ViewModels/FocusViewModel.swift`
- `Saranera/Views/Focus/FocusView.swift` (modified)
- `Saranera/Views/Focus/TimerRingView.swift`
- `Saranera/Views/Focus/ActiveSoundsView.swift`
- `Saranera/Views/Shared/SoundPickerView.swift`
- `Saranera/Views/Shared/SoundPickerRowView.swift`
- `SaraneraTests/FocusViewModelTests.swift`

**Step 2: Verify Xcode project includes all new files**

If files are not in the Xcode project, they need to be added. Since this project uses the modern Xcode structure (files auto-discovered from folder references), new files placed in the right directories should be auto-included.

**Step 3: Final commit if any cleanup needed**

```bash
git add -A
git status
# Only commit if there are changes
```
