import SwiftUI

struct PackCardView: View {
    let pack: SoundPack
    @Environment(StoreManager.self) private var storeManager

    private var isPurchased: Bool {
        storeManager.isPurchased(pack.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: pack.category.iconName)
                .font(.system(size: 28))
                .foregroundStyle(Color.warmAmber)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.tint(.orange), in: .circle)

            Text(pack.name)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("\(pack.soundIDs.count) sounds")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

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
