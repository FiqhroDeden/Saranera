# Serenara — Product Requirements Document

**Immersive Sound & Focus App**
_Your sanctuary for focus and restful sleep_

---

| Field        | Detail        |
| ------------ | ------------- |
| **Version**  | 1.0 (MVP)     |
| **Platform** | iOS (SwiftUI) |
| **Date**     | March 2026    |
| **Status**   | Draft         |

---

## 1. Executive Summary

Serenara is an iOS application that delivers an immersive audio experience designed to help users achieve optimal focus and quality sleep. By combining nature sounds, ambient textures, and lo-fi audio with soothing visual animations, Serenara offers two core modes: **Focus Mode** with integrated Pomodoro Timer and **Sleep Mode** with a sleep timer and automatic fade-out.

Built with SwiftUI for iOS, the app targets college students who need effective study tools and individuals struggling with sleep difficulties. Serenara also leverages **Apple Foundation Models** to provide on-device AI-powered smart sound recommendations — users can describe their mood in natural language and receive personalized soundscape suggestions, all processed locally with zero cloud dependency. Monetization follows a **one-time purchase per sound pack** model, with 10+ free sounds serving as the foundation of the experience.

---

## 2. Problem Statement

### 2.1 Pain Points

| Segment                      | Problem                                                                                                                     | Impact                                                                               |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **College Students**         | Difficulty focusing in noisy environments (dorms, campus, cafés). Frequently distracted by notifications and ambient noise. | Low productivity, ineffective study sessions, suboptimal academic performance.       |
| **People with Sleep Issues** | Difficulty falling asleep due to an active mind, disruptive environmental noise, or lack of a consistent bedtime routine.   | Poor sleep quality, chronic fatigue, negative effects on mental and physical health. |

### 2.2 Competitive Gap

Existing sound and white noise apps on the market tend to enforce expensive subscription models, feature generic UIs without immersive visuals, or bundle too many features (meditation, journaling, breathing exercises) that dilute their core purpose. Serenara fills this gap as a focused and affordable solution: a visually beautiful sound app with two clear modes, on-device AI-powered recommendations, and no subscription pressure.

---

## 3. Target Users

### 3.1 Primary Persona: College Student

- **Name:** Andi, 21 years old, Engineering Student
- **Need:** A study aid with Pomodoro technique integration
- **Behavior:** Studies 3–6 hours/day, often in dorms or the library
- **Frustration:** Distracted by environmental noise, no consistent study rhythm
- **Goal:** Sustain longer, more energized focus sessions

### 3.2 Secondary Persona: Working Professional with Insomnia

- **Name:** Sari, 28 years old, Private Sector Employee
- **Need:** Help relaxing and falling asleep faster
- **Behavior:** High screen time before bed, mind still racing while lying down
- **Frustration:** Has tried several apps but they are too complex or require expensive subscriptions
- **Goal:** Fall asleep within 15–30 minutes in a calming atmosphere

---

## 4. Product Vision & Principles

### 4.1 Vision Statement

> _Serenara becomes a daily companion that helps everyone find tranquility — whether they need full focus or a peaceful night's rest. Simple, beautiful, and effective._

### 4.2 Design Principles

| Principle              | Description                                                                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Calm by Default**    | Every UI element should evoke a sense of calm. No aggressive colors, excessive animations, or intrusive notifications.                    |
| **Two Taps to Sound**  | Users should be able to start playing a sound within a maximum of 2 taps from the home screen. Minimal friction.                          |
| **Visual = Emotional** | Animations are not mere decoration — they reinforce the emotional effect of the sound. Rain should look like rain, fire should feel warm. |
| **Fair Pricing**       | Buy once, own forever. No subscription pressure or dark pattern monetization.                                                             |

---

## 5. Feature Specification

### 5.1 Focus Mode (Pomodoro Timer)

A mode designed for productive study and work sessions with integrated Pomodoro technique.

**Timer Configuration:**

