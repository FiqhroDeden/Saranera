# Phase 1: Foundation — Design Document

**Date**: 2026-03-01
**Scope**: PRD sections 5.3, 7.1, 8.2
**Status**: Approved

---

## Overview

Phase 1 establishes Serenara's foundation: tab navigation, sound data model, audio playback engine, and a basic library view. No real audio files — test tones serve as placeholders.

## Decisions

- **DI Pattern**: AudioManager as singleton (`AudioManager.shared`), injected via `.environment()`
- **Architecture**: Monolithic AudioManager (single `@Observable` class owns AVAudioEngine + state). Refactor to layered when Phase 2 demands it.
- **UI Framework**: SwiftUI with Liquid Glass (iOS 26 native tab bar styling)
- **Concurrency**: Default MainActor isolation per Swift 6.2 / project settings

---

## 1. Tab Navigation

Replace boilerplate with root `TabView` containing 3 tabs:

| Tab | SF Symbol | View | Status |
|-----|-----------|------|--------|
| Focus | `brain.head.profile` | `FocusView` | Placeholder |
| Sleep | `moon.stars` | `SleepView` | Placeholder |
| Library | `square.grid.2x2` | `LibraryView` | Implemented |

`SaraneraApp` creates and injects `AudioManager.shared` via `.environment()`. Standard iOS 26 `TabView` gets Liquid Glass automatically.

Placeholder views show the tab name centered, styled with Deep Navy background and Soft Blue text.

**Files**:
- Modify `Saranera/SaraneraApp.swift`
- Modify `Saranera/ContentView.swift`
- Create `Saranera/Views/Focus/FocusView.swift`
- Create `Saranera/Views/Sleep/SleepView.swift`

## 2. Sound Model

### SoundCategory (`Saranera/Models/SoundCategory.swift`)

```
enum SoundCategory: String, CaseIterable, Codable
    cases: nature, ambient, environment, urban
    computed: displayName, iconName
```

### Sound (`Saranera/Models/Sound.swift`)

```
struct Sound: Identifiable, Hashable, Codable
    id: String, name: String, category: SoundCategory
    fileName: String, isPremium: Bool, iconName: String (SF Symbol)
    static catalog: [Sound] — 12 free sounds from PRD 5.3
```

Catalog:

| Sound | Category | SF Symbol |
|-------|----------|-----------|
| Rain | nature | cloud.rain |
| Thunder | nature | cloud.bolt |
| Forest | nature | tree |
| Ocean Waves | nature | water.waves |
| White Noise | ambient | waveform |
| Brown Noise | ambient | waveform.path |
| Pink Noise | ambient | waveform.badge.magnifyingglass |
| Fireplace | environment | flame |
| Wind | environment | wind |
| Night Crickets | environment | moon.stars |
| Coffee Shop | urban | cup.and.saucer |
| Library Ambience | urban | books.vertical |

### SoundMix (`Saranera/Models/SoundMix.swift`)

```
struct SoundMix: Identifiable, Codable
    id: UUID, name: String, components: [MixComponent], isFavorite: Bool

struct MixComponent: Codable, Hashable
    soundID: String, volume: Float (0.0...1.0)
```

## 3. AudioManager

**File**: `Saranera/ViewModels/AudioManager.swift`

Single `@Observable` class, singleton pattern (`AudioManager.shared`).

### State
- `activeSounds: [String: ActiveSound]` — sound ID -> player state
- `isPlaying: Bool` — computed from activeSounds
- `maxSimultaneous: Int = 3`

### ActiveSound (inner struct)
Holds `AVAudioPlayerNode`, current `volume: Float`, `AVAudioPCMBuffer` reference.

### Engine Setup (on init)
1. Create `AVAudioEngine`
2. Configure `AVAudioSession` for `.playback` with `.mixWithOthers`
3. Observe `interruptionNotification`
4. Engine starts lazily on first play

### Public API
- `play(sound:)` — Toggle behavior. Reject if at max capacity (3). Creates node, attaches, connects to mixer, generates test-tone buffer, schedules with `.loops`.
- `stop(sound:)` — Stops node, detaches, removes from state.
- `stopAll()` — Stops all.
- `setVolume(for:to:)` — Sets node volume, updates state.
- `isActive(_:) -> Bool` — Quick check.

### Test Tone Generation
Private `generateTestToneBuffer(frequency:duration:) -> AVAudioPCMBuffer` creates a sine wave at the engine's output format. Each sound gets a different frequency (220-880Hz) for distinguishability.

### Interruption Handling
- `.began`: pause engine
- `.ended` with `.shouldResume`: restart engine, re-schedule buffers

## 4. Library View

**File**: `Saranera/Views/Library/LibraryView.swift`

`List` with sections grouped by `SoundCategory`. Each section has the category display name as header.

### Sound Row (`Saranera/Views/Library/SoundRowView.swift`)
- SF Symbol icon
- Sound name
- Play state indicator (active/inactive visual)

### Interaction
Tap row to toggle play/stop. If at max capacity, play is silently rejected.

### Styling
Dark background (Deep Navy), Liquid Glass on section headers, SF Pro Rounded typography.

## 5. Testing

**File**: `SaraneraTests/AudioManagerTests.swift`

| Test | Verifies |
|------|----------|
| `testPlaySound` | Sound added to activeSounds, isPlaying is true |
| `testStopSound` | Sound removed from activeSounds |
| `testTogglePlay` | Playing active sound stops it |
| `testMaxSimultaneous` | 4th sound rejected, only 3 active |
| `testStopAll` | All sounds cleared |
| `testSetVolume` | Volume state updated |
| `testIsActive` | Correct active/inactive reporting |

Tests use real AVAudioEngine (integration-style). Gracefully handle engine start failures for CI.

---

## File Summary

| Action | Path |
|--------|------|
| Modify | `Saranera/SaraneraApp.swift` |
| Modify | `Saranera/ContentView.swift` |
| Create | `Saranera/Models/Sound.swift` |
| Create | `Saranera/Models/SoundCategory.swift` |
| Create | `Saranera/Models/SoundMix.swift` |
| Create | `Saranera/ViewModels/AudioManager.swift` |
| Create | `Saranera/Views/Focus/FocusView.swift` |
| Create | `Saranera/Views/Sleep/SleepView.swift` |
| Create | `Saranera/Views/Library/LibraryView.swift` |
| Create | `Saranera/Views/Library/SoundRowView.swift` |
| Create | `SaraneraTests/AudioManagerTests.swift` |
