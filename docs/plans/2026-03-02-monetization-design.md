# Monetization Design — Phase 4

## Overview

StoreKit 2 integration for one-time sound pack purchases with On-Demand Resources delivery, preview playback, and a redesigned Library tab.

## Decisions

- **Architecture**: Centralized StoreManager (@Observable) + separate DownloadManager
- **Asset delivery**: On-Demand Resources (ODR) → copy to Documents for persistence
- **Dev assets**: Stub audio files with full purchase-to-play flow
- **Library layout**: Favorites → Packs → All Sounds sections
- **Bundle**: Smart bundle with savings callout
- **Previews**: 15-30s bundled clips per premium sound
- **Pricing**: USD

## Pricing

| Product | ID | Price |
|---|---|---|
| Rainy Day Collection | `app.fiqhrodedhen.Saranera.pack.rainy_day` | $1.99 |
| Ocean Dreams | `app.fiqhrodedhen.Saranera.pack.ocean_dreams` | $1.99 |
| Lo-Fi Study | `app.fiqhrodedhen.Saranera.pack.lofi_study` | $2.99 |
| Nusantara | `app.fiqhrodedhen.Saranera.pack.nusantara` | $3.99 |
| City Nights | `app.fiqhrodedhen.Saranera.pack.city_nights` | $1.99 |
| Bundle All Access | `app.fiqhrodedhen.Saranera.pack.bundle_all` | $7.99 |

Bundle saves ~$4.97 (40%) vs buying individually.

## Data Model

### SoundPack (new)

```swift
struct SoundPack: Identifiable {
    let id: String              // matches StoreKit product ID
    let name: String
    let description: String
    let category: SoundCategory
    let soundIDs: [String]
    let odrTag: String          // On-Demand Resources tag
    let previewImageName: String

    static let catalog: [SoundPack]
}
```

### Sound Extensions

```swift
// Add to existing Sound:
let packID: String?             // nil for free sounds
let previewFileName: String?    // bundled 15-30s clip
let fullFileName: String        // full audio file name

var isFree: Bool { packID == nil }
```

### StoreKit Product IDs

All 6 products are non-consumable (one-time purchase).

## StoreManager

```swift
@Observable
final class StoreManager {
    var products: [Product] = []
    var purchasedPackIDs: Set<String> = []
    var purchaseInProgress: String? = nil
    var errorMessage: String? = nil

    func loadProducts() async
    func listenForTransactions() async
    func purchase(_ product: Product) async throws
    func restorePurchases() async
    func isPurchased(_ packID: String) -> Bool
    func product(for packID: String) -> Product?
    func bundleSavings() -> String?
}
```

**Key behaviors:**
- `loadProducts()` called on app launch
- `listenForTransactions()` runs as background Task for out-of-app purchases
- `purchase()` sets purchaseInProgress, calls product.purchase(), verifies, updates entitlements, triggers download
- Bundle logic: computes savings string based on already-owned packs
- Entitlements synced from `Transaction.currentEntitlements`

## DownloadManager

```swift
@Observable
final class DownloadManager {
    var downloads: [String: DownloadState] = [:]

    enum DownloadState: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case failed(String)
    }

    func downloadPack(_ packID: String) async
    func cancelDownload(_ packID: String)
    func deletePack(_ packID: String) throws
    func checkDownloadedPacks()
    func isDownloaded(_ packID: String) -> Bool
    func isDownloaded(soundID: String) -> Bool
    func fileURL(for soundID: String) -> URL?
    func downloadedSize() -> String
}
```

**Flow:**
1. Purchase completes → StoreManager calls `downloadManager.downloadPack(packID)`
2. Creates `NSBundleResourceRequest` with pack's ODR tag
3. Observes `progress.fractionCompleted` → updates state
4. Copies files to `Documents/Sounds/{packID}/`
5. State → `.downloaded`

Resume: `NSBundleResourceRequest` handles resume natively.
On launch: `checkDownloadedPacks()` scans Documents to rebuild state.

## Library UI

### Layout (top → bottom)

1. **My Favorites** — horizontal scroll of saved SoundMix cards
2. **Premium Packs** — horizontal scroll of Liquid Glass pack cards with price/checkmark
3. **All Sounds** — grouped by category, lock icons on premium sounds

### New Views

```
Views/Library/
├── LibraryView.swift          // redesigned 3-section layout
├── SoundRowView.swift         // updated with lock/premium indicators
├── PackCardView.swift         // horizontal scroll card
├── PackDetailView.swift       // full pack: sounds list, preview, buy, download
├── PurchaseButtonView.swift   // price button with loading states
└── DownloadProgressView.swift // progress bar for downloads
```

### PackDetailView

Header with pack name/description, scrollable sound list with preview playback buttons, purchase/download button at bottom.

### Purchase Button States

```
Not owned     → "Buy for $X.XX"        (tappable)
Purchasing    → spinner + "Purchasing…" (disabled)
Owned, not DL → "Download"             (tappable)
Downloading   → progress bar + "%"     (progress)
Downloaded    → "Downloaded ✓"          (disabled, green)
Error         → "Retry Download"        (tappable, red)
```

## Integration Points

### AudioManager
- Add `loadSound(from url: URL)` for Documents-based files
- Check download state before playing premium sounds
- Prompt purchase/download if sound unavailable

### SoundPickerView
- Lock icon on unpurchased premium sounds
- Tapping locked sound → pack detail sheet (upsell)
- Filter toggle: "All" / "My Sounds"

### RecommendationManager
- Update `buildInstructions()` to include purchased+downloaded premium sounds
- Show "Get this pack" callout when AI recommends unowned premium sounds

### SaraneraApp Entry Point

```swift
@main
struct SaraneraApp: App {
    let storeManager = StoreManager()
    let downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AudioManager.shared)
                .environment(storeManager)
                .environment(downloadManager)
                .task {
                    await storeManager.loadProducts()
                    await storeManager.listenForTransactions()
                    downloadManager.checkDownloadedPacks()
                }
        }
        .modelContainer(for: FocusSession.self)
    }
}
```

### StoreKit Testing
- New `Saranera.storekit` configuration file
- 6 non-consumable products
- Testable in Simulator without App Store Connect

### Error Handling
- Purchase failures → alert with retry
- Download failures → retry button on pack card
- Offline → cached state, disable purchase/download
- Transaction verification failures → log + generic error
