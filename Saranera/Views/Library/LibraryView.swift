import SwiftUI

struct LibraryView: View {
    @Environment(AudioManager.self) private var audioManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(SoundCategory.allCases, id: \.self) { category in
                    Section {
                        let sounds = Sound.grouped[category] ?? []
                        ForEach(sounds) { sound in
                            SoundRowView(
                                sound: sound,
                                isActive: audioManager.isActive(sound)
                            )
                            .onTapGesture {
                                audioManager.play(sound: sound)
                            }
                        }
                    } header: {
                        Label(category.displayName, systemImage: category.iconName)
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .navigationTitle("Library")
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea()) // Deep Navy
        }
    }
}

#Preview {
    LibraryView()
        .environment(AudioManager.shared)
}
