# Claude Code Prompts — Serenara Project

## Prompt 1: Project Setup & CLAUDE.md

```
Read the full PRD at docs/PRD.md — this is our complete product specification for Serenara.

Then create a CLAUDE.md file in the project root. This file will be your persistent memory for all future tasks.

### CLAUDE.md must include:

**1. Project Overview**
Serenara — an immersive sound & focus iOS app with two modes (Focus with Pomodoro, Sleep with timer/fade-out), sound mixing (up to 3 sounds), on-device AI recommendations, and one-time purchase sound packs. Full spec in docs/PRD.md.

**2. Architecture**
- Pattern: MVVM + Repository
- Language: Swift 6 with strict concurrency
- UI: SwiftUI only, no UIKit — iOS 26 minimum deployment target
- Design: Liquid Glass design language (Apple's latest design system for iOS 26)
- State: @Observable (NOT ObservableObject), @State, @Environment
- DI: Environment injection via .environment()

**3. Documentation Reference Map**
This is critical. Include this exact mapping so you know which Apple doc to read for each task:

| Task / Feature | Read First |
|---|---|
| Any UI work | @AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md |
| Foundation Models / AI | @AdditionalDocumentation/FoundationModels-Using-on-device-LLM-in-your-app.md |
| StoreKit / IAP | @AdditionalDocumentation/StoreKit-Updates.md |
| SwiftData / Persistence | @AdditionalDocumentation/SwiftData-Class-Inheritance.md |
| Concurrency / Async | @AdditionalDocumentation/Swift-Concurrency-Updates.md |
| Toolbar / Navigation | @AdditionalDocumentation/SwiftUI-New-Toolbar-Features.md |
| Styled Text | @AdditionalDocumentation/SwiftUI-Styled-Text-Editing.md |
| Charts / Stats UI | @AdditionalDocumentation/Swift-Charts-3D-Visualization.md |
| AlarmKit / Sleep alarm | @AdditionalDocumentation/SwiftUI-AlarmKit-Integration.md |
| App Intents / Siri | @AdditionalDocumentation/AppIntents-Updates.md |
| Widgets | @AdditionalDocumentation/WidgetKit-Implementing-Liquid-Glass-Design.md |
| Accessibility | @AdditionalDocumentation/Implementing-Assistive-Access-in-iOS.md |
| Visual Intelligence | @AdditionalDocumentation/Implementing-Visual-Intelligence-in-iOS.md |
| MapKit | @AdditionalDocumentation/MapKit-GeoToolbox-PlaceDescriptors.md |
| AttributedString | @AdditionalDocumentation/Foundation-AttributedString-Updates.md |
| InlineArray / Span | @AdditionalDocumentation/Swift-InlineArray-Span.md |
| WebKit integration | @AdditionalDocumentation/SwiftUI-WebKit-Integration.md |
| AppKit Liquid Glass | @AdditionalDocumentation/AppKit-Implementing-Liquid-Glass-Design.md |
| UIKit Liquid Glass | @AdditionalDocumentation/UIKit-Implementing-Liquid-Glass-Design.md |

RULE: Before starting ANY task, check this map. If a relevant doc exists, read it FIRST before writing code. Always use the latest APIs and patterns from these docs.

**4. Design System Tokens**
- Primary: Deep Navy #0D1B2A
- Accent: Soft Blue #5B9BD5
- Warm: Amber #F4A261
- Typography: SF Pro Rounded (system)
- Timer digits: Light/Ultralight weight
- Body: Regular weight
- Icons: SF Symbols, rounded & filled style
- All UI: Liquid Glass materials and effects
- Dark mode primary, minimal chrome, generous whitespace

**5. File Structure**
```

Saranera/
├── App/
│ └── SaraneraApp.swift
├── Models/
│ ├── Sound.swift
│ ├── SoundCategory.swift
│ ├── SoundMix.swift
│ └── FocusSession.swift
├── ViewModels/
│ ├── AudioManager.swift
│ ├── FocusViewModel.swift
│ ├── SleepViewModel.swift
│ ├── LibraryViewModel.swift
│ ├── RecommendationManager.swift
│ └── StoreManager.swift
├── Views/
│ ├── Focus/
│ ├── Sleep/
│ ├── Library/
│ └── Shared/
├── Services/
│ ├── AudioEngine.swift
│ ├── TimerService.swift
│ └── DownloadManager.swift
├── Resources/
│ ├── Sounds/
│ ├── Animations/
│ └── Assets.xcassets
└── Extensions/

