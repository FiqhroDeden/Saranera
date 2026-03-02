import SwiftUI
import StoreKit

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
                    headerSection
                    soundsSection
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
