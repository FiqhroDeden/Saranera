import SwiftUI

struct SoundPickerRowView: View {
    let sound: Sound
    @Environment(AudioManager.self) private var audioManager

    private var isActive: Bool {
        audioManager.isActive(sound)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                audioManager.play(sound: sound)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: sound.iconName)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(isActive
                            ? Color.warmAmber
                            : .white.opacity(0.7))
                        .frame(width: 32)

                    Text(sound.name)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    if sound.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.softBlue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .disabled(sound.isPremium)

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
    }
}
