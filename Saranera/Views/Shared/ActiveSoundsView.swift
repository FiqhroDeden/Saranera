import SwiftUI

struct ActiveSoundsView: View {
    @Environment(AudioManager.self) private var audioManager

    var body: some View {
        if !audioManager.activeSoundIDs.isEmpty {
            VStack(spacing: 8) {
                ForEach(activeSounds) { sound in
                    HStack(spacing: 8) {
                        Image(systemName: sound.iconName)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(sound.name)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))

                        // Volume dots
                        HStack(spacing: 3) {
                            let vol = audioManager.volume(for: sound)
                            ForEach(0..<5, id: \.self) { dot in
                                Circle()
                                    .fill(Float(dot) / 5.0 < vol ? .white : .white.opacity(0.2))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }
        }
    }

    private var activeSounds: [Sound] {
        Sound.catalog.filter { audioManager.isActive($0) }
    }
}

#Preview {
    ZStack {
        Color.deepNavy.ignoresSafeArea()
        ActiveSoundsView()
            .environment(AudioManager(audioEnabled: false))
    }
}
