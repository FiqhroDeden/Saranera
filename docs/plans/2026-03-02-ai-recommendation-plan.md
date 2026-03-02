# AI Sound Recommendation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add on-device AI sound recommendation using Apple Foundation Models — users describe their mood and get a personalized soundscape suggestion.

**Architecture:** `@Observable` RecommendationManager owns all AI state (availability, streaming, results). Shared `RecommendationView` component embeds in both Focus and Sleep idle screens. `@Generable` structs for guided generation. Each tab gets its own manager instance.

**Tech Stack:** FoundationModels framework, `@Generable` macro, `LanguageModelSession`, `streamResponse`, Swift Testing

**Docs to read before coding:**
- `AdditionalDocumentation/FoundationModels-Using-on-device-LLM-in-your-app.md`
- `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md`
- `docs/plans/2026-03-02-ai-recommendation-design.md`

---

### Task 1: Create SoundRecommendation Model

**Files:**
- Create: `Saranera/Models/SoundRecommendation.swift`

**Step 1: Create the @Generable structs**

```swift
import Foundation
import FoundationModels

@Generable(description: "A single sound suggestion within a recommendation")
struct SoundSuggestion {
    @Guide(description: "The sound identifier from the catalog, e.g. 'rain', 'coffeeShop', 'ocean_waves'")
    var soundId: String

    @Guide(description: "Volume level for this sound", .range(0...100))
    var volume: Int
}

@Generable(description: "A personalized soundscape recommendation based on user's mood")
struct SoundRecommendation {
    @Guide(description: "Suggested sounds to play", .count(1...3))
    var sounds: [SoundSuggestion]

    @Guide(description: "Suggested timer duration in minutes", .range(5...120))
    var timerMinutes: Int

    @Guide(description: "Fade-out duration in minutes for sleep mode, 0 for focus mode", .range(0...15))
    var fadeOutMinutes: Int

    @Guide(description: "Brief explanation of why this soundscape was chosen for the user's mood")
    var reasoning: String
}
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -20`
Expected: BUILD SUCCEEDED (or warnings only — `@Generable` macro expansion generates PartiallyGenerated types automatically)

**Step 3: Commit**

```bash
git add Saranera/Models/SoundRecommendation.swift
git commit -m "feat: add SoundRecommendation @Generable model for AI recommendations"
```

---

### Task 2: Create RecommendationManager — Enums, State, and Availability

**Files:**
- Create: `Saranera/ViewModels/RecommendationManager.swift`
- Create: `SaraneraTests/RecommendationManagerTests.swift`

**Step 1: Write the failing tests for availability and initial state**

File: `SaraneraTests/RecommendationManagerTests.swift`

```swift
import Foundation
import Testing
@testable import Saranera

@MainActor
struct RecommendationManagerTests {

    // MARK: - Initial State

    @Test func initialStateIsIdle() {
        let manager = RecommendationManager()
        #expect(manager.state == .idle)
        #expect(manager.result == nil)
        #expect(manager.partialResult == nil)
        #expect(manager.errorMessage == nil)
    }

    // MARK: - Instruction Building

    @Test func buildInstructionsContainsSoundCatalog() {
        let manager = RecommendationManager()
        let sounds = [
            Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
            Sound(id: "fire", name: "Fireplace", category: .environment, fileName: "fire.m4a", isPremium: false, iconName: "flame"),
        ]
        let instructions = manager.buildInstructions(mode: .focus, availableSounds: sounds)

        #expect(instructions.contains("rain"))
        #expect(instructions.contains("Rain"))
        #expect(instructions.contains("fire"))
        #expect(instructions.contains("Fireplace"))
        #expect(instructions.contains("focus"))
    }

    @Test func buildInstructionsContainsMode() {
        let manager = RecommendationManager()
        let sounds = [Sound.catalog[0]]

        let focusInstructions = manager.buildInstructions(mode: .focus, availableSounds: sounds)
        #expect(focusInstructions.contains("focus"))

        let sleepInstructions = manager.buildInstructions(mode: .sleep, availableSounds: sounds)
        #expect(sleepInstructions.contains("sleep"))
    }

    @Test func buildInstructionsExcludesUnavailableSounds() {
        let manager = RecommendationManager()
        let sounds = [
            Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
        ]
        let instructions = manager.buildInstructions(mode: .focus, availableSounds: sounds)

        // Should contain "rain" but NOT "thunder" (not in available list)
        #expect(instructions.contains("rain"))
        // The word "thunder" should not appear as an available sound ID
        #expect(!instructions.contains("\"thunder\""))
    }

    // MARK: - Reset

    @Test func resetClearsState() {
        let manager = RecommendationManager()
        // Manually set some state to verify reset clears it
        manager.errorMessage = "test error"
        manager.state = .error

        manager.reset()

        #expect(manager.state == .idle)
        #expect(manager.result == nil)
        #expect(manager.partialResult == nil)
        #expect(manager.errorMessage == nil)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/RecommendationManagerTests -quiet 2>&1 | tail -20`