| Parameter                  | Default    | Range         |
| -------------------------- | ---------- | ------------- |
| Focus Duration             | 25 minutes | 5–120 minutes |
| Short Break                | 5 minutes  | 1–30 minutes  |
| Long Break                 | 15 minutes | 5–60 minutes  |
| Sessions before Long Break | 4 sessions | 2–8 sessions  |

**Behavior:**

- Sound plays during focus sessions, auto-pauses during breaks (optional)
- Gentle notification (soft chime) on focus → break and break → focus transitions
- Visual progress: ring timer with smooth animation centered on screen
- Session statistics: total focus time today, daily streak
- Can be started without a timer (free play mode) for flexibility

### 5.2 Sleep Mode (Sleep Timer)

A mode designed to help users relax and fall asleep comfortably.

**Timer Configuration:**

| Parameter         | Default    | Options                            |
| ----------------- | ---------- | ---------------------------------- |
| Sleep Timer       | 30 minutes | 15, 30, 45, 60, 90 minutes, custom |
| Fade-out Duration | 5 minutes  | Instant, 2, 5, 10, 15 minutes      |
| Auto-stop         | Yes        | Stops after timer expires          |

**Behavior:**

- UI automatically switches to dark mode with minimal brightness
- Gradual volume fade-out as the timer approaches its end
- Screen auto-dims after 30 seconds of inactivity
- Simple gestures: tap to view remaining time, swipe to stop
- Optional alarm: wake up gradually with the same sound (nice-to-have)

### 5.3 Sound System

**Sound Library (MVP) — Minimum 12 free sounds bundled with the app:**

| Category    | Sounds (Free)                        | Count |
| ----------- | ------------------------------------ | ----- |
| Nature      | Rain, Thunder, Forest, Ocean Waves   | 4     |
| Ambient     | White Noise, Brown Noise, Pink Noise | 3     |
| Environment | Fireplace, Wind, Night Crickets      | 3     |
| Urban       | Coffee Shop, Library Ambience        | 2     |

**Sound Mixing:**

- Users can select and combine 2–3 sounds simultaneously
- Each sound has an independent volume slider (0–100%)
- Preset mixes available: e.g. "Rainy Cafe" (Rain + Coffee Shop), "Forest Night" (Forest + Crickets + Wind)
- Users can save custom mixes as favorites

**Audio Technical Requirements:**

- Format: AAC or MP3, minimum bitrate 192kbps
- Loop: seamless looping with no gaps or clicks
- Duration: minimum 5 minutes per track (seamless loop point)
- Background Audio: must continue playing when the app is backgrounded, the screen is locked, or other apps are in use
- Interruption handling: automatic resume after phone calls or other audio notifications

### 5.4 Visual & Animation System

Each sound or scene has a lightweight visual animation that reinforces its emotional tone.

**Technical Approach:**

| Technology        | Usage                                     | Examples                                            |
| ----------------- | ----------------------------------------- | --------------------------------------------------- |
| Lottie Animations | Primary looping animation per sound/scene | Raindrops, flickering fire, swaying leaves          |
| Particle Effects  | Additional layer for depth and immersion  | Snow particles, fireflies, water splashes           |
| Gradient Shifts   | Background color that changes slowly      | Sunset gradient for sleep mode, cool blue for focus |

**Performance Targets:**

- Animations must run at 60fps on iPhone 12 and above
- Battery consumption: maximum 5% per hour while active in foreground
- Animations automatically reduced in low power mode

### 5.5 Smart Sound Recommendation (Apple Intelligence)

An on-device AI feature powered by Apple Foundation Models that allows users to describe their current mood, activity, or desired atmosphere in natural language and receive a personalized soundscape recommendation. All processing happens locally on-device — no cloud calls, no data leaving the device.

**How It Works:**

1. User taps the "✨ Describe your mood" input field (available on both Focus and Sleep screens)
2. User types a natural language description (e.g., "I'm stressed from exams and need to concentrate", "feeling anxious, can't sleep, it's raining outside")
3. The on-device LLM analyzes the input and returns a structured recommendation
4. Serenara auto-configures the suggested sounds, volume levels, and mode

**Example Interactions:**

