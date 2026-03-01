# Phase 1: Foundation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build Serenara's foundation — tab navigation, sound data model, audio playback engine with test tones, and a basic library view.

**Architecture:** Monolithic AudioManager (`@Observable` singleton with `AVAudioEngine`) injected via `.environment()`. SwiftUI TabView with Liquid Glass (iOS 26 native). All code is MainActor-isolated by default (Swift 6.2 approachable concurrency).

**Tech Stack:** Swift 6 / SwiftUI / AVFoundation / Swift Testing framework

**References:**
- Design doc: `docs/plans/2026-03-01-phase1-foundation-design.md`
- Liquid Glass: `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md`
- Concurrency: `AdditionalDocumentation/Swift-Concurrency-Updates.md`
- PRD: `docs/PRD.md` (sections 5.3, 7.1, 8.2)

**Test command:**
```bash
xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20
```

**Build command (compile check only):**
```bash
xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10
```

**Important project settings:**
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all code is MainActor by default
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- iOS 26 minimum deployment target
- Swift Testing framework (use `import Testing`, `@Test`, `#expect` — NOT XCTest)
- All new files must be added to the Xcode project's `Saranera` target (or `SaraneraTests` for test files)

---

## Task 1: Sound Models (SoundCategory + Sound + SoundMix)

**Files:**
- Create: `Saranera/Models/SoundCategory.swift`
- Create: `Saranera/Models/Sound.swift`
- Create: `Saranera/Models/SoundMix.swift`
- Test: `SaraneraTests/SoundModelTests.swift`

**Step 1: Write the failing tests**

Create `SaraneraTests/SoundModelTests.swift`:

```swift
import Testing
@testable import Saranera

struct SoundModelTests {

    // MARK: - SoundCategory

    @Test func soundCategoryHasFourCases() {
        #expect(SoundCategory.allCases.count == 4)
    }

    @Test func soundCategoryDisplayNames() {
        #expect(SoundCategory.nature.displayName == "Nature")
        #expect(SoundCategory.ambient.displayName == "Ambient")
        #expect(SoundCategory.environment.displayName == "Environment")
        #expect(SoundCategory.urban.displayName == "Urban")
    }

    // MARK: - Sound Catalog

    @Test func catalogHas12FreeSounds() {
        #expect(Sound.catalog.count == 12)
    }

    @Test func catalogHasNoPremiuimSounds() {
        let premiumSounds = Sound.catalog.filter { $0.isPremium }
        #expect(premiumSounds.isEmpty)
    }

    @Test func catalogCoversAllCategories() {
        let categories = Set(Sound.catalog.map(\.category))
        #expect(categories.count == 4)
    }

    @Test func catalogSoundsHaveUniqueIDs() {
        let ids = Sound.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func soundLookupByID() {
        let rain = Sound.catalog.first { $0.id == "rain" }
        #expect(rain != nil)
        #expect(rain?.name == "Rain")
        #expect(rain?.category == .nature)
        #expect(rain?.iconName == "cloud.rain")
    }

    // MARK: - Sound Grouping

    @Test func soundsGroupByCategory() {
        let grouped = Sound.grouped
        #expect(grouped[.nature]?.count == 4)
        #expect(grouped[.ambient]?.count == 3)
        #expect(grouped[.environment]?.count == 3)
        #expect(grouped[.urban]?.count == 2)
    }

    // MARK: - SoundMix

    @Test func soundMixCreation() {
        let mix = SoundMix(
            name: "Rainy Cafe",
            components: [
                MixComponent(soundID: "rain", volume: 0.8),
                MixComponent(soundID: "coffee_shop", volume: 0.6)
            ]
        )
        #expect(mix.name == "Rainy Cafe")
        #expect(mix.components.count == 2)
        #expect(mix.isFavorite == false)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20`
Expected: Build failure — `SoundCategory`, `Sound`, `SoundMix` not defined.

**Step 3: Implement SoundCategory**

Create `Saranera/Models/SoundCategory.swift`:

```swift
import Foundation

enum SoundCategory: String, CaseIterable, Codable, Sendable {
    case nature
    case ambient
    case environment
    case urban

    var displayName: String {
        switch self {
        case .nature: "Nature"
        case .ambient: "Ambient"
        case .environment: "Environment"
        case .urban: "Urban"
        }
    }

    var iconName: String {
        switch self {
        case .nature: "leaf"
        case .ambient: "waveform"
        case .environment: "house"
        case .urban: "building.2"
        }
    }
}
```

**Step 4: Implement Sound**