Expected: FAIL — `RecommendationManager` not found

**Step 3: Implement RecommendationManager skeleton**

File: `Saranera/ViewModels/RecommendationManager.swift`

```swift
import Foundation
import FoundationModels
import Observation

enum ModelAvailability: Sendable, Equatable {
    case available
    case notEnabled
    case notEligible
    case notReady
}

enum RecommendationState: Sendable, Equatable {
    case idle
    case loading
    case streaming
    case completed
    case error
}

enum RecommendationMode: Sendable {
    case focus
    case sleep
}

@Observable
final class RecommendationManager {

    // MARK: - Public State

    private(set) var availability: ModelAvailability = .notEligible
    private(set) var state: RecommendationState = .idle
    var partialResult: SoundRecommendation.PartiallyGenerated?
    var result: SoundRecommendation?
    var errorMessage: String?

    // MARK: - Private

    private var currentTask: Task<Void, Never>?

    // MARK: - Availability

    func checkAvailability() {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            availability = .available
        case .unavailable(.appleIntelligenceNotEnabled):
            availability = .notEnabled
        case .unavailable(.deviceNotEligible):
            availability = .notEligible
        case .unavailable(.modelNotReady):
            availability = .notReady
        case .unavailable:
            availability = .notEligible
        }
    }

    // MARK: - Instructions

    func buildInstructions(mode: RecommendationMode, availableSounds: [Sound]) -> String {
        let modeString = mode == .focus ? "focus" : "sleep"
        let soundList = availableSounds
            .map { "- \"\($0.id)\": \($0.name) (\($0.category.displayName))" }
            .joined(separator: "\n")

        return """
            You are Serenara's sound recommendation assistant. The user is in \(modeString) mode.

            AVAILABLE SOUNDS (only suggest from this list):
            \(soundList)

            RULES:
            - Only use soundId values from the available sounds list above.
            - Suggest 1 to 3 sounds that complement each other.
            - Set volume (0-100) for each sound. Primary sounds should be 50-80, secondary/accent sounds 20-50.
            - For focus mode: suggest timer durations of 25, 50, or longer for deep work. Set fadeOutMinutes to 0.
            - For sleep mode: suggest timer durations of 30-90 minutes. Set fadeOutMinutes between 2-15.
            - Match the soundscape to the user's described mood, activity, or atmosphere.
            - Nature sounds (rain, ocean, forest) are calming and good for both focus and sleep.
            - Noise sounds (white, brown, pink) are excellent for masking distractions during focus.
            - Brown noise is especially good for deep concentration.
            - Environment sounds (fireplace, wind, crickets) add warmth and atmosphere.
            - Urban sounds (coffee shop, library) create a productive ambience for focus.
            - Keep reasoning brief (1-2 sentences).
            """
    }

    // MARK: - Recommend

    func recommend(mood: String, mode: RecommendationMode, availableSounds: [Sound]) async {
        currentTask?.cancel()
        state = .loading
        result = nil
        partialResult = nil
        errorMessage = nil

        let instructions = buildInstructions(mode: mode, availableSounds: availableSounds)

        do {
            let session = LanguageModelSession(instructions: instructions)
            let stream = session.streamResponse(
                to: "The user says: \(mood)",
                generating: SoundRecommendation.self
            )

            state = .streaming

            for try await partial in stream {
                partialResult = partial
            }

            // Stream completed — extract final result
            if let partial = partialResult,
               let sounds = partial.sounds,
               let timerMinutes = partial.timerMinutes,
               let fadeOutMinutes = partial.fadeOutMinutes,
               let reasoning = partial.reasoning {
                // Validate all sound IDs exist in available sounds
                let validSoundIds = Set(availableSounds.map(\.id))
                let validSuggestions = sounds.compactMap { suggestion -> SoundSuggestion? in
                    guard let soundId = suggestion.soundId,
                          let volume = suggestion.volume,
                          validSoundIds.contains(soundId) else { return nil }
                    return SoundSuggestion(soundId: soundId, volume: volume)
                }

                guard !validSuggestions.isEmpty else {
                    state = .error
                    errorMessage = "No valid sounds in recommendation"
                    return
                }

                result = SoundRecommendation(
                    sounds: validSuggestions,
                    timerMinutes: timerMinutes,
                    fadeOutMinutes: fadeOutMinutes,
                    reasoning: reasoning
                )
                state = .completed
            } else {
                state = .error
                errorMessage = "Incomplete recommendation received"
            }
        } catch let error as LanguageModelSession.GenerationError {
            state = .error
            switch error {
            case .exceededContextWindowSize:
                errorMessage = "Too many sounds to process"
            case .guardrailViolation:
                errorMessage = "Could not generate a recommendation"
            default:
                errorMessage = "Something went wrong"
            }
        } catch is CancellationError {
            // Task was cancelled — don't update state
            return
        } catch {
            state = .error
            errorMessage = "Something went wrong"
        }
    }

    // MARK: - Reset

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
        result = nil
        partialResult = nil
        errorMessage = nil
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SaraneraTests/RecommendationManagerTests -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Saranera/ViewModels/RecommendationManager.swift SaraneraTests/RecommendationManagerTests.swift
git commit -m "feat: add RecommendationManager with availability, instructions, and streaming"
```

