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
                    .foregroundStyle(.primary)
                    .opacity(isLocked ? 0.5 : 1.0)

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
