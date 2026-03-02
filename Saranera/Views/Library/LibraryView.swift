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
                    packsSection
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