---

### Task 3: Create RecommendationView

**Files:**
- Create: `Saranera/Views/Shared/RecommendationView.swift`

**Step 1: Create the shared RecommendationView component**

File: `Saranera/Views/Shared/RecommendationView.swift`

Read `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` for Liquid Glass patterns.

```swift
import SwiftUI

struct RecommendationView: View {
    var manager: RecommendationManager
    let mode: RecommendationMode
    let availableSounds: [Sound]
    let onApply: (SoundRecommendation) -> Void

    @State private var moodText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        switch manager.availability {
        case .notEligible:
            EmptyView()
        case .notEnabled:
            notEnabledView
        case .notReady:
            notReadyView
        case .available:
            availableView
        }
    }

    // MARK: - Not Enabled

    private var notEnabledView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.3))
            Text("Enable Apple Intelligence in Settings for smart recommendations")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal)
    }

    // MARK: - Not Ready

    private var notReadyView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.3))
            TextField("AI is getting ready...", text: .constant(""))
                .font(.system(.subheadline, design: .rounded))
                .disabled(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    // MARK: - Available

    @ViewBuilder
    private var availableView: some View {
        VStack(spacing: 12) {
            switch manager.state {
            case .idle:
                moodInputView
            case .loading:
                loadingView
            case .streaming:
                streamingView
            case .completed:
                completedView
            case .error:
                errorView
            }
        }
    }

    // MARK: - Mood Input

    private var moodInputView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.softBlue)

            TextField("Describe your mood...", text: $moodText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white)
                .focused($isTextFieldFocused)
                .onSubmit { submitMood() }

            if !moodText.isEmpty {
                Button {
                    submitMood()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(.title3))
                        .foregroundStyle(Color.softBlue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("Thinking...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    // MARK: - Streaming

    private var streamingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show partial sounds as they arrive
            if let partial = manager.partialResult, let sounds = partial.sounds {
                ForEach(Array(sounds.enumerated()), id: \.offset) { _, suggestion in
                    if let soundId = suggestion.soundId,
                       let sound = Sound.catalog.first(where: { $0.id == soundId }) {
                        HStack {
                            Image(systemName: sound.iconName)
                                .foregroundStyle(Color.softBlue)
                            Text(sound.name)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            if let volume = suggestion.volume {
                                Text("\(volume)%")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }

            if let partial = manager.partialResult, let reasoning = partial.reasoning {
                Text(reasoning)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            ProgressView()
                .tint(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let recommendation = manager.result {
                // Sound list
                ForEach(Array(recommendation.sounds.enumerated()), id: \.offset) { _, suggestion in
                    if let sound = Sound.catalog.first(where: { $0.id == suggestion.soundId }) {
                        HStack {
                            Image(systemName: sound.iconName)
                                .foregroundStyle(Color.softBlue)
                            Text(sound.name)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(suggestion.volume)%")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                // Timer info
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(recommendation.timerMinutes) min")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    if mode == .sleep && recommendation.fadeOutMinutes > 0 {
                        Text("· \(recommendation.fadeOutMinutes) min fade")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Reasoning
                Text(recommendation.reasoning)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        onApply(recommendation)
                        manager.reset()
                        moodText = ""
                    } label: {
                        Label("Apply", systemImage: "checkmark")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glassProminent)

                    Button {
                        manager.reset()
                        moodText = ""
                    } label: {
                        Text("Dismiss")
                            .font(.system(.subheadline, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 8) {
            Text(manager.errorMessage ?? "Something went wrong")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Button {
                manager.reset()
            } label: {
                Text("Try again")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Actions

    private func submitMood() {
        guard !moodText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isTextFieldFocused = false
        Task {
            await manager.recommend(
                mood: moodText,
                mode: mode,
                availableSounds: availableSounds
            )
        }
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/Views/Shared/RecommendationView.swift
git commit -m "feat: add RecommendationView with mood input, streaming, and result display"
```

