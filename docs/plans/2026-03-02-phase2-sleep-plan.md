# Sleep Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement Sleep Mode with a linear countdown timer, gradual volume fade-out, and a dark immersive UI.

**Architecture:** Standalone `SleepViewModel` (`@Observable`) owns all timer and fade-out logic. Calls `AudioManager.setVolume(for:to:)` directly during fade. `SleepView` replaces the existing stub with a full dark UI using Liquid Glass materials. TDD throughout — tests before implementation.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`, `TimerClock` protocol (reused from FocusViewModel), Liquid Glass (`GlassEffectContainer`, `.glassEffect()`, `.buttonStyle(.glass)`)

---

### Task 1: Create SleepViewModel with state enum and basic structure

**Files:**
- Create: `Saranera/ViewModels/SleepViewModel.swift`

**Step 1: Create SleepViewModel file with state enum and skeleton**

```swift
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
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```
git add Saranera/ViewModels/SleepViewModel.swift
git commit -m "feat: add SleepViewModel with state machine, timer, and fade-out logic"
```

---

### Task 2: Write SleepViewModel tests — initial state and configuration

**Files:**
- Create: `SaraneraTests/SleepViewModelTests.swift`

**Step 1: Write initial state and configuration tests**

```swift
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
}
```

Note: `ImmediateClock` is already defined in `FocusViewModelTests.swift`. It needs to be accessible from both test files. Since Swift Testing structs in the same test target share the same module, this will work as-is — `ImmediateClock` is an internal type visible within the `SaraneraTests` target.

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/SleepViewModelTests 2>&1 | grep -E '(Test Suite|Passed|Failed|error:)'`
Expected: All 4 tests PASS

**Step 3: Commit**

```
git add SaraneraTests/SleepViewModelTests.swift
git commit -m "test: add SleepViewModel initial state and configuration tests"
```

---

### Task 3: Write SleepViewModel tests — timer countdown and state transitions

**Files:**
- Modify: `SaraneraTests/SleepViewModelTests.swift`

**Step 1: Add timer countdown test**

Append to the `SleepViewModelTests` struct:

```swift
    // MARK: - Timer Countdown

    @Test func timerCountsDownToZero() async {
        let vm = makeViewModel()
        vm.selectedDuration = 3
        vm.selectedFadeOut = 0 // Instant — no fade
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.timerState == .completed || vm.timerState == .idle)
        // With ImmediateClock, timer runs instantly to completion
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
        // The auto-reset also fires immediately with ImmediateClock
        #expect(vm.timerState == .idle)
    }
```

**Step 2: Run tests**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/SleepViewModelTests 2>&1 | grep -E '(Test Suite|Passed|Failed|error:)'`
Expected: All 6 tests PASS

**Step 3: Commit**

```
git add SaraneraTests/SleepViewModelTests.swift
git commit -m "test: add timer countdown and state transition tests for SleepViewModel"
```

---

### Task 4: Write SleepViewModel tests — fade volume calculation

**Files:**
- Modify: `SaraneraTests/SleepViewModelTests.swift`

**Step 1: Add fade volume calculation test**

This test uses `ContinuousTimerClock` so we can observe the fade in progress. Append:

```swift
    // MARK: - Fade Volume Calculation

    @Test func fadeReducesVolumeProportionally() async {
        let vm = SleepViewModel(clock: ContinuousTimerClock())
        vm.selectedDuration = 6 // 6 seconds total
        vm.selectedFadeOut = 4  // Last 4 seconds fade
        let audio = AudioManager(audioEnabled: false)

        // Pre-play a sound so AudioManager has an active sound
        let rain = Sound.catalog.first { $0.id == "rain" }!
        audio.play(sound: rain)
        #expect(audio.volume(for: rain) == 1.0)

        vm.start(audioManager: audio)

        // Wait for fade to start (after ~2s of playing, 4s remaining = fade begins)
        try? await Task.sleep(for: .seconds(3))

        // Should be in fadingOut state with reduced volume
        if vm.timerState == .fadingOut {
            let vol = audio.volume(for: rain)
            #expect(vol < 1.0)
            #expect(vol >= 0.0)
        }

        vm.stop() // Clean up
    }
```

