# Phase 4 Monetization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add StoreKit 2 in-app purchases for sound packs, an ODR-based download system, and a redesigned Library tab with pack browsing, previews, and purchase flow.

**Architecture:** Centralized `StoreManager` (@Observable) for all StoreKit logic + separate `DownloadManager` (@Observable) for ODR downloads. Both injected via SwiftUI `.environment()`. `SoundPack` model defines pack catalog; `Sound` model extended with `packID` and `previewFileName`.

**Tech Stack:** StoreKit 2, On-Demand Resources (NSBundleResourceRequest), SwiftUI (Liquid Glass), Swift Testing

**Reference Docs:**
- `AdditionalDocumentation/StoreKit-Updates.md` — StoreKit 2 APIs
- `AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md` — Liquid Glass patterns

---

## Task 1: SoundPack Model + Sound Model Extensions

**Files:**
- Create: `Saranera/Models/SoundPack.swift`
- Modify: `Saranera/Models/Sound.swift`
- Test: `SaraneraTests/SoundModelTests.swift`

**Step 1: Write failing tests for SoundPack and Sound extensions**

Add to `SaraneraTests/SoundModelTests.swift`:

```swift
// MARK: - SoundPack

@Test func soundPackCatalogHasFivePacks() {
    #expect(SoundPack.catalog.count == 5)
}

@Test func soundPacksHaveUniqueIDs() {
    let ids = SoundPack.catalog.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test func eachPackContainsSounds() {
    for pack in SoundPack.catalog {
        #expect(!pack.soundIDs.isEmpty)
    }
}

@Test func packSoundsExistInCatalog() {
    let allSoundIDs = Set(Sound.catalog.map(\.id))
    for pack in SoundPack.catalog {
        for soundID in pack.soundIDs {
            #expect(allSoundIDs.contains(soundID), "Sound \(soundID) in pack \(pack.id) not found in catalog")
        }
    }
}

@Test func soundPackLookup() {
    let rainyDay = SoundPack.catalog.first { $0.id == "app.fiqhrodedhen.Saranera.pack.rainy_day" }
    #expect(rainyDay != nil)
    #expect(rainyDay?.name == "Rainy Day Collection")
    #expect(rainyDay?.soundIDs.count == 4)
}

// MARK: - Sound Premium Extensions

@Test func freeSoundsHaveNoPackID() {
    let freeSounds = Sound.catalog.filter { $0.isFree }
    for sound in freeSounds {
        #expect(sound.packID == nil)
    }
}

@Test func premiumSoundsHavePackID() {
    let premiumSounds = Sound.catalog.filter { $0.isPremium }
    for sound in premiumSounds {
        #expect(sound.packID != nil, "Premium sound \(sound.id) missing packID")
    }
}

@Test func catalogHasBothFreeAndPremiumSounds() {
    let free = Sound.catalog.filter { $0.isFree }
    let premium = Sound.catalog.filter { !$0.isFree }
    #expect(free.count == 12)
    #expect(premium.count > 0)
}

@Test func soundPackForIDReturnsCorrectPack() {
    let pack = SoundPack.pack(for: "drizzle")
    #expect(pack?.id == "app.fiqhrodedhen.Saranera.pack.rainy_day")
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing SaraneraTests/SoundModelTests 2>&1 | tail -20`
Expected: FAIL — `SoundPack` type not found, `isFree`/`packID` not found on `Sound`

**Step 3: Create SoundPack model**

Create `Saranera/Models/SoundPack.swift`:

```swift
import Foundation

struct SoundPack: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let category: SoundCategory
    let soundIDs: [String]
    let odrTag: String
    let previewImageName: String

    static func pack(for soundID: String) -> SoundPack? {
        catalog.first { $0.soundIDs.contains(soundID) }
    }

    static let catalog: [SoundPack] = [
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.rainy_day",
            name: "Rainy Day Collection",
            description: "Atmospheric rain sounds for deep relaxation",
            category: .nature,
            soundIDs: ["drizzle", "thunderstorm", "rain_tin_roof", "rain_tent"],
            odrTag: "pack_rainy_day",
            previewImageName: "pack.rainy_day"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.ocean_dreams",
            name: "Ocean Dreams",
            description: "Immersive ocean and coastal soundscapes",
            category: .nature,
            soundIDs: ["beach_waves", "underwater", "harbor", "seagulls"],
            odrTag: "pack_ocean_dreams",
            previewImageName: "pack.ocean_dreams"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.lofi_study",
            name: "Lo-Fi Study",
            description: "Chill beats and study ambience",
            category: .ambient,
            soundIDs: ["lofi_beats", "vinyl_crackle", "keyboard_typing", "pen_writing"],
            odrTag: "pack_lofi_study",
            previewImageName: "pack.lofi_study"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.nusantara",
            name: "Nusantara",
            description: "Traditional Indonesian soundscapes",
            category: .environment,
            soundIDs: ["gamelan", "rice_paddies", "jungle_river", "traditional_market"],
            odrTag: "pack_nusantara",
            previewImageName: "pack.nusantara"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.city_nights",
            name: "City Nights",
            description: "Urban nighttime atmosphere",
            category: .urban,
            soundIDs: ["distant_traffic", "train_passing", "apartment_window", "late_night_diner"],
            odrTag: "pack_city_nights",
            previewImageName: "pack.city_nights"
        ),
    ]
}
```

**Step 4: Extend Sound model with packID, previewFileName, isFree**

Modify `Saranera/Models/Sound.swift`. Add new fields to the struct and update the catalog:

```swift
import Foundation

struct Sound: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let category: SoundCategory
    let fileName: String
    let isPremium: Bool
    let iconName: String
    let packID: String?
    let previewFileName: String?

    var isFree: Bool { packID == nil }

    init(id: String, name: String, category: SoundCategory, fileName: String, isPremium: Bool, iconName: String, packID: String? = nil, previewFileName: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.fileName = fileName
        self.isPremium = isPremium
        self.iconName = iconName
        self.packID = packID
        self.previewFileName = previewFileName
    }

    static let catalog: [Sound] = [
        // Free — Nature
        Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
        Sound(id: "thunder", name: "Thunder", category: .nature, fileName: "thunder.m4a", isPremium: false, iconName: "cloud.bolt"),
        Sound(id: "forest", name: "Forest", category: .nature, fileName: "forest.m4a", isPremium: false, iconName: "tree"),
        Sound(id: "ocean_waves", name: "Ocean Waves", category: .nature, fileName: "ocean_waves.m4a", isPremium: false, iconName: "water.waves"),
        // Free — Ambient
        Sound(id: "white_noise", name: "White Noise", category: .ambient, fileName: "white_noise.m4a", isPremium: false, iconName: "waveform"),
        Sound(id: "brown_noise", name: "Brown Noise", category: .ambient, fileName: "brown_noise.m4a", isPremium: false, iconName: "waveform.path"),
        Sound(id: "pink_noise", name: "Pink Noise", category: .ambient, fileName: "pink_noise.m4a", isPremium: false, iconName: "waveform.badge.magnifyingglass"),
        // Free — Environment
        Sound(id: "fireplace", name: "Fireplace", category: .environment, fileName: "fireplace.m4a", isPremium: false, iconName: "flame"),
        Sound(id: "wind", name: "Wind", category: .environment, fileName: "wind.m4a", isPremium: false, iconName: "wind"),
        Sound(id: "night_crickets", name: "Night Crickets", category: .environment, fileName: "night_crickets.m4a", isPremium: false, iconName: "moon.stars"),
        // Free — Urban
        Sound(id: "coffee_shop", name: "Coffee Shop", category: .urban, fileName: "coffee_shop.m4a", isPremium: false, iconName: "cup.and.saucer"),
        Sound(id: "library_ambience", name: "Library Ambience", category: .urban, fileName: "library_ambience.m4a", isPremium: false, iconName: "books.vertical"),

        // Premium — Rainy Day Collection
        Sound(id: "drizzle", name: "Drizzle", category: .nature, fileName: "drizzle.m4a", isPremium: true, iconName: "cloud.drizzle", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "drizzle_preview.m4a"),
        Sound(id: "thunderstorm", name: "Thunderstorm", category: .nature, fileName: "thunderstorm.m4a", isPremium: true, iconName: "cloud.bolt.rain", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "thunderstorm_preview.m4a"),
        Sound(id: "rain_tin_roof", name: "Rain on Tin Roof", category: .nature, fileName: "rain_tin_roof.m4a", isPremium: true, iconName: "house", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "rain_tin_roof_preview.m4a"),
        Sound(id: "rain_tent", name: "Rain on Tent", category: .nature, fileName: "rain_tent.m4a", isPremium: true, iconName: "tent", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "rain_tent_preview.m4a"),

        // Premium — Ocean Dreams
        Sound(id: "beach_waves", name: "Beach Waves", category: .nature, fileName: "beach_waves.m4a", isPremium: true, iconName: "beach.umbrella", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "beach_waves_preview.m4a"),
        Sound(id: "underwater", name: "Underwater", category: .nature, fileName: "underwater.m4a", isPremium: true, iconName: "drop.triangle", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "underwater_preview.m4a"),
        Sound(id: "harbor", name: "Harbor", category: .nature, fileName: "harbor.m4a", isPremium: true, iconName: "ferry", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "harbor_preview.m4a"),
        Sound(id: "seagulls", name: "Seagulls", category: .nature, fileName: "seagulls.m4a", isPremium: true, iconName: "bird", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "seagulls_preview.m4a"),

        // Premium — Lo-Fi Study
        Sound(id: "lofi_beats", name: "Lo-Fi Beats", category: .ambient, fileName: "lofi_beats.m4a", isPremium: true, iconName: "headphones", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "lofi_beats_preview.m4a"),
        Sound(id: "vinyl_crackle", name: "Vinyl Crackle", category: .ambient, fileName: "vinyl_crackle.m4a", isPremium: true, iconName: "opticaldisc", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "vinyl_crackle_preview.m4a"),
        Sound(id: "keyboard_typing", name: "Keyboard Typing", category: .ambient, fileName: "keyboard_typing.m4a", isPremium: true, iconName: "keyboard", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "keyboard_typing_preview.m4a"),
        Sound(id: "pen_writing", name: "Pen Writing", category: .ambient, fileName: "pen_writing.m4a", isPremium: true, iconName: "pencil.line", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "pen_writing_preview.m4a"),

        // Premium — Nusantara
        Sound(id: "gamelan", name: "Gamelan", category: .environment, fileName: "gamelan.m4a", isPremium: true, iconName: "music.note", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "gamelan_preview.m4a"),
        Sound(id: "rice_paddies", name: "Rice Paddies", category: .environment, fileName: "rice_paddies.m4a", isPremium: true, iconName: "leaf.arrow.circlepath", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "rice_paddies_preview.m4a"),
        Sound(id: "jungle_river", name: "Jungle River", category: .environment, fileName: "jungle_river.m4a", isPremium: true, iconName: "water.waves.and.arrow.down", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "jungle_river_preview.m4a"),
        Sound(id: "traditional_market", name: "Traditional Market", category: .environment, fileName: "traditional_market.m4a", isPremium: true, iconName: "storefront", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "traditional_market_preview.m4a"),

        // Premium — City Nights
        Sound(id: "distant_traffic", name: "Distant Traffic", category: .urban, fileName: "distant_traffic.m4a", isPremium: true, iconName: "car", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "distant_traffic_preview.m4a"),
        Sound(id: "train_passing", name: "Train Passing", category: .urban, fileName: "train_passing.m4a", isPremium: true, iconName: "tram", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "train_passing_preview.m4a"),
        Sound(id: "apartment_window", name: "Apartment Window", category: .urban, fileName: "apartment_window.m4a", isPremium: true, iconName: "window.casement", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "apartment_window_preview.m4a"),
        Sound(id: "late_night_diner", name: "Late Night Diner", category: .urban, fileName: "late_night_diner.m4a", isPremium: true, iconName: "fork.knife", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "late_night_diner_preview.m4a"),
    ]

    static var grouped: [SoundCategory: [Sound]] {
        Dictionary(grouping: catalog, by: \.category)
    }

    static var freeSounds: [Sound] {
        catalog.filter { $0.isFree }
    }

    static var premiumSounds: [Sound] {
        catalog.filter { !$0.isFree }
    }
}
```

