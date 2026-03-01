# Serenara — Project Intelligence

## Project Overview

Serenara is an immersive sound & focus iOS app with two core modes:
- **Focus Mode**: Pomodoro timer with configurable work/break intervals
- **Sleep Mode**: Sleep timer with gradual fade-out

Key features: sound mixing (up to 3 simultaneous), on-device AI recommendations via Apple Foundation Models, one-time purchase sound packs (no subscriptions), Lottie animations per sound. Full spec in `docs/PRD.md`.

## Architecture

- **Pattern**: MVVM + Repository
- **Language**: Swift 6 with strict concurrency (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`)
- **UI**: SwiftUI only — no UIKit. iOS 26 minimum deployment target.
- **Design**: Liquid Glass design language (Apple's latest design system for iOS 26)
- **State**: `@Observable` (NOT `ObservableObject`), `@State`, `@Environment`
- **DI**: Environment injection via `.environment()`

## Documentation Reference Map

**RULE: Before starting ANY task, check this map. If a relevant doc exists, read it FIRST before writing code. Always use the latest APIs and patterns from these docs.**

| Task / Feature | Read First |
|---|---|
| Any UI work | `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` |
| Foundation Models / AI | `AdditionalDocumentation/FoundationModels-Using-on-device-LLM-in-your-app.md` |
| StoreKit / IAP | `AdditionalDocumentation/StoreKit-Updates.md` |
| SwiftData / Persistence | `AdditionalDocumentation/SwiftData-Class-Inheritance.md` |
| Concurrency / Async | `AdditionalDocumentation/Swift-Concurrency-Updates.md` |
| Toolbar / Navigation | `AdditionalDocumentation/SwiftUI-New-Toolbar-Features.md` |
| Styled Text | `AdditionalDocumentation/SwiftUI-Styled-Text-Editing.md` |
| Charts / Stats UI | `AdditionalDocumentation/Swift-Charts-3D-Visualization.md` |
| AlarmKit / Sleep alarm | `AdditionalDocumentation/SwiftUI-AlarmKit-Integration.md` |
| App Intents / Siri | `AdditionalDocumentation/AppIntents-Updates.md` |
| Widgets | `AdditionalDocumentation/WidgetKit-Implementing-Liquid-Glass-Design.md` |
| Accessibility | `AdditionalDocumentation/Implementing-Assistive-Access-in-iOS.md` |
| Visual Intelligence | `AdditionalDocumentation/Implementing-Visual-Intelligence-in-iOS.md` |
| MapKit | `AdditionalDocumentation/MapKit-GeoToolbox-PlaceDescriptors.md` |
| AttributedString | `AdditionalDocumentation/Foundation-AttributedString-Updates.md` |
| InlineArray / Span | `AdditionalDocumentation/Swift-InlineArray-Span.md` |
| WebKit integration | `AdditionalDocumentation/SwiftUI-WebKit-Integration.md` |
| AppKit Liquid Glass | `AdditionalDocumentation/AppKit-Implementing-Liquid-Glass-Design.md` |
| UIKit Liquid Glass | `AdditionalDocumentation/UIKit-Implementing-Liquid-Glass-Design.md` |

## Design System Tokens

### Colors
- **Primary**: Deep Navy `#0D1B2A`
- **Accent**: Soft Blue `#5B9BD5`
- **Warm**: Amber `#F4A261`

### Typography
- **Font**: SF Pro Rounded (system)
- **Timer digits**: Light/Ultralight weight
- **Body**: Regular weight
- **Minimal text** — let visuals speak

### Iconography
- SF Symbols, rounded & filled style

### Layout & Motion
- All UI uses Liquid Glass materials and effects
- Dark mode primary, minimal chrome, generous whitespace
- All transitions use spring animations — no abrupt changes
- Full-screen canvas for visuals/animations with floating controls

## File Structure

```
Saranera/
├── App/
│   └── SaraneraApp.swift
├── Models/
│   ├── Sound.swift
│   ├── SoundCategory.swift
│   ├── SoundMix.swift
│   └── FocusSession.swift
├── ViewModels/
│   ├── AudioManager.swift
│   ├── FocusViewModel.swift
│   ├── SleepViewModel.swift
│   ├── LibraryViewModel.swift
│   ├── RecommendationManager.swift
│   └── StoreManager.swift
├── Views/
│   ├── Focus/
│   ├── Sleep/
│   ├── Library/
│   └── Shared/
├── Services/
│   ├── AudioEngine.swift
│   ├── TimerService.swift
│   └── DownloadManager.swift
├── Resources/
│   ├── Sounds/
│   ├── Animations/
│   └── Assets.xcassets
└── Extensions/
```

## Code Rules

- No force unwraps except in tests
- All ViewModels must be `@Observable`
- Audio playback must work in background (`AVAudioSession` `.playback`)
- Every new feature: write unit tests for ViewModel logic
- Prefer composition over inheritance
- Use Swift 6 concurrency (`async/await`, actors where needed)
- Error handling: no silent failures, always surface errors to UI
- Use `@concurrent` attribute for background work (Swift 6.2 pattern)
- Use isolated conformances (`@MainActor Exportable`) where needed

## Key Technical Notes

### Audio Engine
- `AVAudioEngine` with max 3 `AVAudioPlayerNode` instances simultaneous
- `AVAudioMixerNode` for per-track volume control
- Seamless looping via `scheduleBuffer` with loop flag
- Background audio: `AVAudioSession.sharedInstance().setCategory(.playback)`
- Interruption handling: observe `AVAudioSession.interruptionNotification`

### Foundation Models (On-Device AI)
- Check `SystemLanguageModel.default.availability` before showing AI features
- Use `@Generable` macro for structured output (`SoundRecommendation`)
- Single-turn sessions only — new `LanguageModelSession` per request
- Use `response.content` (NOT `response.output`) to access results
- Stream partial results using `streamResponse` for responsive UI
- Context limit: 4,096 tokens total
- Graceful fallback: hide AI input on unsupported devices

### Sound Files
- Format: AAC 192kbps, seamless loop
- Free sounds (12+): bundled in app binary
- Premium sounds: downloaded after purchase, stored in Documents directory
- Minimum 5 minutes per track (seamless loop point)

### StoreKit 2
- One-time purchase per sound pack (no subscriptions)
- Use `SubscriptionOfferView` for pack merchandising if applicable
- Test with StoreKit Configuration File in Xcode

## Xcode Project Settings

- **Bundle ID**: `app.fiqhrodedhen.Saranera`
- **Display Name**: Serenara
- **Deployment Target**: iOS 26
- **Swift Version**: 6.0
- **Concurrency**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- **Development Team**: C588LMCKSL
- **Targeted Devices**: iPhone and iPad (1,2)

## Navigation Structure

3-tab `TabView`:
1. **Focus** — Sound picker, Pomodoro timer, visual canvas, stats
2. **Sleep** — Sound picker, sleep timer, dark UI, fade controls
3. **Library** — All sounds, saved mixes, premium packs, categories

## MVP Priorities (MoSCoW)

### MUST
- Audio playback with background support
- Sound mixing (2-3 simultaneous)
- Focus Mode with Pomodoro timer
- Sleep Mode with sleep timer & fade-out
- 12+ bundled free sounds
- Basic Lottie animations per sound

### SHOULD
- Save favorite mixes
- Smart Sound Recommendation (Apple Foundation Models)
- In-App Purchase (StoreKit 2) for sound packs
- Focus session statistics
- Preset mixes

### COULD
- Onboarding flow
- Haptic feedback on timer events
- Particle effects layer
