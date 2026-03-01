# Phase 2: Focus Mode — Core Features Design

**Date:** 2026-03-02
**Scope:** FocusViewModel, Focus Screen UI, Sound Picker, SwiftData Persistence

## Decisions

- Sound pauses during breaks, resumes when focus resumes
- Free play = sounds play without timer; timer is opt-in via "Start Focus" button
- Timer logic lives inside FocusViewModel (no separate TimerService)
- Enum-driven state machine for timer phases
- Shared SoundPickerView sheet for Focus and Sleep tabs
- SwiftData flat model for FocusSession persistence (no inheritance)

---

## 1. FocusViewModel & State Machine

### State Enum

```swift
enum FocusTimerState: Sendable {
    case idle           // No timer running, sounds can play freely
    case focusing       // Work period active, timer counting down
    case shortBreak     // Short break, sound paused
    case longBreak      // Long break after N sessions, sound paused
    case completed      // All sessions done
}
```

### FocusViewModel (`@Observable`)

**Configuration:**
- `focusDuration: TimeInterval = 25 * 60` (5–120 min range)
- `shortBreakDuration: TimeInterval = 5 * 60` (1–30 min range)
- `longBreakDuration: TimeInterval = 15 * 60` (1–30 min range)
- `sessionsBeforeLongBreak: Int = 4`

**Runtime state:**
- `timerState: FocusTimerState = .idle`
- `timeRemaining: TimeInterval = 0`
- `currentSession: Int = 0` (1-based, which session of the cycle)
- `totalFocusMinutesToday: Int = 0`
- `sessionsCompletedToday: Int = 0`
- `isPaused: Bool = false`

**Computed:**
- `progress: Double` — 0.0→1.0 for ring timer
- `formattedTime: String` — "25:00" format
- `isTimerActive: Bool` — true when focusing or on break

**Methods:**
- `startPomodoro()` — begins first focus session
- `pause()` / `resume()` — pauses/resumes current timer
- `skip()` — skips current break
- `stop()` — resets to idle, saves session if focus time elapsed

**Timer implementation:**
- Internal `Task` stored as `private var timerTask: Task<Void, Never>?`
- Uses `try await Task.sleep(for: .seconds(1))` in a loop
- Cancel via `timerTask?.cancel()`
- Testable via `TimerClock` protocol (production = `ContinuousClock`, tests = instant mock)

**State transitions:**
```
idle → startPomodoro() → focusing
focusing → time=0 → check session count:
  if currentSession % sessionsBeforeLongBreak == 0 → longBreak
  else → shortBreak
shortBreak/longBreak → time=0 → focusing (increment session)
final session complete → completed
```

**Audio integration:**
- `.focusing` start → AudioManager resumes active sounds
- Break start → AudioManager pauses active sounds
- `.completed` / `.stop()` → sounds keep playing (user stops manually)

---

## 2. Focus Screen UI

### Two visual modes

**Idle (free play):**
- Full-screen gradient (deep navy → dark blue)
- Center: large "Start Focus" button (Liquid Glass prominent)
- Sound names shown if playing
- Bottom: sound picker + settings buttons

**Timer active:**
- Center: circular ring timer
  - `Circle` stroke with `trim(from:to:)` animated by progress
  - Ring: soft blue during focus, amber during break
  - Inside: mm:ss in SF Pro Rounded Ultralight ~60pt
  - Below: phase label + session dots
- Below timer: active sound names + volume dots
- Bottom controls in `GlassEffectContainer`:
  - Play/pause (center, `.glassProminent`)
  - Sound picker (left, `.glass`)
  - Stop (right, `.glass`) — during timer
  - Skip break — during break states only

### View hierarchy

```
FocusView
├── ZStack
│   ├── LinearGradient (background)
│   ├── VStack
│   │   ├── TimerRingView / StartButton
│   │   ├── ActiveSoundsView
│   │   └── GlassEffectContainer (controls)
│   └── .sheet(SoundPickerView)
```

### Animations
- Ring progress: `.animation(.linear(duration: 1))` per tick
- State transitions: `.animation(.spring)`
- Phase color changes: spring animation

---

## 3. Sound Picker (Reusable Sheet)

Presented as `.sheet` with detents (`.medium`, `.large`).

**Uses `@Environment(AudioManager.self)`** — no additional bindings needed.

**Layout:**
- NavigationStack with "Sounds" title
- ScrollView with sections per SoundCategory
- Each row: icon, name, lock icon (premium), checkmark (active)
- Active sounds expand to show volume slider
- Tap toggles play/stop via AudioManager
- Max 3 enforced by AudioManager (brief alert on overflow)
- Premium sounds show lock, disabled (purchase flow later)
- Active rows get `.glassEffect()` styling

---

## 4. Persistence (SwiftData)

### FocusSession Model

```swift
@Model
final class FocusSession {
    var id: UUID
    var date: Date
    var focusMinutes: Int
    var sessionsCompleted: Int
    var focusDuration: Int            // configured, in minutes
    var shortBreakDuration: Int       // configured, in minutes
    var longBreakDuration: Int        // configured, in minutes
}
```

Flat model, no inheritance.

### Integration
- `SaraneraApp`: add `.modelContainer(for: FocusSession.self)`
- FocusViewModel saves on stop (if focus time > 0) and on completion
- Stats queries via `FetchDescriptor` filtered by today's date

---

## 5. Testing Strategy

- `TimerClock` protocol for deterministic timer tests
- FocusViewModel tests: state transitions, auto-advance, session counting, stats accumulation
- In-memory `ModelContainer` for SwiftData persistence tests
- Sound picker: integration with AudioManager (existing test patterns)

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `Saranera/Models/FocusSession.swift` | Create — SwiftData model |
| `Saranera/ViewModels/FocusViewModel.swift` | Create — timer + state machine |
| `Saranera/Views/Focus/FocusView.swift` | Rewrite — full focus screen |
| `Saranera/Views/Focus/TimerRingView.swift` | Create — circular progress ring |
| `Saranera/Views/Shared/SoundPickerView.swift` | Create — reusable sound picker sheet |
| `Saranera/Views/Shared/SoundPickerRowView.swift` | Create — sound row with volume slider |
| `Saranera/Views/Focus/ActiveSoundsView.swift` | Create — sound names + volume dots |
| `Saranera/App/SaraneraApp.swift` | Modify — add modelContainer |
| `SaraneraTests/FocusViewModelTests.swift` | Create — timer logic tests |