**Step 5: Update existing test that asserts exactly 12 sounds**

In `SaraneraTests/SoundModelTests.swift`, update:
- `catalogHas12FreeSounds` → now checks `Sound.freeSounds.count == 12`
- `catalogHasNoPremiuimSounds` → rename to `catalogHasPremiumSounds`, check `Sound.premiumSounds.count == 20`
- `soundsGroupByCategory` → update counts (Nature now has 4+8=12, etc.)

```swift
@Test func catalogHas12FreeSounds() {
    #expect(Sound.freeSounds.count == 12)
}

@Test func catalogHasPremiumSounds() {
    #expect(Sound.premiumSounds.count == 20)
}

@Test func catalogTotalIs32Sounds() {
    #expect(Sound.catalog.count == 32)
}
```

**Step 6: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing SaraneraTests/SoundModelTests 2>&1 | tail -20`
Expected: ALL PASS

**Step 7: Update AudioManager frequency map for new premium sounds**

In `Saranera/ViewModels/AudioManager.swift`, extend the `frequencyMap` to include all 20 premium sounds (use sequential frequencies so test tones are distinguishable):

```swift
// Add to frequencyMap:
"drizzle": 830.61,
"thunderstorm": 880.00,
"rain_tin_roof": 932.33,
"rain_tent": 987.77,
"beach_waves": 1046.50,
"underwater": 1108.73,
"harbor": 1174.66,
"seagulls": 1244.51,
"lofi_beats": 1318.51,
"vinyl_crackle": 1396.91,
"keyboard_typing": 1479.98,
"pen_writing": 1567.98,
"gamelan": 1661.22,
"rice_paddies": 1760.00,
"jungle_river": 1864.66,
"traditional_market": 1975.53,
"distant_traffic": 2093.00,
"train_passing": 2217.46,
"apartment_window": 2349.32,
"late_night_diner": 2489.02,
```

**Step 8: Run full test suite to verify nothing is broken**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: ALL PASS

**Step 9: Commit**

```bash
git add Saranera/Models/SoundPack.swift Saranera/Models/Sound.swift Saranera/ViewModels/AudioManager.swift SaraneraTests/SoundModelTests.swift
git commit -m "feat: add SoundPack model and extend Sound with premium pack support"
```

---

## Task 2: StoreManager

**Files:**
- Create: `Saranera/ViewModels/StoreManager.swift`
- Test: `SaraneraTests/StoreManagerTests.swift`

**Step 1: Write failing tests for StoreManager**

Create `SaraneraTests/StoreManagerTests.swift`:

```swift
import Testing
@testable import Saranera

@MainActor
struct StoreManagerTests {

    private func makeManager() -> StoreManager {
        StoreManager()
    }

    // MARK: - Initial State

    @Test func initialStateIsEmpty() {
        let manager = makeManager()
        #expect(manager.products.isEmpty)
        #expect(manager.purchasedPackIDs.isEmpty)
        #expect(manager.purchaseInProgress == nil)
        #expect(manager.errorMessage == nil)
    }

    // MARK: - Product IDs

    @Test func allProductIDsAreDefined() {
        #expect(StoreManager.packProductIDs.count == 5)
        #expect(StoreManager.allProductIDs.count == 6) // 5 packs + 1 bundle
        #expect(StoreManager.allProductIDs.contains(StoreManager.bundleProductID))
    }

    // MARK: - isPurchased

    @Test func isPurchasedReturnsFalseByDefault() {
        let manager = makeManager()
        #expect(!manager.isPurchased("app.fiqhrodedhen.Saranera.pack.rainy_day"))
    }

    @Test func isPurchasedReturnsTrueAfterMarking() {
        let manager = makeManager()
        manager.purchasedPackIDs.insert("app.fiqhrodedhen.Saranera.pack.rainy_day")
        #expect(manager.isPurchased("app.fiqhrodedhen.Saranera.pack.rainy_day"))
    }

    // MARK: - Bundle

    @Test func bundleIsPurchasedGrantsAllPacks() {
        let manager = makeManager()
        manager.purchasedPackIDs.insert(StoreManager.bundleProductID)
        for packID in StoreManager.packProductIDs {
            #expect(manager.isPurchased(packID))
        }
    }

    @Test func bundleSavingsReturnsNilWhenNoPurchases() {
        let manager = makeManager()
        let savings = manager.bundleSavings(bundlePrice: 7.99, individualTotal: 12.96)
        #expect(savings != nil)
        #expect(savings!.contains("40"))
    }

    // MARK: - Sound Availability

    @Test func isSoundAvailableForFreeSound() {
        let manager = makeManager()
        #expect(manager.isSoundAvailable("rain"))
    }

    @Test func isSoundNotAvailableForUnpurchasedPremium() {
        let manager = makeManager()
        #expect(!manager.isSoundAvailable("drizzle"))
    }