| User Input                                                  | AI Recommendation                                                        |
| ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| "I need to focus on writing my thesis, feeling a bit tired" | Focus Mode · Coffee Shop (70%) + Brown Noise (30%) · 25 min Pomodoro     |
| "Exhausted after work, want to drift off to sleep"          | Sleep Mode · Ocean Waves (60%) + Wind (40%) · 45 min timer · 10 min fade |
| "Rainy day vibes, just want to chill and read"              | Focus Mode (free play) · Rain (80%) + Fireplace (50%)                    |
| "Anxious, racing thoughts, need something calming"          | Sleep Mode · Pink Noise (50%) + Night Crickets (40%) · 60 min timer      |

**Technical Implementation:**

```
Framework:     Apple Foundation Models (FoundationModels)
Model:         SystemLanguageModel.default
Generation:    Guided Generation with @Generable struct
Availability:  Devices supporting Apple Intelligence (iPhone 15 Pro+, etc.)
Fallback:      Manual sound selection (standard UI) on unsupported devices
```

**Structured Output — `SoundRecommendation` (Generable):**

The LLM returns structured data using guided generation, mapped directly to a Swift struct:

```
SoundRecommendation
├── mode: String              → "focus" or "sleep"
├── sounds: [SoundSuggestion] → array of 1–3 sounds
│   ├── soundId: String       → matches internal sound catalog
│   └── volume: Int           → 0–100
├── timerMinutes: Int         → suggested timer duration
├── fadeOutMinutes: Int       → fade-out duration (sleep mode only)
└── reasoning: String         → brief explanation of why this mix was chosen
```

**Session Instructions (System Prompt):**

The LLM session is initialized with instructions that define Serenara's sound catalog, mood-to-sound mapping logic, and output constraints. The model is instructed to only recommend sounds available in the user's library (free or purchased).

**Availability & Graceful Degradation:**

| Device State                   | Behavior                                                                                |
| ------------------------------ | --------------------------------------------------------------------------------------- |
| Apple Intelligence available   | Show "✨ Describe your mood" input with AI sparkle icon                                 |
| Apple Intelligence not enabled | Show a subtle prompt: "Enable Apple Intelligence in Settings for smart recommendations" |
| Device not eligible            | Hide the AI input entirely; user selects sounds manually as normal                      |
| Model not ready (downloading)  | Show input as disabled with "AI is getting ready..." placeholder                        |

**Key Constraints:**

- Context window: 4,096 tokens — instructions + prompt + output must fit within this limit
- Single-turn interaction only (new session per recommendation request)
- Response time target: < 3 seconds on supported devices
- No network required — fully on-device processing
- The feature is an enhancement, not a dependency — the app is fully functional without it

---

## 6. Monetization Strategy

### 6.1 Model: One-Time Purchase per Sound Pack

Serenara uses a separate purchase model per sound pack. No subscriptions. Users buy once and have access forever.

### 6.2 Pricing Structure

| Tier                  | Price (IDR)       | Content                                      | Target User                 |
| --------------------- | ----------------- | -------------------------------------------- | --------------------------- |
| **Free**              | Rp 0              | 12+ basic sounds, all core features          | All users                   |
| **Standard Pack**     | Rp 29,000–39,000  | 6–8 themed sounds + exclusive visuals        | Users seeking variety       |
| **Premium Pack**      | Rp 49,000         | 8–10 premium sounds + preset mixes           | Power users & enthusiasts   |
| **Bundle All Access** | Rp 99,000–149,000 | All current packs + discount on future packs | Early adopters, whale users |

### 6.3 Planned Sound Packs (Post-Launch)

- **"Rainy Day Collection"** — Rain variations: drizzle, thunderstorm, rain on a tin roof, rain on a tent
- **"Ocean Dreams"** — Beach waves, underwater, harbor, seagulls
- **"Lo-Fi Study"** — Lo-fi beats, vinyl crackle, keyboard typing, pen writing
- **"Nusantara"** — Gamelan, rice paddies, river, traditional market sounds _(unique differentiator)_
- **"City Nights"** — Distant traffic, train, apartment window, late-night diner

