# AI Sound Recommendation — Design

## Overview

On-device AI feature powered by Apple Foundation Models. Users describe their mood in natural language and receive a personalized soundscape recommendation. All processing is local — no cloud, no data leaves the device.

## Decisions

- Recommendations stay within the current tab's mode (Focus tab → focus recommendation, Sleep tab → sleep recommendation)
- Mood input appears only in the idle state (before timer starts)
- "Apply" configures sounds + timer settings but does not auto-start the session
- Architecture: `@Observable` RecommendationManager + shared RecommendationView component

## Data Model

File: `Saranera/Models/SoundRecommendation.swift`

Two `@Generable` structs for guided generation:

```swift
@Generable(description: "A single sound suggestion within a recommendation")
struct SoundSuggestion {
    @Guide(description: "The sound identifier from the catalog, e.g. 'rain', 'coffeeShop'")
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

    @Guide(description: "Fade-out duration in minutes for sleep mode", .range(0...15))
    var fadeOutMinutes: Int

    @Guide(description: "Brief explanation of why this mix was chosen")
    var reasoning: String
}
```

No `mode` field — the mode is implicit from the current tab. `fadeOutMinutes` is present but ignored by Focus mode.

## RecommendationManager

File: `Saranera/ViewModels/RecommendationManager.swift`

```swift
@Observable
final class RecommendationManager {
    // Public state
    var availability: ModelAvailability    // .available, .notEnabled, .notEligible, .notReady
    var state: RecommendationState         // .idle, .loading, .streaming, .completed, .error
    var partialResult: SoundRecommendation.PartiallyGenerated?
    var result: SoundRecommendation?
    var errorMessage: String?

    // Methods
    func checkAvailability()
    func recommend(mood: String, mode: Mode, availableSounds: [Sound]) async
    func reset()
}
```

### Enums

```swift
enum ModelAvailability { case available, notEnabled, notEligible, notReady }
enum Mode { case focus, sleep }
enum RecommendationState { case idle, loading, streaming, completed, error }
```

### Session Instructions

Built dynamically per request, containing:
- Sound catalog (names + IDs of sounds user has access to)
- Current mode ("focus" or "sleep")
- Mood-to-sound mapping guidance
- Output constraints (only suggest sounds from the provided list, valid volumes)

### Streaming Flow

1. Create new `LanguageModelSession(instructions:)` per request (single-turn)
2. Call `session.streamResponse(to: prompt, generating: SoundRecommendation.self)`
3. Iterate async sequence → update `partialResult` on each snapshot
4. On completion → set `result` and `state = .completed`

### Error Handling

- `exceededContextWindowSize` → "Too many sounds to process"
- `guardrailViolation` → "Could not generate recommendation"
- Generic errors → user-friendly message in `errorMessage`

## RecommendationView

File: `Saranera/Views/Shared/RecommendationView.swift`

Reusable component embedded in both Focus and Sleep idle states.

```swift
struct RecommendationView: View {
    var manager: RecommendationManager
    let mode: RecommendationManager.Mode
    let availableSounds: [Sound]
    let onApply: (SoundRecommendation) -> Void
}
```

### UI States

| Manager State | UI |
|---|---|
| `availability == .notEligible` | Hidden (`EmptyView`) |
| `availability == .notEnabled` | Subtle text: "Enable Apple Intelligence in Settings for smart recommendations" |
| `availability == .notReady` | Disabled input with "AI is getting ready..." placeholder |
| `availability == .available` + `state == .idle` | Text field with sparkle icon + Submit button |
| `state == .loading` | Pulsing indicator, "Thinking..." |
| `state == .streaming` | Progressive card showing partial results |
| `state == .completed` | Full recommendation card with "Apply" button |
| `state == .error` | Error message with "Try again" button |

### Design

- Liquid Glass material for recommendation card
- SF Symbol `sparkles` for input field
- Spring animations for transitions
- Compact layout — sits above the start button, doesn't dominate idle screen

## Integration

### FocusView (idle state)

```swift
RecommendationView(
    manager: recommendationManager,
    mode: .focus,
    availableSounds: Sound.catalog.filter { !$0.isPremium },
    onApply: { recommendation in
        audioManager.stopAll()
        for sound in recommendation.sounds {
            if let s = Sound.catalog.first(where: { $0.id == sound.soundId }) {
                audioManager.play(sound: s)
                audioManager.setVolume(for: s.id, to: Float(sound.volume) / 100.0)
            }
        }
        viewModel.focusDuration = recommendation.timerMinutes * 60
    }
)
```

### SleepView (idle state)

Same sound setup, plus:
```swift
viewModel.selectedDuration = recommendation.timerMinutes * 60
viewModel.selectedFadeOut = recommendation.fadeOutMinutes * 60
```

### Ownership

Each tab creates its own `@State private var recommendationManager = RecommendationManager()`. Not shared between tabs — avoids state leaking.

## Testing

File: `SaraneraTests/RecommendationManagerTests.swift`

Test the logic around the LLM call (not the call itself):
- `testCheckAvailability` — all 4 availability states map correctly
- `testBuildInstructions` — instruction string contains sound catalog and mode
- `testRecommendAppliesValidSounds` — verify only valid sound IDs accepted
- `testResetClearsState` — verify reset returns to idle
- `testErrorHandling` — verify error states are surfaced
- State transition tests: idle → loading → streaming → completed