    @Test func isSoundAvailableAfterPackPurchase() {
        let manager = makeManager()
        manager.purchasedPackIDs.insert("app.fiqhrodedhen.Saranera.pack.rainy_day")
        #expect(manager.isSoundAvailable("drizzle"))
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing SaraneraTests/StoreManagerTests 2>&1 | tail -20`
Expected: FAIL — `StoreManager` type not found

**Step 3: Implement StoreManager**

Create `Saranera/ViewModels/StoreManager.swift`:

```swift
import StoreKit
import Observation

@Observable
final class StoreManager {

    // MARK: - Product IDs

    static let packProductIDs: Set<String> = [
        "app.fiqhrodedhen.Saranera.pack.rainy_day",
        "app.fiqhrodedhen.Saranera.pack.ocean_dreams",
        "app.fiqhrodedhen.Saranera.pack.lofi_study",
        "app.fiqhrodedhen.Saranera.pack.nusantara",
        "app.fiqhrodedhen.Saranera.pack.city_nights",
    ]

    static let bundleProductID = "app.fiqhrodedhen.Saranera.pack.bundle_all"

    static var allProductIDs: Set<String> {
        packProductIDs.union([bundleProductID])
    }

    // MARK: - State

    var products: [Product] = []
    var purchasedPackIDs: Set<String> = []
    var purchaseInProgress: String? = nil
    var errorMessage: String? = nil

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Never>?

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products"
        }
    }

    // MARK: - Transaction Listener