---

## 7. User Flow & Navigation

### 7.1 App Structure

Navigation uses a tab bar with 3 main tabs:

| Tab         | Function                               | Content                                            |
| ----------- | -------------------------------------- | -------------------------------------------------- |
| **Focus**   | Focus Mode with Pomodoro timer         | Sound picker, timer controls, visual canvas, stats |
| **Sleep**   | Sleep Mode with sleep timer            | Sound picker, sleep timer, dark UI, fade controls  |
| **Library** | Sound collection, favorites, and store | All sounds, saved mixes, premium packs, categories |

### 7.2 Core User Flows

**Flow A — Quick Focus Session:**
Open App → Tap "Focus" Tab → Select Sound(s) → Tap "Start Focus" → Pomodoro Begins → Soft Chime at Break → Resume → Session Complete

**Flow B — Sleep Mode:**
Open App → Tap "Sleep" Tab → Select Sound(s) → Set Timer → Tap "Begin Sleep" → Lights Dim → Gradual Fade-out → Audio Stops

**Flow C — Sound Mixing:**
In Focus/Sleep Mode → Tap "+" to add sound → Browse/Search → Select up to 3 → Adjust individual volumes → Optionally save as favorite mix

**Flow D — Smart Recommendation (AI-Powered):**
In Focus/Sleep Screen → Tap "✨ Describe your mood" → Type natural language input → AI generates recommendation → Review suggested sounds, mode, and timer → Tap "Apply" to accept or modify manually → Session begins

---

## 8. Technical Architecture

### 8.1 Tech Stack

| Layer           | Technology                                            |
| --------------- | ----------------------------------------------------- |
| UI Framework    | SwiftUI (iOS 16+)                                     |
| Audio Engine    | AVFoundation (AVAudioEngine for multi-track mixing)   |
| Animation       | Lottie-iOS + SwiftUI Canvas for particle effects      |
| On-Device AI    | Apple Foundation Models (Smart Sound Recommendation)  |
| Local Storage   | SwiftData / UserDefaults (settings, favorites, stats) |
| In-App Purchase | StoreKit 2                                            |
| Audio Files     | Bundled (free), On-demand download (premium)          |
| Analytics       | TelemetryDeck or Firebase Analytics (privacy-first)   |
| Architecture    | MVVM + Repository Pattern                             |

### 8.2 Key Technical Considerations

**Audio Engine (AVAudioEngine):**

- Uses AVAudioPlayerNode for each track (max 3 simultaneous)
- AVAudioMixerNode for per-track volume control
- Seamless looping via scheduleBuffer with loop flag
- Background audio via AVAudioSession category `.playback`
- Interruption handling: observe `AVAudioSession.interruptionNotification`

**Offline & Download Strategy:**

- Free sounds (12+): bundled in app binary, available offline from install
- Premium sounds: downloaded after purchase, stored in Documents directory
- Download manager: resume support for unstable connections
- Total estimated app size: 80–120 MB (bundled), +20–40 MB per premium pack

**SwiftUI Architecture:**

- Root: `TabView` with 3 tabs (Focus, Sleep, Library)
- Shared `AudioManager` as `@EnvironmentObject` (singleton)
- Timer logic in a dedicated `TimerViewModel`, decoupled from UI
- Animation layer via overlay using Lottie or Canvas
- StoreKit 2 integration via `StoreManager` class

**Apple Foundation Models (On-Device AI):**

- Check `SystemLanguageModel.default.availability` before showing AI features
- Create a new `LanguageModelSession` per recommendation request (single-turn)
- Use `@Generable` macro to define `SoundRecommendation` struct for guided generation
- Session instructions contain the full sound catalog and mood-mapping logic
- Stream partial results using `streamResponse` for responsive UI feedback
- Graceful fallback: AI feature hidden on unsupported devices, manual selection always available
- `RecommendationManager` class handles session lifecycle, prompt construction, and result parsing

---

## 9. UI/UX Design Guidelines

### 9.1 Visual Identity