Create `Saranera/Models/Sound.swift`:

```swift
import Foundation

struct Sound: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let category: SoundCategory
    let fileName: String
    let isPremium: Bool
    let iconName: String

    static let catalog: [Sound] = [
        // Nature
        Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
        Sound(id: "thunder", name: "Thunder", category: .nature, fileName: "thunder.m4a", isPremium: false, iconName: "cloud.bolt"),
        Sound(id: "forest", name: "Forest", category: .nature, fileName: "forest.m4a", isPremium: false, iconName: "tree"),
        Sound(id: "ocean_waves", name: "Ocean Waves", category: .nature, fileName: "ocean_waves.m4a", isPremium: false, iconName: "water.waves"),
        // Ambient
        Sound(id: "white_noise", name: "White Noise", category: .ambient, fileName: "white_noise.m4a", isPremium: false, iconName: "waveform"),
        Sound(id: "brown_noise", name: "Brown Noise", category: .ambient, fileName: "brown_noise.m4a", isPremium: false, iconName: "waveform.path"),
        Sound(id: "pink_noise", name: "Pink Noise", category: .ambient, fileName: "pink_noise.m4a", isPremium: false, iconName: "waveform.badge.magnifyingglass"),
        // Environment
        Sound(id: "fireplace", name: "Fireplace", category: .environment, fileName: "fireplace.m4a", isPremium: false, iconName: "flame"),
        Sound(id: "wind", name: "Wind", category: .environment, fileName: "wind.m4a", isPremium: false, iconName: "wind"),
        Sound(id: "night_crickets", name: "Night Crickets", category: .environment, fileName: "night_crickets.m4a", isPremium: false, iconName: "moon.stars"),
        // Urban
        Sound(id: "coffee_shop", name: "Coffee Shop", category: .urban, fileName: "coffee_shop.m4a", isPremium: false, iconName: "cup.and.saucer"),
        Sound(id: "library_ambience", name: "Library Ambience", category: .urban, fileName: "library_ambience.m4a", isPremium: false, iconName: "books.vertical"),
    ]

    static var grouped: [SoundCategory: [Sound]] {
        Dictionary(grouping: catalog, by: \.category)
    }
}
```

**Step 5: Implement SoundMix**

Create `Saranera/Models/SoundMix.swift`:

```swift
import Foundation

struct MixComponent: Codable, Hashable, Sendable {
    let soundID: String
    var volume: Float
}

struct SoundMix: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var components: [MixComponent]
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, components: [MixComponent], isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.components = components
        self.isFavorite = isFavorite
    }
}
```

**Step 6: Add all new files to the Xcode project**

All `.swift` files in the `Saranera/` directory need to be in the Saranera target. Test files in `SaraneraTests/` need to be in SaraneraTests target. Create necessary directories first:

```bash
mkdir -p Saranera/Models
mkdir -p Saranera/ViewModels
mkdir -p Saranera/Views/Focus
mkdir -p Saranera/Views/Sleep
mkdir -p Saranera/Views/Library
```

Then use a Ruby script to add files to the Xcode project, or manually add them via `xcodebuild`. The simplest approach: use `xed .` to open Xcode and drag files in, OR use the PBXProj manipulation approach. For automation, ensure new Swift files are placed in the correct directories and referenced in the project.

**Step 7: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20`
Expected: All 8 SoundModelTests PASS.

**Step 8: Commit**

```bash
git add Saranera/Models/ SaraneraTests/SoundModelTests.swift
git commit -m "feat: add Sound, SoundCategory, and SoundMix models with tests"
```

---

## Task 2: AudioManager — Core State and Play/Stop

**Files:**
- Create: `Saranera/ViewModels/AudioManager.swift`
- Create: `SaraneraTests/AudioManagerTests.swift`

**Step 1: Write the failing tests**

Create `SaraneraTests/AudioManagerTests.swift`:

```swift
import Testing
@testable import Saranera

struct AudioManagerTests {

    // Helper: get a fresh AudioManager for each test
    private func makeManager() -> AudioManager {
        AudioManager()
    }

    private var rain: Sound {
        Sound.catalog.first { $0.id == "rain" }!
    }

    private var thunder: Sound {
        Sound.catalog.first { $0.id == "thunder" }!
    }

    private var forest: Sound {
        Sound.catalog.first { $0.id == "forest" }!
    }

    private var ocean: Sound {
        Sound.catalog.first { $0.id == "ocean_waves" }!
    }

    // MARK: - Play / Stop