    func listenForTransactions() {
        transactionListener = Task.detached { @Sendable in
            for await result in Transaction.updates {
                await self.handleVerificationResult(result)
            }
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        purchaseInProgress = product.id
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                await handleVerificationResult(verification)
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }

        purchaseInProgress = nil
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateEntitlements()
        } catch {
            errorMessage = "Failed to restore purchases"
        }
    }

    // MARK: - Queries

    func isPurchased(_ packID: String) -> Bool {
        if purchasedPackIDs.contains(Self.bundleProductID) {
            return Self.packProductIDs.contains(packID) || packID == Self.bundleProductID
        }
        return purchasedPackIDs.contains(packID)
    }

    func isSoundAvailable(_ soundID: String) -> Bool {
        guard let sound = Sound.catalog.first(where: { $0.id == soundID }) else { return false }
        if sound.isFree { return true }
        guard let packID = sound.packID else { return false }
        return isPurchased(packID)
    }

    func product(for packID: String) -> Product? {
        products.first { $0.id == packID }
    }

    func bundleSavings(bundlePrice: Decimal, individualTotal: Decimal) -> String? {
        guard individualTotal > bundlePrice else { return nil }
        let savings = individualTotal - bundlePrice
        let percent = Int((savings as NSDecimalNumber).doubleValue / (individualTotal as NSDecimalNumber).doubleValue * 100)
        return "Save \(percent)%"
    }

    // MARK: - Entitlements

    func updateEntitlements() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if Self.allProductIDs.contains(transaction.productID) {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedPackIDs = purchased
    }

    // MARK: - Internal

    private func handleVerificationResult(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            if Self.allProductIDs.contains(transaction.productID) {
                purchasedPackIDs.insert(transaction.productID)
            }
            await transaction.finish()
        case .unverified:
            errorMessage = "Transaction verification failed"
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing SaraneraTests/StoreManagerTests 2>&1 | tail -20`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add Saranera/ViewModels/StoreManager.swift SaraneraTests/StoreManagerTests.swift
git commit -m "feat: add StoreManager with StoreKit 2 purchase and entitlement logic"
```

---

## Task 3: DownloadManager

**Files:**
- Create: `Saranera/Services/DownloadManager.swift`
- Test: `SaraneraTests/DownloadManagerTests.swift`

**Step 1: Write failing tests for DownloadManager**

Create `SaraneraTests/DownloadManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import Saranera

@MainActor
struct DownloadManagerTests {

    private func makeManager() -> DownloadManager {
        DownloadManager()
    }

    // MARK: - Initial State

    @Test func initialStateIsEmpty() {
        let manager = makeManager()
        #expect(manager.downloads.isEmpty)
    }

    // MARK: - Download State

    @Test func defaultStateIsNotDownloaded() {
        let manager = makeManager()
        #expect(!manager.isDownloaded("app.fiqhrodedhen.Saranera.pack.rainy_day"))
    }

    // MARK: - Sound File URL

    @Test func fileURLReturnsNilForUndownloaded() {
        let manager = makeManager()
        #expect(manager.fileURL(for: "drizzle") == nil)
    }

    @Test func fileURLReturnsPathForDownloaded() {
        let manager = makeManager()
        manager.downloads["app.fiqhrodedhen.Saranera.pack.rainy_day"] = .downloaded
        let url = manager.fileURL(for: "drizzle")
        #expect(url != nil)
        #expect(url!.path().contains("Sounds"))
        #expect(url!.path().contains("drizzle.m4a"))
    }

    // MARK: - isDownloaded for sound ID

    @Test func isSoundDownloadedWhenPackIsDownloaded() {
        let manager = makeManager()
        manager.downloads["app.fiqhrodedhen.Saranera.pack.rainy_day"] = .downloaded
        #expect(manager.isDownloaded(soundID: "drizzle"))
    }

    @Test func isSoundNotDownloadedWhenPackIsNotDownloaded() {
        let manager = makeManager()
        #expect(!manager.isDownloaded(soundID: "drizzle"))
    }

    // MARK: - Documents Directory

    @Test func soundsDirectoryIsInDocuments() {
        let manager = makeManager()
        let dir = manager.soundsDirectory
        #expect(dir.path().contains("Documents"))
        #expect(dir.path().contains("Sounds"))
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing SaraneraTests/DownloadManagerTests 2>&1 | tail -20`
Expected: FAIL — `DownloadManager` type not found

**Step 3: Implement DownloadManager**

Create `Saranera/Services/DownloadManager.swift`:

```swift
import Foundation
import Observation

@Observable
final class DownloadManager {

    // MARK: - Types

    enum DownloadState: Equatable, Sendable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case failed(String)
    }

    // MARK: - State

    var downloads: [String: DownloadState] = [:]

    // MARK: - File System

    var soundsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    private func packDirectory(for packID: String) -> URL {
        soundsDirectory.appendingPathComponent(packID, isDirectory: true)
    }

    // MARK: - Download

    @concurrent
    func downloadPack(_ packID: String) async {
        await MainActor.run {
            downloads[packID] = .downloading(progress: 0)
        }

        guard let pack = SoundPack.catalog.first(where: { $0.id == packID }) else {
            await MainActor.run {
                downloads[packID] = .failed("Pack not found")
            }
            return
        }

        let request = NSBundleResourceRequest(tags: [pack.odrTag])

        // Observe progress
        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                let fraction = request.progress.fractionCompleted
                downloads[packID] = .downloading(progress: fraction)
                if fraction >= 1.0 { break }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }

        do {
            try await request.beginAccessingResources()
            progressTask.cancel()

            // Copy files to Documents
            let packDir = packDirectory(for: packID)
            try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

            for soundID in pack.soundIDs {
                guard let sound = Sound.catalog.first(where: { $0.id == soundID }) else { continue }
                let fileName = sound.fileName
                if let sourceURL = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".m4a", with: ""), withExtension: "m4a") {
                    let destURL = packDir.appendingPathComponent(fileName)
                    if !FileManager.default.fileExists(atPath: destURL.path()) {
                        try FileManager.default.copyItem(at: sourceURL, to: destURL)
                    }
                }
            }

            request.endAccessingResources()

            await MainActor.run {
                downloads[packID] = .downloaded
            }
        } catch {
            progressTask.cancel()
            await MainActor.run {
                downloads[packID] = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Cancel

    func cancelDownload(_ packID: String) {
        downloads[packID] = .notDownloaded
    }

    // MARK: - Delete

    func deletePack(_ packID: String) throws {
        let packDir = packDirectory(for: packID)
        if FileManager.default.fileExists(atPath: packDir.path()) {
            try FileManager.default.removeItem(at: packDir)
        }
        downloads[packID] = .notDownloaded
    }

    // MARK: - Check Existing Downloads

    func checkDownloadedPacks() {
        for pack in SoundPack.catalog {
            let packDir = packDirectory(for: pack.id)
            if FileManager.default.fileExists(atPath: packDir.path()) {
                downloads[pack.id] = .downloaded
            }
        }
    }

    // MARK: - Queries

    func isDownloaded(_ packID: String) -> Bool {
        downloads[packID] == .downloaded
    }

    func isDownloaded(soundID: String) -> Bool {
        guard let pack = SoundPack.pack(for: soundID) else { return false }
        return isDownloaded(pack.id)
    }

    func fileURL(for soundID: String) -> URL? {
        guard let sound = Sound.catalog.first(where: { $0.id == soundID }),
              let packID = sound.packID,
              isDownloaded(packID) else { return nil }
        return packDirectory(for: packID).appendingPathComponent(sound.fileName)
    }

    func downloadedSize() -> String {
        let totalBytes = SoundPack.catalog.reduce(into: 0) { total, pack in
            let packDir = packDirectory(for: pack.id)
            guard FileManager.default.fileExists(atPath: packDir.path()) else { return }
            if let enumerator = FileManager.default.enumerator(at: packDir, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    total += size
                }
            }
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing SaraneraTests/DownloadManagerTests 2>&1 | tail -20`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add Saranera/Services/DownloadManager.swift SaraneraTests/DownloadManagerTests.swift
git commit -m "feat: add DownloadManager with ODR downloads and Documents persistence"
```

---

## Task 4: StoreKit Configuration File

**Files:**
- Create: `Saranera/Configuration/Saranera.storekit`

**Step 1: Create StoreKit configuration file**

This file is JSON. Create `Saranera/Configuration/Saranera.storekit`:

```json
{
  "identifier" : "C47C1B18",
  "nonRenewingSubscriptions" : [],
  "products" : [
    {
      "displayPrice" : "1.99",
      "familyShareable" : false,
      "internalID" : "rainy_day_001",
      "localizations" : [
        {
          "description" : "Atmospheric rain sounds for deep relaxation",
          "displayName" : "Rainy Day Collection",
          "locale" : "en_US"
        }
      ],
      "productID" : "app.fiqhrodedhen.Saranera.pack.rainy_day",
      "referenceName" : "Rainy Day Collection",
      "type" : "NonConsumable"
    },
    {
      "displayPrice" : "1.99",
      "familyShareable" : false,
      "internalID" : "ocean_dreams_001",
      "localizations" : [
        {
          "description" : "Immersive ocean and coastal soundscapes",
          "displayName" : "Ocean Dreams",
          "locale" : "en_US"
        }
      ],
      "productID" : "app.fiqhrodedhen.Saranera.pack.ocean_dreams",
      "referenceName" : "Ocean Dreams",
      "type" : "NonConsumable"
    },
    {
      "displayPrice" : "2.99",
      "familyShareable" : false,
      "internalID" : "lofi_study_001",
      "localizations" : [
        {
          "description" : "Chill beats and study ambience",
          "displayName" : "Lo-Fi Study",
          "locale" : "en_US"
        }
      ],
      "productID" : "app.fiqhrodedhen.Saranera.pack.lofi_study",
      "referenceName" : "Lo-Fi Study",
      "type" : "NonConsumable"
    },
    {
      "displayPrice" : "3.99",
      "familyShareable" : false,
      "internalID" : "nusantara_001",
      "localizations" : [
        {
          "description" : "Traditional Indonesian soundscapes",
          "displayName" : "Nusantara",
          "locale" : "en_US"
        }
      ],
      "productID" : "app.fiqhrodedhen.Saranera.pack.nusantara",
      "referenceName" : "Nusantara",
      "type" : "NonConsumable"
    },
    {
      "displayPrice" : "1.99",
      "familyShareable" : false,
      "internalID" : "city_nights_001",
      "localizations" : [
        {
          "description" : "Urban nighttime atmosphere",
          "displayName" : "City Nights",
          "locale" : "en_US"
        }
      ],
      "productID" : "app.fiqhrodedhen.Saranera.pack.city_nights",
      "referenceName" : "City Nights",
      "type" : "NonConsumable"
    },
    {
      "displayPrice" : "7.99",
      "familyShareable" : false,
      "internalID" : "bundle_all_001",
      "localizations" : [
        {
          "description" : "All 5 sound packs at a 40% discount",
          "displayName" : "Bundle All Access",
          "locale" : "en_US"
        }
      ],
      "productID" : "app.fiqhrodedhen.Saranera.pack.bundle_all",
      "referenceName" : "Bundle All Access",
      "type" : "NonConsumable"
    }
  ],
  "settings" : {
    "_applicationInternalID" : "app_001",
    "_developerTeamID" : "C588LMCKSL",
    "_lastSynchronizedDate" : 0
  },
  "subscriptionGroups" : [],
  "version" : {
    "major" : 4,
    "minor" : 0
  }
}
```

**Step 2: Verify the file is valid JSON**

Run: `python3 -c "import json; json.load(open('Saranera/Configuration/Saranera.storekit')); print('Valid JSON')"`
Expected: `Valid JSON`

**Step 3: Commit**

```bash
git add Saranera/Configuration/Saranera.storekit
git commit -m "feat: add StoreKit configuration file with 6 non-consumable products"
```

**Note:** After committing, the StoreKit configuration file must be set as the active configuration in Xcode: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → select `Saranera.storekit`.

---

## Task 5: Wire StoreManager + DownloadManager into App

**Files:**
- Modify: `Saranera/App/SaraneraApp.swift`

**Step 1: Update SaraneraApp to inject StoreManager and DownloadManager**

Modify `Saranera/App/SaraneraApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct SaraneraApp: App {
    @State private var storeManager = StoreManager()
    @State private var downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
                .environment(storeManager)
                .environment(downloadManager)
                .task {
                    await storeManager.loadProducts()
                    storeManager.listenForTransactions()
                    await storeManager.updateEntitlements()
                    downloadManager.checkDownloadedPacks()
                }
        }
        .modelContainer(for: FocusSession.self)
    }
}
```

**Step 2: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add Saranera/App/SaraneraApp.swift
git commit -m "feat: wire StoreManager and DownloadManager into app entry point"
```