| Element           | Specification                                                                                                                                             |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Color Palette** | Dark mode primary. Deep navy (`#0D1B2A`), soft blue accent (`#5B9BD5`), warm amber highlights (`#F4A261`). Light surfaces only for content/text overlays. |
| **Typography**    | SF Pro Rounded (system font). Display: Light/Ultralight weight for timer digits. Body: Regular weight. Minimal text — let the visuals speak.              |
| **Iconography**   | SF Symbols, style: rounded & filled. Custom icons for sound categories if needed.                                                                         |
| **Layout**        | Full-screen canvas for visuals/animations. Floating controls above the visual layer. Generous whitespace, minimal chrome.                                 |
| **Motion**        | All transitions use spring animations. No abrupt animations. Loading and state changes should feel organic.                                               |

### 9.2 Key Screen Descriptions

**Focus Screen:**
Full-screen visual canvas with animation matching the selected sound. Center: circular Pomodoro timer (ring progress) with minute:second digits in large, light-weight font. Below the timer: current sound name(s) with small volume indicators. Bottom area: play/pause button (prominent), skip break, and sound picker toggle. Dominant colors: cool blue and deep navy.

**Sleep Screen:**
Full-screen visual that is darker and more subtle than Focus. Timer displayed as large digits that slowly fade. Minimal UI elements — only timer, sound info, and stop button. Auto-dims after inactivity. Dominant colors: very dark navy, nearly black, with extremely subtle amber accents.

**Library Screen:**
Grid or list view of all sounds, grouped by category. Each sound has a small representative thumbnail/icon. Separate sections for: My Favorites, All Sounds (free), Premium Packs. Premium packs displayed as cards with preview and pricing. Search bar at the top for quick filtering.

---

## 10. MVP Scope & Prioritization

### MoSCoW Prioritization

| Priority      | Feature                                              | Effort               |
| ------------- | ---------------------------------------------------- | -------------------- |
| 🟢 **MUST**   | Audio playback with background support               | Medium               |
| 🟢 **MUST**   | Sound mixing (2–3 simultaneous sounds)               | Medium-High          |
| 🟢 **MUST**   | Focus Mode with Pomodoro timer                       | Medium               |
| 🟢 **MUST**   | Sleep Mode with sleep timer & fade-out               | Medium               |
| 🟢 **MUST**   | 12+ bundled free sounds                              | Low (asset sourcing) |
| 🟢 **MUST**   | Basic Lottie animations per sound                    | Medium-High          |
| 🔵 **SHOULD** | Save favorite mixes                                  | Low                  |
| 🔵 **SHOULD** | Smart Sound Recommendation (Apple Foundation Models) | Medium               |
| 🔵 **SHOULD** | In-App Purchase (StoreKit 2) for sound packs         | Medium               |
| 🔵 **SHOULD** | Focus session statistics (daily/weekly)              | Low-Medium           |
| 🔵 **SHOULD** | Preset mixes (curated combinations)                  | Low                  |
| 🟠 **COULD**  | Onboarding flow (select initial preferences)         | Low                  |
| 🟠 **COULD**  | Haptic feedback on timer events                      | Low                  |
| 🟠 **COULD**  | Particle effects layer (beyond Lottie)               | Medium               |

---

## 11. Roadmap

### Development Phases

| Phase                        | Timeline   | Deliverables                                                                                                                                             |
| ---------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Phase 1: Foundation**      | Week 1–3   | Project setup, SwiftUI architecture, audio engine (AVAudioEngine), basic playback & mixing, tab navigation                                               |
| **Phase 2: Core Features**   | Week 4–6   | Pomodoro timer, sleep timer + fade-out, mode switching (Focus/Sleep), sound library UI                                                                   |
| **Phase 3: Visual & Polish** | Week 7–9   | Lottie integration, per-sound animations, dark mode sleep UI, favorites system, preset mixes, Apple Foundation Models integration (Smart Recommendation) |
| **Phase 4: Monetization**    | Week 10–11 | StoreKit 2 integration, premium pack download system, Library/Store UI, pricing setup                                                                    |
| **Phase 5: Launch Prep**     | Week 12–13 | QA & bug fixes, App Store assets, performance optimization, beta testing (TestFlight), submission                                                        |

