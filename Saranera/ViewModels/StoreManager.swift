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

    private nonisolated(unsafe) var transactionListener: Task<Void, Never>?

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
            purchaseInProgress = nil
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
