# Serenara

**Your sanctuary for focus and restful sleep.**

Serenara is an immersive sound & focus iOS app that combines nature sounds, ambient textures, and lo-fi audio with soothing visual animations. Two core modes help users achieve optimal productivity and quality sleep.

## Features

### Focus Mode
- Integrated Pomodoro timer (configurable work/break intervals)
- Sound plays during focus, auto-pauses during breaks
- Ring progress animation with session statistics
- Daily streak tracking

### Sleep Mode
- Sleep timer with gradual volume fade-out
- Auto-dimming dark UI for minimal distraction
- Simple gesture controls (tap for time, swipe to stop)

### Sound Mixing
- Combine up to 3 sounds simultaneously
- Independent volume control per track
- Preset mixes (e.g., "Rainy Cafe", "Forest Night")
- Save custom mixes as favorites

### Smart Recommendations (Apple Intelligence)
- Describe your mood in natural language
- On-device AI suggests sounds, mode, and timer settings
- Powered by Apple Foundation Models — fully private, no cloud dependency
- Graceful fallback on unsupported devices

### Sound Library
- 12+ free sounds bundled (Nature, Ambient, Environment, Urban)
- Premium sound packs available as one-time purchases
- No subscriptions

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 26+, Liquid Glass design) |
| Audio | AVFoundation (AVAudioEngine, multi-track mixing) |
| Animation | Lottie + SwiftUI Canvas |
| On-Device AI | Apple Foundation Models |
| Persistence | SwiftData / UserDefaults |
| In-App Purchase | StoreKit 2 |
| Architecture | MVVM + Repository |
| Language | Swift 6 |

## Requirements

- iOS 26.0+
- Xcode 26.1+
- Swift 6

## Getting Started

1. Clone the repository
2. Open `Saranera.xcodeproj` in Xcode
3. Select a simulator or device running iOS 26+
4. Build and run

## Project Structure

```
Saranera/
├── App/                  # App entry point
├── Models/               # Data models (Sound, SoundMix, FocusSession)
├── ViewModels/           # @Observable view models and managers
├── Views/                # SwiftUI views (Focus/, Sleep/, Library/, Shared/)
├── Services/             # Audio engine, timer, download manager
├── Resources/            # Sounds, animations, assets
└── Extensions/           # Swift extensions
```

## Design

- **Color palette**: Deep Navy (#0D1B2A), Soft Blue (#5B9BD5), Amber (#F4A261)
- **Typography**: SF Pro Rounded
- **Icons**: SF Symbols (rounded, filled)
- **Design language**: Apple Liquid Glass
- **Dark mode primary** with minimal chrome

## Documentation

- [Product Requirements Document](docs/PRD.md) — full product specification

## License

All rights reserved.