### Post-Launch (v1.1 – v2.0)

- iPadOS optimization with wider layouts
- Widgets (Lock Screen & Home Screen) for quick play
- Apple Watch companion: basic controls and haptic timer
- Siri Shortcuts: "Hey Siri, start focus in Serenara"
- New sound packs every 4–6 weeks (Nusantara, Lo-Fi Study, etc.)
- Generative visuals (shader-based) for a more immersive experience
- Social: share custom mixes with friends
- HealthKit integration: correlate sleep timer usage with sleep quality
- AI-powered session summaries and motivational notes after focus sessions
- AI mood check-in: auto-detect mode (Focus/Sleep) and sound based on natural language mood input
- AI-driven adaptive soundscapes that evolve during a session based on user behavior

---

## 12. Success Metrics

| Metric                   | Target (3 Months) | Target (6 Months) | Measurement                     |
| ------------------------ | ----------------- | ----------------- | ------------------------------- |
| Downloads                | 5,000             | 15,000            | App Store Connect               |
| DAU / MAU Ratio          | > 25%             | > 30%             | Analytics                       |
| Avg. Session Duration    | > 20 minutes      | > 25 minutes      | Analytics                       |
| Conversion (free → paid) | > 3%              | > 5%              | StoreKit reports                |
| App Store Rating         | > 4.5             | > 4.6             | App Store Connect               |
| D7 Retention             | > 30%             | > 40%             | Analytics                       |
| Revenue (total)          | Rp 5 million      | Rp 25 million     | App Store Connect               |
| AI Recommendation Usage  | > 15% of sessions | > 25% of sessions | Analytics (on eligible devices) |

---

## 13. Risks & Mitigations

| Risk                                            | Impact    | Mitigation                                                                                                                                                 |
| ----------------------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| App size too large due to audio files           | 🔴 High   | Optimal audio compression (AAC 192kbps), bundle only 12 sounds, remaining available as on-demand downloads                                                 |
| Excessive battery drain from animations + audio | 🔴 High   | Profile with Instruments, reduce animation complexity, auto-pause animations in background, reduced motion in Low Power Mode                               |
| Poor audio interruption handling                | 🟡 Medium | Implement robust AVAudioSession interruption observer, test with calls, Siri, alarms, and other audio apps                                                 |
| Low free-to-paid conversion rate                | 🟡 Medium | Free tier must be valuable enough for retention, premium must feel "wow" during preview. A/B test pricing and pack composition                             |
| Asset production bottleneck (audio + animation) | 🟡 Medium | Use royalty-free audio libraries for MVP, invest in original content after product-market fit is proven                                                    |
| Apple Intelligence limited device support       | 🟡 Medium | AI feature is enhancement-only; full manual UX always available. Monitor Apple Intelligence adoption rates and expand AI features as device coverage grows |

---

## 14. Appendix

### 14.1 Competitor Analysis

| App           | Strengths                                                     | Weaknesses                                          | Serenara's Opportunity         |
| ------------- | ------------------------------------------------------------- | --------------------------------------------------- | ------------------------------ |
| **Calm**      | Strong brand, extensive meditation content, beautiful visuals | Expensive subscription (~$70/yr), too many features | More focused & affordable      |
| **Noisli**    | Great sound mixing, minimal UI                                | Visuals lacking appeal, feels outdated              | Immersive visuals + timer      |
| **Rain Rain** | Large sound library, mixing support                           | Cluttered UI, too many ads                          | Clean UI, no ads, fair pricing |

### 14.2 Audio Source Strategy

For MVP, use a combination of the following audio sources:

- **Royalty-free libraries:** Freesound.org, Pixabay Audio, Artlist (for higher quality)
- **Procedural generation:** White/Brown/Pink noise can be generated programmatically using AVAudioEngine
- **Original recordings:** Targeted for post-MVP, especially for the Nusantara pack as a unique selling point

---

_Serenara — Your sanctuary for focus and restful sleep._