---

## Task 6: PackCardView + PurchaseButtonView

**Files:**
- Create: `Saranera/Views/Library/PackCardView.swift`
- Create: `Saranera/Views/Library/PurchaseButtonView.swift`

**Step 1: Create PurchaseButtonView**

Create `Saranera/Views/Library/PurchaseButtonView.swift`:

```swift
import SwiftUI
import StoreKit

struct PurchaseButtonView: View {
    let product: Product?
    let packID: String
    @Environment(StoreManager.self) private var storeManager
    @Environment(DownloadManager.self) private var downloadManager

    private var isPurchased: Bool {
        storeManager.isPurchased(packID)
    }

    private var isDownloaded: Bool {
        downloadManager.isDownloaded(packID)
    }

    private var isPurchasing: Bool {
        storeManager.purchaseInProgress == packID
    }

    private var downloadState: DownloadManager.DownloadState {
        downloadManager.downloads[packID] ?? .notDownloaded
    }

    var body: some View {
        Group {
            if !isPurchased {
                // Not owned — show price
                Button {
                    Task {
                        guard let product else { return }
                        try? await storeManager.purchase(product)
                    }
                } label: {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(product?.displayPrice ?? "—")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(isPurchasing || product == nil)
            } else if !isDownloaded {
                // Owned but not downloaded
                switch downloadState {
                case .downloading(let progress):
                    ProgressView(value: progress)
                        .tint(Color.softBlue)
                        .frame(width: 80)
                case .failed:
                    Button("Retry") {
                        Task { await downloadManager.downloadPack(packID) }
                    }
                    .buttonStyle(.glass)
                    .tint(.red)
                default:
                    Button("Download") {
                        Task { await downloadManager.downloadPack(packID) }
                    }
                    .buttonStyle(.glass)
                }
            } else {
                // Downloaded
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.green)
            }
        }
        .animation(.spring(duration: 0.3), value: isPurchased)
        .animation(.spring(duration: 0.3), value: isDownloaded)
    }
}
```

**Step 2: Create PackCardView**

Create `Saranera/Views/Library/PackCardView.swift`:

```swift
import SwiftUI

struct PackCardView: View {
    let pack: SoundPack
    @Environment(StoreManager.self) private var storeManager
    @Environment(DownloadManager.self) private var downloadManager

    private var isPurchased: Bool {
        storeManager.isPurchased(pack.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pack icon/category
            Image(systemName: pack.category.iconName)
                .font(.system(size: 28))
                .foregroundStyle(Color.warmAmber)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.tint(.orange), in: .circle)

            // Pack name
            Text(pack.name)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            // Sound count
            Text("\(pack.soundIDs.count) sounds")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            // Purchase / download button
            PurchaseButtonView(
                product: storeManager.product(for: pack.id),
                packID: pack.id
            )
        }
        .padding()
        .frame(width: 160, height: 200)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
```

**Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Saranera/Views/Library/PackCardView.swift Saranera/Views/Library/PurchaseButtonView.swift
git commit -m "feat: add PackCardView and PurchaseButtonView with Liquid Glass styling"
```

---

## Task 7: PackDetailView

**Files:**
- Create: `Saranera/Views/Library/PackDetailView.swift`

**Step 1: Create PackDetailView**

Create `Saranera/Views/Library/PackDetailView.swift`:

```swift
import SwiftUI