    @Test func playAddsToActiveSounds() async {
        let manager = makeManager()
        manager.play(sound: rain)
        #expect(manager.isActive(rain))
        #expect(manager.isPlaying)
        #expect(manager.activeSoundIDs.count == 1)
    }

    @Test func stopRemovesFromActiveSounds() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.stop(sound: rain)
        #expect(!manager.isActive(rain))
        #expect(!manager.isPlaying)
        #expect(manager.activeSoundIDs.isEmpty)
    }

    @Test func playingActiveSoundTogglesIt() async {
        let manager = makeManager()
        manager.play(sound: rain)
        #expect(manager.isActive(rain))
        manager.play(sound: rain)
        #expect(!manager.isActive(rain))
    }

    // MARK: - Max Simultaneous

    @Test func maxThreeSimultaneousSounds() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.play(sound: thunder)
        manager.play(sound: forest)
        #expect(manager.activeSoundIDs.count == 3)

        // 4th sound should be rejected
        manager.play(sound: ocean)
        #expect(manager.activeSoundIDs.count == 3)
        #expect(!manager.isActive(ocean))
    }

    // MARK: - Stop All

    @Test func stopAllClearsEverything() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.play(sound: thunder)
        manager.play(sound: forest)
        manager.stopAll()
        #expect(manager.activeSoundIDs.isEmpty)
        #expect(!manager.isPlaying)
    }

    // MARK: - Volume

    @Test func setVolumeUpdatesState() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.setVolume(for: rain, to: 0.5)
        #expect(manager.volume(for: rain) == 0.5)
    }

    @Test func setVolumeClampsToRange() async {
        let manager = makeManager()
        manager.play(sound: rain)
        manager.setVolume(for: rain, to: 1.5)
        #expect(manager.volume(for: rain) == 1.0)
        manager.setVolume(for: rain, to: -0.5)
        #expect(manager.volume(for: rain) == 0.0)
    }

    // MARK: - isActive

    @Test func isActiveReturnsCorrectState() async {
        let manager = makeManager()
        #expect(!manager.isActive(rain))
        manager.play(sound: rain)
        #expect(manager.isActive(rain))
        manager.stop(sound: rain)
        #expect(!manager.isActive(rain))
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20`
Expected: Build failure — `AudioManager` not defined.

**Step 3: Implement AudioManager**

Create `Saranera/ViewModels/AudioManager.swift`:

```swift
import AVFoundation
import Observation

@Observable
final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Public State

    private(set) var activeSoundIDs: Set<String> = []
    let maxSimultaneous = 3

    var isPlaying: Bool {
        !activeSoundIDs.isEmpty
    }

    // MARK: - Internal State

    struct ActiveSound {
        let node: AVAudioPlayerNode
        var volume: Float
        let buffer: AVAudioPCMBuffer
    }

    private var activeSounds: [String: ActiveSound] = [:]
    private let engine = AVAudioEngine()
    private var isEngineRunning = false

    // MARK: - Frequency mapping for test tones

    private static let frequencyMap: [String: Float] = [
        "rain": 261.63,         // C4
        "thunder": 293.66,      // D4
        "forest": 329.63,       // E4
        "ocean_waves": 349.23,  // F4
        "white_noise": 392.00,  // G4
        "brown_noise": 440.00,  // A4
        "pink_noise": 493.88,   // B4
        "fireplace": 523.25,    // C5
        "wind": 587.33,         // D5
        "night_crickets": 659.25, // E5
        "coffee_shop": 698.46,  // F5
        "library_ambience": 783.99, // G5
    ]

    // MARK: - Init

    init() {
        configureAudioSession()
        observeInterruptions()
    }

    // MARK: - Public API

    func play(sound: Sound) {
        // Toggle: if already playing, stop it
        if activeSounds[sound.id] != nil {
            stop(sound: sound)
            return
        }

        // Reject if at max capacity
        guard activeSounds.count < maxSimultaneous else { return }

        do {
            try startEngineIfNeeded()

            let node = AVAudioPlayerNode()
            engine.attach(node)

            let format = engine.mainMixerNode.outputFormat(forBus: 0)
            engine.connect(node, to: engine.mainMixerNode, format: format)

            let frequency = Self.frequencyMap[sound.id] ?? 440.0
            let buffer = generateTestToneBuffer(frequency: frequency, duration: 2.0, format: format)

            node.scheduleBuffer(buffer, at: nil, options: .loops)
            node.volume = 1.0
            node.play()

            activeSounds[sound.id] = ActiveSound(node: node, volume: 1.0, buffer: buffer)
            activeSoundIDs.insert(sound.id)
        } catch {
            print("AudioManager: Failed to play sound \(sound.id): \(error)")
        }
    }

    func stop(sound: Sound) {
        guard let activeSound = activeSounds[sound.id] else { return }
        activeSound.node.stop()
        engine.detach(activeSound.node)
        activeSounds.removeValue(forKey: sound.id)
        activeSoundIDs.remove(sound.id)

        if activeSounds.isEmpty {
            engine.stop()
            isEngineRunning = false
        }
    }

    func stopAll() {
        let soundIDs = Array(activeSounds.keys)
        for id in soundIDs {
            if let sound = Sound.catalog.first(where: { $0.id == id }) {
                stop(sound: sound)
            }
        }
    }

    func setVolume(for sound: Sound, to volume: Float) {
        guard var activeSound = activeSounds[sound.id] else { return }
        let clampedVolume = min(max(volume, 0.0), 1.0)
        activeSound.volume = clampedVolume
        activeSound.node.volume = clampedVolume
        activeSounds[sound.id] = activeSound
    }

    func volume(for sound: Sound) -> Float {
        activeSounds[sound.id]?.volume ?? 0.0
    }

    func isActive(_ sound: Sound) -> Bool {
        activeSounds[sound.id] != nil
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("AudioManager: Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Engine

    private func startEngineIfNeeded() throws {
        guard !isEngineRunning else { return }
        try engine.start()
        isEngineRunning = true
    }

    // MARK: - Interruption Handling

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            engine.pause()
            isEngineRunning = false
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                do {
                    try engine.start()
                    isEngineRunning = true
                    // Re-play all active sounds
                    for (_, activeSound) in activeSounds {
                        activeSound.node.scheduleBuffer(activeSound.buffer, at: nil, options: .loops)
                        activeSound.node.play()
                    }
                } catch {
                    print("AudioManager: Failed to resume after interruption: \(error)")
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Test Tone Generation

    private func generateTestToneBuffer(frequency: Float, duration: TimeInterval, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(sampleRate * Float(duration))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = Int(format.channelCount)
        let omega = 2.0 * Float.pi * frequency / sampleRate

        for channel in 0..<channels {
            let channelData = buffer.floatChannelData![channel]
            for frame in 0..<Int(frameCount) {
                channelData[frame] = 0.3 * sin(omega * Float(frame))
            }
        }

        return buffer
    }
}
```

**Step 4: Add AudioManager.swift to Xcode project (Saranera target) and AudioManagerTests.swift to SaraneraTests target**

**Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20`
Expected: All 8 AudioManagerTests PASS.

**Step 6: Commit**

```bash
git add Saranera/ViewModels/AudioManager.swift SaraneraTests/AudioManagerTests.swift
git commit -m "feat: add AudioManager with AVAudioEngine, test tones, and play/stop/volume control"
```

---

## Task 3: Tab Navigation and Placeholder Views

**Files:**
- Modify: `Saranera/SaraneraApp.swift`
- Modify: `Saranera/ContentView.swift`
- Create: `Saranera/Views/Focus/FocusView.swift`
- Create: `Saranera/Views/Sleep/SleepView.swift`

**Step 1: Create FocusView placeholder**

Create `Saranera/Views/Focus/FocusView.swift`:

```swift
import SwiftUI

struct FocusView: View {
    var body: some View {
        ZStack {
            Color(red: 0.051, green: 0.106, blue: 0.165) // Deep Navy #0D1B2A
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835)) // Soft Blue #5B9BD5

                Text("Focus")
                    .font(.system(.largeTitle, design: .rounded, weight: .light))
                    .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
            }
        }
    }
}

#Preview {
    FocusView()
}
```

**Step 2: Create SleepView placeholder**

Create `Saranera/Views/Sleep/SleepView.swift`:

```swift
import SwiftUI

struct SleepView: View {
    var body: some View {
        ZStack {
            Color(red: 0.051, green: 0.106, blue: 0.165) // Deep Navy #0D1B2A
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835)) // Soft Blue #5B9BD5

                Text("Sleep")
                    .font(.system(.largeTitle, design: .rounded, weight: .light))
                    .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
            }
        }
    }
}

#Preview {
    SleepView()
}
```

**Step 3: Replace ContentView with TabView**

Modify `Saranera/ContentView.swift` — replace entire contents:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Focus", systemImage: "brain.head.profile") {
                FocusView()
            }

            Tab("Sleep", systemImage: "moon.stars") {
                SleepView()
            }

            Tab("Library", systemImage: "square.grid.2x2") {
                LibraryView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AudioManager.shared)
}
```

**Step 4: Update SaraneraApp to inject AudioManager**

Modify `Saranera/SaraneraApp.swift` — replace entire contents:

```swift
import SwiftUI

@main
struct SaraneraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
        }
    }
}
```

**Step 5: Create a stub LibraryView (will be fully built in Task 4)**

Create `Saranera/Views/Library/LibraryView.swift`:

```swift
import SwiftUI

