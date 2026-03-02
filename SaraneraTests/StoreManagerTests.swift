import Testing
import Foundation
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
        #expect(StoreManager.allProductIDs.count == 6)
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

    @Test func bundleSavingsReturnsPercentage() {
        let manager = makeManager()
        let savings = manager.bundleSavings(bundlePrice: 7.99, individualTotal: 12.96)
        #expect(savings != nil)
        #expect(savings!.contains("38"))
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

    @Test func isSoundAvailableAfterBundlePurchase() {
        let manager = makeManager()
        manager.purchasedPackIDs.insert(StoreManager.bundleProductID)
        #expect(manager.isSoundAvailable("drizzle"))
        #expect(manager.isSoundAvailable("lofi_beats"))
        #expect(manager.isSoundAvailable("gamelan"))
    }

    @Test func isSoundAvailableReturnsFalseForUnknownSound() {
        let manager = makeManager()
        #expect(!manager.isSoundAvailable("nonexistent_sound"))
    }
}