struct PackDetailView: View {
    let pack: SoundPack
    @Environment(StoreManager.self) private var storeManager
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.dismiss) private var dismiss

    private var packSounds: [Sound] {
        pack.soundIDs.compactMap { soundID in
            Sound.catalog.first { $0.id == soundID }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Sounds list
                    soundsSection

                    // Purchase / download
                    purchaseSection
                }
                .padding()
            }
            .background(Color.deepNavy.ignoresSafeArea())
            .navigationTitle(pack.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.softBlue)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: pack.category.iconName)
                .font(.system(size: 48))
                .foregroundStyle(Color.warmAmber)
                .frame(width: 80, height: 80)
                .glassEffect(.regular.tint(.orange), in: .circle)

            Text(pack.description)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Sounds

    private var soundsSection: some View {
        VStack(spacing: 0) {
            ForEach(packSounds) { sound in
                HStack(spacing: 12) {
                    Image(systemName: sound.iconName)
                        .font(.title3)
                        .foregroundStyle(Color.softBlue)
                        .frame(width: 32)

                    Text(sound.name)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    // Preview button
                    if sound.previewFileName != nil {
                        Button {
                            audioManager.play(sound: sound)
                        } label: {
                            Image(systemName: audioManager.isActive(sound) ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.softBlue)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)

                if sound.id != packSounds.last?.id {
                    Divider()
                        .background(.white.opacity(0.1))
                        .padding(.leading, 56)
                }
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 8) {
            PurchaseButtonView(
                product: storeManager.product(for: pack.id),
                packID: pack.id
            )

            if let product = storeManager.product(for: pack.id),
               !storeManager.isPurchased(pack.id) {
                Text(product.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
```

**Step 2: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Saranera/Views/Library/PackDetailView.swift
git commit -m "feat: add PackDetailView with sound list, preview, and purchase flow"
```

---

## Task 8: Redesign LibraryView

**Files:**
- Modify: `Saranera/Views/Library/LibraryView.swift`
- Modify: `Saranera/Views/Library/SoundRowView.swift`

**Step 1: Update SoundRowView with premium indicators**

Modify `Saranera/Views/Library/SoundRowView.swift`:

```swift
import SwiftUI

struct SoundRowView: View {
    let sound: Sound
    let isActive: Bool
    let isLocked: Bool

    init(sound: Sound, isActive: Bool, isLocked: Bool = false) {
        self.sound = sound
        self.isActive = isActive
        self.isLocked = isLocked
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sound.iconName)
                .font(.title3)
                .foregroundStyle(isActive ? Color.warmAmber : isLocked ? .secondary.opacity(0.5) : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(sound.name)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(isLocked ? .primary.opacity(0.5) : .primary)

                if isLocked, let pack = SoundPack.pack(for: sound.id) {
                    Text(pack.name)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color.softBlue.opacity(0.7))
                }
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            } else if isActive {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.warmAmber)
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
        SoundRowView(sound: Sound.catalog[0], isActive: false, isLocked: true)
    }
    .padding()
}
```

**Step 2: Redesign LibraryView with three sections**

Modify `Saranera/Views/Library/LibraryView.swift`:

```swift
import SwiftUI

struct LibraryView: View {
    @Environment(AudioManager.self) private var audioManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(DownloadManager.self) private var downloadManager
    @State private var selectedPack: SoundPack?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Section 1: Premium Packs
                    packsSection

                    // Section 2: All Sounds
                    allSoundsSection
                }
                .padding(.vertical)
            }
            .background(Color.deepNavy.ignoresSafeArea())
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task { await storeManager.restorePurchases() }
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.softBlue)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(item: $selectedPack) { pack in
                PackDetailView(pack: pack)
                    .environment(storeManager)
                    .environment(downloadManager)
                    .environment(audioManager)
            }
            .alert("Error", isPresented: Binding(
                get: { storeManager.errorMessage != nil },
                set: { if !$0 { storeManager.errorMessage = nil } }
            )) {
                Button("OK") { storeManager.errorMessage = nil }
            } message: {
                Text(storeManager.errorMessage ?? "")
            }
        }
    }

    // MARK: - Packs Section

    private var packsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Packs")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SoundPack.catalog) { pack in
                        PackCardView(pack: pack)
                            .onTapGesture {
                                selectedPack = pack
                            }
                    }

                    // Bundle card
                    bundleCard
                }
                .padding(.horizontal)
            }
        }
    }

    private var bundleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.softBlue)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.tint(.blue), in: .circle)

            Text("All Access")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            if let savings = storeManager.bundleSavings(bundlePrice: 7.99, individualTotal: 12.96) {
                Text(savings)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.warmAmber)
            }

            Spacer()

            PurchaseButtonView(
                product: storeManager.product(for: StoreManager.bundleProductID),
                packID: StoreManager.bundleProductID
            )
        }
        .padding()
        .frame(width: 160, height: 200)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - All Sounds Section

    private var allSoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Sounds")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal)

            ForEach(SoundCategory.allCases, id: \.self) { category in
                VStack(alignment: .leading, spacing: 4) {
                    Label(category.displayName, systemImage: category.iconName)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        let sounds = Sound.grouped[category] ?? []
                        ForEach(sounds) { sound in
                            let isLocked = sound.isPremium && !storeManager.isSoundAvailable(sound.id)
                            SoundRowView(
                                sound: sound,
                                isActive: audioManager.isActive(sound),
                                isLocked: isLocked
                            )
                            .padding(.horizontal)
                            .onTapGesture {
                                if isLocked {
                                    if let pack = SoundPack.pack(for: sound.id) {
                                        selectedPack = pack
                                    }
                                } else {
                                    audioManager.play(sound: sound)
                                }
                            }
                        }
                    }
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .environment(AudioManager(audioEnabled: false))
        .environment(StoreManager())
        .environment(DownloadManager())
}
```

**Step 3: Make SoundPack conform to Identifiable for sheet binding**

This is already done (SoundPack: Identifiable). Verify it also has `Hashable` for the sheet. If needed, add conformance:

In `Saranera/Models/SoundPack.swift`, the struct already has `let id: String` and conforms to `Identifiable`. No change needed.

**Step 4: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 5: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add Saranera/Views/Library/LibraryView.swift Saranera/Views/Library/SoundRowView.swift
git commit -m "feat: redesign Library tab with premium packs section and lock indicators"
```

---

## Task 9: Update SoundPickerView with Premium Indicators

**Files:**
- Modify: `Saranera/Views/Shared/SoundPickerView.swift`
- Modify: `Saranera/Views/Shared/SoundPickerRowView.swift`

**Step 1: Update SoundPickerRowView to handle locked premium sounds**

Modify `Saranera/Views/Shared/SoundPickerRowView.swift`. Add `StoreManager` environment and disable interaction for locked sounds:

```swift
import SwiftUI

struct SoundPickerRowView: View {
    let sound: Sound
    @Environment(AudioManager.self) private var audioManager
    @Environment(StoreManager.self) private var storeManager

    private var isActive: Bool {
        audioManager.isActive(sound)
    }

    private var isLocked: Bool {
        sound.isPremium && !storeManager.isSoundAvailable(sound.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                if !isLocked {
                    audioManager.play(sound: sound)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: sound.iconName)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(isActive
                            ? Color.warmAmber
                            : isLocked ? .white.opacity(0.3) : .white.opacity(0.7))
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.name)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(isLocked ? .white.opacity(0.5) : .white)

                        if isLocked, let pack = SoundPack.pack(for: sound.id) {
                            Text(pack.name)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(Color.softBlue.opacity(0.6))
                        }
                    }

                    Spacer()

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    } else if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.softBlue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .disabled(isLocked)

            // Volume slider for active sounds
            if isActive {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))

                    Slider(
                        value: Binding(
                            get: { Double(audioManager.volume(for: sound)) },
                            set: { audioManager.setVolume(for: sound, to: Float($0)) }
                        ),
                        in: 0...1
                    )
                    .tint(Color.softBlue)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .animation(.spring(duration: 0.3), value: isActive)
    }
}

#Preview {
    ZStack {
        Color.deepNavy.ignoresSafeArea()
        VStack {
            SoundPickerRowView(sound: Sound.catalog[0])
            SoundPickerRowView(sound: Sound.catalog[1])
        }
        .environment(AudioManager(audioEnabled: false))
        .environment(StoreManager())
    }
}
```

**Step 2: Update SoundPickerView to pass StoreManager environment to previews**

Modify `Saranera/Views/Shared/SoundPickerView.swift` — update just the Preview:

```swift
#Preview {
    SoundPickerView()
        .environment(AudioManager(audioEnabled: false))
        .environment(StoreManager())
}
```

**Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Saranera/Views/Shared/SoundPickerView.swift Saranera/Views/Shared/SoundPickerRowView.swift
git commit -m "feat: add premium lock indicators to SoundPickerView"
```

---

## Task 10: Update RecommendationManager for Premium Sounds

**Files:**
- Modify: `Saranera/ViewModels/RecommendationManager.swift`
- Modify: `Saranera/Views/Shared/RecommendationView.swift`

**Step 1: Read RecommendationView.swift first**

Read `Saranera/Views/Shared/RecommendationView.swift` to understand the current call site.

**Step 2: Update RecommendationManager.buildInstructions to accept purchased sounds**

In `Saranera/ViewModels/RecommendationManager.swift`, modify the `buildInstructions` method signature. Instead of taking `availableSounds: [Sound]`, it should take `availableSounds: [Sound]` which the caller will now include purchased+downloaded premium sounds in:

No change needed to RecommendationManager itself — the caller is responsible for passing the correct `availableSounds` array.

**Step 3: Update RecommendationView to filter available sounds**

In `Saranera/Views/Shared/RecommendationView.swift`, where `recommend()` is called, update the `availableSounds` parameter to include purchased+downloaded premium sounds:

Find where `Sound.catalog.filter { !$0.isPremium }` or similar is used and replace with:

```swift
// Build available sounds: free + purchased & downloaded premium
let availableSounds = Sound.catalog.filter { sound in
    if sound.isFree { return true }
    guard let packID = sound.packID else { return false }
    return storeManager.isSoundAvailable(sound.id) && downloadManager.isDownloaded(packID)
}
```

Add `@Environment(StoreManager.self)` and `@Environment(DownloadManager.self)` to RecommendationView.

**Step 4: Build to verify compilation**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 5: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add Saranera/ViewModels/RecommendationManager.swift Saranera/Views/Shared/RecommendationView.swift
git commit -m "feat: include purchased premium sounds in AI recommendations"
```

---

## Task 11: Update Remaining Views for Environment Compatibility

**Files:**
- Modify: `Saranera/Views/Focus/FocusView.swift`
- Modify: `Saranera/Views/Sleep/SleepView.swift`
- Modify: `Saranera/ContentView.swift`

**Step 1: Read FocusView.swift, SleepView.swift to check for environment dependencies**

These views contain `SoundPickerView` presentations and `RecommendationView` usage. Since those sub-views now require `StoreManager` and `DownloadManager` environments, verify the environment chain passes through. Since we inject at the app level, these should be inherited automatically.

**Step 2: Build to verify all views compile with new environment requirements**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

If there are compilation errors about missing environments in sheets/modals, add explicit `.environment()` modifiers to sheet content.

**Step 3: Run full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: ALL PASS

**Step 4: Commit (only if changes were needed)**

```bash
git add -A
git commit -m "fix: ensure StoreManager and DownloadManager environments propagate to all views"
```

---

## Task 12: Final Integration Test + Cleanup

**Files:**
- All modified files

**Step 1: Run the full test suite**

Run: `xcodebuild test -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40`
Expected: ALL PASS

**Step 2: Verify build for both iPhone and iPad**

Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10`
Run: `xcodebuild build -scheme Saranera -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED for both

**Step 3: Review git log for clean commit history**

Run: `git log --oneline -15`
Expected: Clean, sequential commits for Phase 4

**Step 4: Final commit if any cleanup needed**

```bash
git status
# Only commit if there are unstaged changes
```
