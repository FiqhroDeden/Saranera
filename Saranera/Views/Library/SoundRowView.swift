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