struct LibraryView: View {
    var body: some View {
        ZStack {
            Color(red: 0.051, green: 0.106, blue: 0.165)
                .ignoresSafeArea()

            Text("Library")
                .font(.system(.largeTitle, design: .rounded, weight: .light))
                .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
        }
    }
}

#Preview {
    LibraryView()
        .environment(AudioManager.shared)
}
```

**Step 6: Add all new view files to Xcode project (Saranera target)**

**Step 7: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 8: Run all tests to verify nothing broke**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20`
Expected: All previous tests still PASS.

**Step 9: Commit**

```bash
git add Saranera/SaraneraApp.swift Saranera/ContentView.swift Saranera/Views/
git commit -m "feat: add TabView navigation with Focus, Sleep, and Library tabs"
```

---

## Task 4: Library View with Sound List

**Files:**
- Modify: `Saranera/Views/Library/LibraryView.swift`
- Create: `Saranera/Views/Library/SoundRowView.swift`

**Step 1: Create SoundRowView**

Create `Saranera/Views/Library/SoundRowView.swift`:

```swift
import SwiftUI

struct SoundRowView: View {
    let sound: Sound
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sound.iconName)
                .font(.title3)
                .foregroundStyle(isActive ? Color(red: 0.957, green: 0.635, blue: 0.380) : .secondary) // Amber #F4A261 when active
                .frame(width: 32)

            Text(sound.name)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            if isActive {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.957, green: 0.635, blue: 0.380)) // Amber
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .animation(.spring(duration: 0.3), value: isActive)
    }
}

#Preview {
    VStack {
        SoundRowView(sound: Sound.catalog[0], isActive: false)
        SoundRowView(sound: Sound.catalog[0], isActive: true)
    }
    .padding()
}
```