```

**6. Code Rules**
- No force unwraps except in tests
- All ViewModels must be @Observable
- Audio playback must work in background (AVAudioSession .playback)
- Every new feature: write unit tests for ViewModel logic
- Prefer composition over inheritance
- Use Swift 6 concurrency (async/await, actors where needed)
- Error handling: no silent failures, always surface errors to UI

**7. Key Technical Notes**
- AVAudioEngine: max 3 AVAudioPlayerNode simultaneous, AVAudioMixerNode for per-track volume
- Background audio: AVAudioSession.sharedInstance().setCategory(.playback)
- Foundation Models: check SystemLanguageModel.default.availability, use @Generable for structured output, single-turn sessions only
- Sound files: AAC 192kbps, seamless loop, bundled free sounds, on-demand download for premium

Now verify and update the Xcode project settings:
- Minimum deployment target: iOS 26
- Swift language version: Swift 6
- App display name: Serenara
- Suggest an appropriate bundle identifier

Do NOT build any features yet. Only create CLAUDE.md and verify project settings.
```

---

## Prompt 2: Phase 1 — Tab Navigation + Audio Engine

```
We're starting Phase 1 (Foundation) from docs/PRD.md — sections 5.3, 7.1, and 8.2.

Before writing any code, read these docs from AdditionalDocumentation/:
- SwiftUI-Implementing-Liquid-Glass-Design.md (for tab bar and all UI)
- Swift-Concurrency-Updates.md (for async audio patterns)

Then build in this order:

1. TAB NAVIGATION
   - Root TabView with 3 tabs: Focus, Sleep, Library
   - SF Symbols: brain.head.profile (Focus), moon.stars (Sleep), square.grid.2x2 (Library)
   - Apply Liquid Glass styling to tab bar per the documentation
   - Each tab has a placeholder view for now

2. SOUND MODEL
   - Sound struct: id, name, category, fileName, isPremium, iconName
   - SoundCategory enum: nature, ambient, environment, urban
   - SoundMix struct: id, name, sounds (array of Sound + volume pairs), isFavorite
   - Static catalog matching PRD section 5.3: Rain, Thunder, Forest, Ocean Waves, White/Brown/Pink Noise, Fireplace, Wind, Night Crickets, Coffee Shop, Library Ambience

3. AUDIO MANAGER (@Observable singleton)
   - Uses AVAudioEngine with up to 3 AVAudioPlayerNode instances
   - AVAudioSession configured for .playback (background audio)
   - Audio interruption handling with automatic resume
   - Methods: play(sound:), stop(sound:), stopAll(), setVolume(for:to:)
   - Seamless looping via scheduleBuffer with .loops
   - Published state: isPlaying, activeSounds, volume per track
   - No real audio files yet — use generated silence or test tone as placeholder

4. BASIC LIBRARY VIEW
   - List all sounds grouped by category in Library tab
   - Tap a sound to play/stop it (single sound for now)
   - Show play state indicator on active sounds

Write unit tests for AudioManager core logic. Follow CLAUDE.md for all conventions.
```

---

## Prompt 3: Phase 2 — Focus Mode + Pomodoro

```
Starting Phase 2 (Core Features) — docs/PRD.md sections 5.1, 7.2, and 9.2.

Read AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md before building UI.

Build:

1. FOCUS VIEW MODEL
   - Pomodoro timer: focus (25m default), short break (5m), long break (15m)
   - Configurable: all durations + sessions before long break (default 4)
   - States: idle, focusing, shortBreak, longBreak, completed
   - Auto-transition between states, session counting
   - Free play mode (no timer, continuous playback)
   - Daily stats tracking: total focus minutes, sessions completed

2. FOCUS SCREEN UI (per PRD section 9.2)
   - Full-screen gradient background (deep navy → dark blue)
   - Center: circular ring timer showing progress + mm:ss
   - Timer digits: SF Pro Rounded, Ultralight, large
   - Below timer: active sound name(s) with volume dots
   - Bottom: large play/pause, sound picker button, settings button
   - Liquid Glass materials for controls and overlays

3. SOUND PICKER (reusable sheet)
   - Bottom sheet showing sounds grouped by category
   - Select up to 3 sounds simultaneously
   - Each selected sound gets an independent volume slider
   - Shows lock icon on premium sounds
   - Reusable by both Focus and Sleep screens

4. PERSISTENCE
   - SwiftData model for FocusSession: date, focusMinutes, sessionsCompleted
   - Read AdditionalDocumentation/SwiftData-Class-Inheritance.md first
   - Save session on completion

Write tests for FocusViewModel timer logic (state transitions, auto-advance, stats).
```

---

## Prompt 4: Phase 2 — Sleep Mode

