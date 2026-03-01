import Foundation

struct Sound: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let category: SoundCategory
    let fileName: String
    let isPremium: Bool
    let iconName: String

    static let catalog: [Sound] = [
        // Nature
        Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
        Sound(id: "thunder", name: "Thunder", category: .nature, fileName: "thunder.m4a", isPremium: false, iconName: "cloud.bolt"),
        Sound(id: "forest", name: "Forest", category: .nature, fileName: "forest.m4a", isPremium: false, iconName: "tree"),
        Sound(id: "ocean_waves", name: "Ocean Waves", category: .nature, fileName: "ocean_waves.m4a", isPremium: false, iconName: "water.waves"),
        // Ambient
        Sound(id: "white_noise", name: "White Noise", category: .ambient, fileName: "white_noise.m4a", isPremium: false, iconName: "waveform"),
        Sound(id: "brown_noise", name: "Brown Noise", category: .ambient, fileName: "brown_noise.m4a", isPremium: false, iconName: "waveform.path"),
        Sound(id: "pink_noise", name: "Pink Noise", category: .ambient, fileName: "pink_noise.m4a", isPremium: false, iconName: "waveform.badge.magnifyingglass"),
        // Environment
        Sound(id: "fireplace", name: "Fireplace", category: .environment, fileName: "fireplace.m4a", isPremium: false, iconName: "flame"),
        Sound(id: "wind", name: "Wind", category: .environment, fileName: "wind.m4a", isPremium: false, iconName: "wind"),
        Sound(id: "night_crickets", name: "Night Crickets", category: .environment, fileName: "night_crickets.m4a", isPremium: false, iconName: "moon.stars"),
        // Urban
        Sound(id: "coffee_shop", name: "Coffee Shop", category: .urban, fileName: "coffee_shop.m4a", isPremium: false, iconName: "cup.and.saucer"),
        Sound(id: "library_ambience", name: "Library Ambience", category: .urban, fileName: "library_ambience.m4a", isPremium: false, iconName: "books.vertical"),
    ]

    static var grouped: [SoundCategory: [Sound]] {
        Dictionary(grouping: catalog, by: \.category)
    }
}
