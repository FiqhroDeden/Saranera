import SwiftUI

struct SoundPickerView: View {
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(SoundCategory.allCases, id: \.self) { category in
                        Section {
                            let sounds = Sound.grouped[category] ?? []
                            ForEach(sounds) { sound in
                                SoundPickerRowView(sound: sound)
                            }
                        } header: {
                            HStack {
                                Label(category.displayName, systemImage: category.iconName)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.051, green: 0.106, blue: 0.165).ignoresSafeArea())
            .navigationTitle("Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    SoundPickerView()
        .environment(AudioManager(audioEnabled: false))
}
