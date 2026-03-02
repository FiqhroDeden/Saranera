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
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.green)
            }
        }
        .animation(.spring(duration: 0.3), value: isPurchased)
        .animation(.spring(duration: 0.3), value: isDownloaded)
    }
}