```
Continuing Phase 2 — docs/PRD.md sections 5.2 and 9.2.

Read AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md again for Sleep UI specifics.

Build:

1. SLEEP VIEW MODEL
   - Sleep timer: 15, 30, 45, 60, 90 min, or custom
   - Fade-out duration: instant, 2, 5, 10, 15 min
   - Auto-stop after timer expires
   - Volume fade-out logic: gradual linear decrease over fade duration
   - States: idle, playing, fadingOut, stopped

2. SLEEP SCREEN UI (per PRD section 9.2)
   - Full-screen visual, darker than Focus (near-black navy)
   - Large timer digits that slowly fade in opacity as time passes
   - Minimal UI: only timer, sound info, stop button
   - Auto-dim: reduce UI opacity after 30s of no interaction, show on tap
   - Very subtle amber (#F4A261) accents only
   - Liquid Glass materials, extra translucent

3. WIRE UP
   - Sleep mode uses the same AudioManager and Sound Picker sheet
   - Fade-out: AudioManager gradually reduces all track volumes over the fade duration
   - After timer ends: AudioManager.stopAll() and show "Good night" briefly

Write tests for SleepViewModel (timer countdown, fade-out volume calculation, state transitions).
```

---

## Prompt 5: Phase 3 — Smart Sound Recommendation (AI)

```
Starting the AI feature — docs/PRD.md section 5.5.

CRITICAL: Read AdditionalDocumentation/FoundationModels-Using-on-device-LLM-in-your-app.md completely before writing any code.

Build:

1. SOUND RECOMMENDATION MODEL (@Generable)
   Define using guided generation:
   - mode: String ("focus" or "sleep")
   - sounds: [SoundSuggestion] (1-3 items, each with soundId + volume 0-100)
   - timerMinutes: Int
   - fadeOutMinutes: Int (sleep only)
   - reasoning: String (brief explanation)

2. RECOMMENDATION MANAGER
   - Check SystemLanguageModel.default.availability
   - Create LanguageModelSession with instructions containing:
     - Full sound catalog (names + IDs of sounds user has access to)
     - Mood-to-sound mapping guidance
     - Output constraints (only suggest available sounds, valid volumes, valid modes)
   - Single-turn: new session per request
   - Use streamResponse for partial results → responsive UI
   - Response time target: < 3 seconds

3. RECOMMENDATION UI
   - "✨ Describe your mood" text field on Focus and Sleep screens
   - Only visible when Apple Intelligence is available
   - Graceful degradation per PRD section 5.5 availability table:
     - Available → show AI input with sparkle icon
     - Not enabled → subtle prompt to enable in Settings
     - Not eligible → hide completely
     - Not ready → disabled with "AI is getting ready..." placeholder
   - On submit: show streaming result, then "Apply" button
   - Apply → auto-configure AudioManager + timer settings

4. TESTS
   - Test RecommendationManager with mock responses
   - Test availability checking logic
   - Test applying recommendation to AudioManager

Follow all Foundation Models patterns from the documentation. Use @Generable macro, NOT manual JSON parsing.
```

---

## Prompt 6: Phase 4 — Monetization (StoreKit 2)

```
Starting Phase 4 (Monetization) — docs/PRD.md section 6.

CRITICAL: Read AdditionalDocumentation/StoreKit-Updates.md before writing any code.

Build:

1. STORE MANAGER
   - StoreKit 2 integration for sound pack purchases
   - Product IDs matching PRD pricing tiers: standard packs, premium packs, bundle
   - Purchase flow, restore purchases, transaction verification
   - Track purchased packs and unlock corresponding sounds

2. DOWNLOAD MANAGER
   - Download premium audio files after purchase
   - Resume support for unstable connections
   - Store downloaded files in Documents directory
   - Show download progress in UI

3. LIBRARY / STORE UI
   - Update Library tab: My Favorites, All Sounds, Premium Packs sections
   - Premium pack cards with preview, description, and price
   - Purchase button with loading state
   - Lock/unlock indicators on premium sounds

Follow CLAUDE.md conventions. Test StoreManager with StoreKit Testing in Xcode.
```

---

## Quick Reference: When Things Go Wrong

| Problem                        | Prompt                                                                                              |
| ------------------------------ | --------------------------------------------------------------------------------------------------- |
| UI doesn't match design        | "Re-read SwiftUI-Implementing-Liquid-Glass-Design.md and fix [component]"                           |
| Feature doesn't match spec     | "This doesn't match PRD section [X.X]. Re-read that section and fix it."                            |
| Claude Code forgot conventions | "Re-read CLAUDE.md before continuing."                                                              |
| Need to add new feature        | "Read docs/PRD.md section [X] and AdditionalDocumentation/[relevant-doc].md, then build [feature]." |
| Build errors                   | "Fix the build errors. Check CLAUDE.md for architecture rules."                                     |