**Step 2: Implement full LibraryView**

Replace `Saranera/Views/Library/LibraryView.swift` with:

```swift
import SwiftUI

struct LibraryView: View {
    @Environment(AudioManager.self) private var audioManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(SoundCategory.allCases, id: \.self) { category in
                    Section {
                        let sounds = Sound.grouped[category] ?? []
                        ForEach(sounds) { sound in
                            SoundRowView(
                                sound: sound,
                                isActive: audioManager.isActive(sound)
                            )
                            .onTapGesture {
                                audioManager.play(sound: sound)
                            }
                        }
                    } header: {
                        Label(category.displayName, systemImage: category.iconName)
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .navigationTitle("Library")
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea()) // Deep Navy
        }
    }
}

#Preview {
    LibraryView()
        .environment(AudioManager.shared)
}
```

**Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Run all tests to verify nothing broke**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -20`
Expected: All tests still PASS.

**Step 5: Commit**

```bash
git add Saranera/Views/Library/
git commit -m "feat: add Library view with sounds grouped by category and play toggle"
```

---

## Task 5: Final Integration and Cleanup

**Files:**
- Modify: `SaraneraTests/SaraneraTests.swift` (clean up placeholder)
- Review: all files for compilation and test pass

**Step 1: Clean up the placeholder test file**

Replace `SaraneraTests/SaraneraTests.swift` contents with:

```swift
import Testing
@testable import Saranera

// All tests organized in dedicated test files:
// - SoundModelTests.swift
// - AudioManagerTests.swift
```

**Step 2: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -30`
Expected: All 16 tests PASS (8 SoundModelTests + 8 AudioManagerTests).

**Step 3: Run full build**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add SaraneraTests/SaraneraTests.swift
git commit -m "chore: clean up placeholder test file"
```

---

## Summary

| Task | What | Files | Tests |
|------|------|-------|-------|
| 1 | Sound Models | 3 create + 1 test | 8 tests |
| 2 | AudioManager | 1 create + 1 test | 8 tests |
| 3 | Tab Navigation + Placeholders | 2 modify + 3 create | Build check |
| 4 | Library View | 1 modify + 1 create | Build check |
| 5 | Cleanup | 1 modify | Full suite |

**Total: 11 files changed/created, 16 tests**