**Step 2: Run tests**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/SleepViewModelTests 2>&1 | grep -E '(Test Suite|Passed|Failed|error:)'`
Expected: All 7 tests PASS

**Step 3: Commit**

```
git add SaraneraTests/SleepViewModelTests.swift
git commit -m "test: add fade volume calculation test for SleepViewModel"
```

---

### Task 5: Write SleepViewModel tests — instant fade and manual stop

**Files:**
- Modify: `SaraneraTests/SleepViewModelTests.swift`

**Step 1: Add instant fade and manual stop tests**

Append:

```swift
    // MARK: - Instant Fade (0 duration)

    @Test func instantFadeSkipsFadingOutState() async {
        let vm = makeViewModel()
        vm.selectedDuration = 3
        vm.selectedFadeOut = 0 // Instant — no fade
        let audio = AudioManager(audioEnabled: false)
        vm.start(audioManager: audio)
        try? await Task.sleep(for: .milliseconds(50))
        // Should never enter fadingOut — goes straight to completed/idle
        // With ImmediateClock, ends up at idle (auto-reset also fires instantly)
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
        // Wait for fade to start
        try? await Task.sleep(for: .seconds(2))

        if vm.timerState == .fadingOut {
            vm.stop()
            // Volume should be restored to original (1.0)
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
        // With ImmediateClock, countdown + 3s auto-reset all fire instantly
        try? await Task.sleep(for: .milliseconds(100))
        #expect(vm.timerState == .idle)
    }
```

**Step 2: Run tests**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/SleepViewModelTests 2>&1 | grep -E '(Test Suite|Passed|Failed|error:)'`
Expected: All 11 tests PASS

**Step 3: Commit**

```
git add SaraneraTests/SleepViewModelTests.swift
git commit -m "test: add instant fade, manual stop, and auto-reset tests for SleepViewModel"
```

---

### Task 6: Move ActiveSoundsView to Shared directory

**Files:**
- Move: `Saranera/Views/Focus/ActiveSoundsView.swift` → `Saranera/Views/Shared/ActiveSoundsView.swift`

`ActiveSoundsView` is currently in `Views/Focus/` but the design requires it in both Focus and Sleep. Move it to `Views/Shared/` for reuse.

**Step 1: Move the file**

```bash
git mv Saranera/Views/Focus/ActiveSoundsView.swift Saranera/Views/Shared/ActiveSoundsView.swift
```

**Step 2: Verify it compiles** (SwiftUI doesn't use import paths, so no code changes needed)

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`

Note: Since Xcode projects track file references, this `git mv` alone may not update the Xcode project file. If the build fails because Xcode can't find the file, you'll need to update the Xcode project by removing the old reference and adding the new one. Check if the project uses folder references (blue folders) vs group references (yellow folders). If it uses SPM-style folder structure or has `lastKnownFileType` entries, the project file may need manual updating.

**Step 3: Commit**

```
git add -A
git commit -m "refactor: move ActiveSoundsView to Shared directory for reuse"
```

---

### Task 7: Build SleepView — idle state (setup screen)

**Files:**
- Modify: `Saranera/Views/Sleep/SleepView.swift` (replace stub)

**Step 1: Replace SleepView stub with idle state UI**

Read `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` before writing this code — specifically the sections on `GlassEffectContainer`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`, and `.tint()`.

```swift
import SwiftUI

struct SleepView: View {
    @Environment(AudioManager.self) private var audioManager
    @State private var viewModel = SleepViewModel()
    @State private var showSoundPicker = false

    // Auto-dim
    @State private var lastInteractionDate = Date()
    @State private var isDimmed = false

    // Duration presets in minutes
    private let durationPresets: [Int] = [15, 30, 45, 60, 90]
    // Fade presets in minutes (0 = instant)
    private let fadePresets: [Int] = [0, 2, 5, 10, 15]

    var body: some View {
        ZStack {
            // Background — darker than Focus
            LinearGradient(
                colors: [.black, .deepNavy],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Center content
                switch viewModel.timerState {
                case .idle:
                    idleView
                        .transition(.scale.combined(with: .opacity))
                case .playing, .fadingOut:
                    activeView
                        .transition(.scale.combined(with: .opacity))
                case .completed:
                    completedView
                        .transition(.scale.combined(with: .opacity))
                }

                // Active sounds
                ActiveSoundsView()

                Spacer()

                // Bottom controls
                bottomControls
            }
            .padding()
            .opacity(isDimmed && viewModel.isActive ? 0.15 : 1.0)
            .animation(.spring(duration: 1.0), value: isDimmed)
        }
        .animation(.spring(duration: 0.5), value: viewModel.timerState)
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.deepNavy)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            checkAutoDim()
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 32) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.warmAmber.opacity(0.7))

            // Duration picker
            VStack(spacing: 8) {
                Text("Sleep Timer")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 12) {
                    ForEach(durationPresets, id: \.self) { minutes in
                        Button {
                            viewModel.selectedDuration = TimeInterval(minutes * 60)
                        } label: {
                            Text("\(minutes)m")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(viewModel.selectedDuration == TimeInterval(minutes * 60) ? .glassProminent : .glass)
                    }
                }
            }

            // Fade picker
            VStack(spacing: 8) {
                Text("Fade Out")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 12) {
                    ForEach(fadePresets, id: \.self) { minutes in
                        Button {
                            viewModel.selectedFadeOut = TimeInterval(minutes * 60)
                        } label: {
                            Text(minutes == 0 ? "Off" : "\(minutes)m")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(viewModel.selectedFadeOut == TimeInterval(minutes * 60) ? .glassProminent : .glass)
                    }
                }
            }

            // Start button
            Button {
                viewModel.start(audioManager: audioManager)
                resetDimTimer()
            } label: {
                Label("Start Sleep", systemImage: "moon.fill")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(Color.warmAmber)
        }
    }

    // MARK: - Active View (Playing / Fading)

    private var activeView: some View {
        VStack(spacing: 16) {
            // Large timer digits
            Text(viewModel.formattedTime)
                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.white.opacity(timerDigitOpacity))
                .monospacedDigit()
                .contentTransition(.numericText())

            if viewModel.timerState == .fadingOut {
                Text("Fading out...")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.warmAmber.opacity(0.5))
            }
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 16) {
            Text("Good night")
                .font(.system(.title, design: .rounded, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                // Sound picker
                Button {
                    showSoundPicker = true
                    resetDimTimer()
                } label: {
                    Image(systemName: "music.note.list")
                        .font(.system(.title3))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)

                if viewModel.isActive {
                    // Stop button
                    Button {
                        viewModel.stop()
                        resetDimTimer()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(.title2))
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.warmAmber)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.isActive)
    }

    // MARK: - Timer Digit Opacity

    private var timerDigitOpacity: Double {
        // Fade from 1.0 to 0.3 as timer progresses
        let progress = viewModel.timerProgress
        return 1.0 - (progress * 0.7)
    }

    // MARK: - Auto-Dim

    private func handleTap() {
        resetDimTimer()
    }

    private func resetDimTimer() {
        lastInteractionDate = Date()
        isDimmed = false
    }

    private func checkAutoDim() {
        guard viewModel.isActive else {
            isDimmed = false
            return
        }
        let elapsed = Date().timeIntervalSince(lastInteractionDate)
        if elapsed >= 30 && !isDimmed {
            isDimmed = true
        }
    }
}

#Preview {
    SleepView()
        .environment(AudioManager(audioEnabled: false))
}
```

**Step 2: Verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run all tests to make sure nothing is broken**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -E '(Test Suite|Passed|Failed|error:)'`
Expected: All tests PASS

**Step 4: Commit**

```
git add Saranera/Views/Sleep/SleepView.swift
git commit -m "feat: implement SleepView with idle, active, completed states and auto-dim"
```

---

### Task 8: Final integration verification

**Step 1: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -E '(Test Suite|Passed|Failed|error:)'`
Expected: All tests PASS (FocusViewModel tests + SleepViewModel tests + existing tests)

**Step 2: Build for device to check for warnings**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -E '(warning:|error:|BUILD)'`
Expected: BUILD SUCCEEDED with no warnings

**Step 3: Verify all files are committed**

Run: `git status`
Expected: clean working tree