---

### Task 4: Integrate into FocusView

**Files:**
- Modify: `Saranera/Views/Focus/FocusView.swift`

**Step 1: Add RecommendationManager state and RecommendationView to idle state**

In `FocusView.swift`, add a `@State` property for the manager (after line 8):

```swift
@State private var recommendationManager = RecommendationManager()
```

In the `idleView` computed property (currently lines 69-90), insert `RecommendationView` between the brain icon and the Start button. Replace the `idleView` property with:

```swift
private var idleView: some View {
    VStack(spacing: 24) {
        Image(systemName: "brain.head.profile")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(Color.softBlue)

        RecommendationView(
            manager: recommendationManager,
            mode: .focus,
            availableSounds: Sound.catalog.filter { !$0.isPremium },
            onApply: { recommendation in
                applyRecommendation(recommendation)
            }
        )

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
```

Add an `applyRecommendation` method and an `onAppear` call for availability checking. Add this method to FocusView:

```swift
private func applyRecommendation(_ recommendation: SoundRecommendation) {
    audioManager.stopAll()
    for suggestion in recommendation.sounds {
        if let sound = Sound.catalog.first(where: { $0.id == suggestion.soundId }) {
            audioManager.play(sound: sound)
            audioManager.setVolume(for: sound, to: Float(suggestion.volume) / 100.0)
        }
    }
    viewModel.focusDuration = TimeInterval(recommendation.timerMinutes * 60)
}
```

Add `.onAppear { recommendationManager.checkAvailability() }` to the body's outermost modifier chain (after the existing `.onAppear`).

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

**Step 3: Run all tests to verify nothing broke**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add Saranera/Views/Focus/FocusView.swift
git commit -m "feat: integrate AI recommendation into FocusView idle state"
```

---

### Task 5: Integrate into SleepView

**Files:**
- Modify: `Saranera/Views/Sleep/SleepView.swift`

**Step 1: Add RecommendationManager state and RecommendationView to idle state**

In `SleepView.swift`, add a `@State` property for the manager (after line 7):

```swift
@State private var recommendationManager = RecommendationManager()
```

In the `idleView` computed property (currently lines 72-95), insert `RecommendationView` between the moon icon and the duration picker. Replace the `idleView` property with:

```swift
private var idleView: some View {
    VStack(spacing: 32) {
        Image(systemName: "moon.stars")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(Color.warmAmber.opacity(0.7))

        RecommendationView(
            manager: recommendationManager,
            mode: .sleep,
            availableSounds: Sound.catalog.filter { !$0.isPremium },
            onApply: { recommendation in
                applySleepRecommendation(recommendation)
            }
        )

        durationPicker

        fadePicker

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
```

Add the apply method:

```swift
private func applySleepRecommendation(_ recommendation: SoundRecommendation) {
    audioManager.stopAll()
    for suggestion in recommendation.sounds {
        if let sound = Sound.catalog.first(where: { $0.id == suggestion.soundId }) {
            audioManager.play(sound: sound)
            audioManager.setVolume(for: sound, to: Float(suggestion.volume) / 100.0)
        }
    }
    viewModel.selectedDuration = TimeInterval(recommendation.timerMinutes * 60)
    viewModel.selectedFadeOut = TimeInterval(recommendation.fadeOutMinutes * 60)
}
```

Add `.onAppear { recommendationManager.checkAvailability() }` to the body's modifier chain, after the `.animation` modifier on line 56.

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

**Step 3: Run all tests**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -20`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add Saranera/Views/Sleep/SleepView.swift
git commit -m "feat: integrate AI recommendation into SleepView idle state"
```

---

### Task 6: Final Verification

**Step 1: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -30`
Expected: All tests PASS

**Step 2: Build for device to verify FoundationModels links correctly**

Run: `xcodebuild build -scheme Saranera -destination 'generic/platform=iOS' -quiet 2>&1 | tail -20`
Expected: BUILD SUCCEEDED (this confirms FoundationModels framework resolves for real devices)

**Step 3: Review all changes since the design doc commit**

Run: `git log --oneline f902bd6..HEAD` to see all commits in this feature.
Run: `git diff f902bd6..HEAD --stat` to see files changed.

Verify the following files were created/modified:
- Created: `Saranera/Models/SoundRecommendation.swift`
- Created: `Saranera/ViewModels/RecommendationManager.swift`
- Created: `SaraneraTests/RecommendationManagerTests.swift`
- Created: `Saranera/Views/Shared/RecommendationView.swift`
- Modified: `Saranera/Views/Focus/FocusView.swift`
- Modified: `Saranera/Views/Sleep/SleepView.swift`
