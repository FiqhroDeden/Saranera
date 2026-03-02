# Phase 2: Sleep Mode — Design Document

## Overview

Sleep Mode provides a linear countdown timer with gradual audio fade-out for falling asleep. It reuses the existing AudioManager and sound picker infrastructure from Focus Mode.

## Architecture

**Approach:** Standalone SleepViewModel with internal fade logic (Approach A). All timer and fade-out logic lives in `SleepViewModel`. No changes to AudioManager.

## State Machine

```
SleepTimerState: Sendable, Equatable
├── idle          — setup screen, user picks duration + fade
├── playing       — countdown active, audio playing
├── fadingOut     — within fade-out window, volumes decreasing
├── completed     — "Good night" shown, auto-resets after 3s
```

### Transitions

- `idle` → `playing`: user taps Start (audio begins, countdown starts)
- `playing` → `fadingOut`: `timeRemaining <= fadeOutDuration`
- `fadingOut` → `completed`: `timeRemaining == 0` (audio stopped)
- `completed` → `idle`: auto after 3 seconds
- Any active state → `idle`: user taps Stop

## Data Model

| Property | Type | Purpose |
|----------|------|---------|
| `selectedDuration` | `TimeInterval` | Timer length (default 30m) |
| `selectedFadeOut` | `TimeInterval` | Fade duration (default 5m) |
| `timerState` | `SleepTimerState` | Current state (private set) |
| `timeRemaining` | `TimeInterval` | Countdown seconds left (private set) |

**Duration presets:** 15, 30, 45, 60, 90 minutes.
**Fade presets:** Instant (0), 2, 5, 10, 15 minutes.

## Fade-Out Logic

Proportional linear fade preserving mix balance:

1. State transitions to `.fadingOut` when `timeRemaining <= fadeOutDuration`
2. Each tick calculates: `fadeProgress = timeRemaining / fadeOutDuration` (1.0 → 0.0)
3. Store each sound's "original volume" at fade start
4. Per tick: `audioManager.setVolume(for: sound, to: originalVolume * fadeProgress)`
5. At `timeRemaining == 0`: `audioManager.stopAll()`, transition to `.completed`

### Edge Cases

- **Instant fade (0 min):** Skip `.fadingOut`, go `playing` → `completed` with immediate `stopAll()`
- **Manual stop during fade:** Restore original volumes before stopping
- **Fade duration > timer duration:** Fade starts immediately from `playing`

## Sleep Screen UI

### Layout (ZStack)

```
1. Background: LinearGradient(.black → .deepNavy)
2. Content VStack (auto-dim opacity applied):
   ├── Spacer
   ├── Timer digits: SF Pro Rounded Ultralight, large
   │   └── Opacity: 1.0 → 0.3 as timer progresses
   ├── ActiveSoundsView (reused)
   ├── Spacer
   └── Bottom controls in GlassEffectContainer:
       ├── Stop button (glass, subtle amber tint)
       └── Sound picker button (glass)
3. "Good night" overlay (.completed state only)
```

### Idle State (Setup)

- Horizontal chip pickers for duration and fade-out presets
- Start button (glass prominent, amber tint)
- Sound picker button

### Auto-Dim

- Track last interaction time
- After 30s no taps: animate content opacity to 0.15 (spring, 1s)
- Any tap restores opacity to 1.0
- Timer digits remain faintly visible when dimmed

### Visual Treatment

- Near-black background (darker than Focus)
- Warm amber (#F4A261) accents only on start/stop button and active sound indicators
- All other elements: muted navy/gray
- Liquid Glass materials with extra translucency

## Testing Plan

SleepViewModel unit tests (7 cases):

1. Timer countdown — `timeRemaining` decrements, reaches 0
2. State transitions — idle→playing→fadingOut→completed→idle
3. Fade volume calculation — 50% progress = 50% original volume
4. Instant fade — skips fadingOut, direct to completed
5. Manual stop during fade — restores original volumes, returns to idle
6. Manual stop during playing — returns to idle, stops audio
7. Auto-reset — completed transitions to idle after 3s

## Files

| Action | File |
|--------|------|
| Create | `Saranera/ViewModels/SleepViewModel.swift` |
| Create | `SaraneraTests/SleepViewModelTests.swift` |
| Modify | `Saranera/Views/Sleep/SleepView.swift` (replace stub) |

## Wiring

- `SleepView` gets `AudioManager` via `@Environment`
- Reuses `SoundPickerView` (modal sheet) and `ActiveSoundsView`
- `SleepViewModel` instantiated as `@State` in `SleepView`
- Sleep tab already exists in `TabView` — stub replacement only
