import Foundation

struct Sound: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let category: SoundCategory
    let fileName: String
    let isPremium: Bool
    let iconName: String
    let packID: String?
    let previewFileName: String?

    var isFree: Bool { packID == nil }

    init(
        id: String,
        name: String,
        category: SoundCategory,
        fileName: String,
        isPremium: Bool,
        iconName: String,
        packID: String? = nil,
        previewFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.fileName = fileName
        self.isPremium = isPremium
        self.iconName = iconName
        self.packID = packID
        self.previewFileName = previewFileName
    }

    // MARK: - Catalog

    static let catalog: [Sound] = freeSounds + premiumSounds

    static var freeSounds: [Sound] {
        [
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
    }

    static var premiumSounds: [Sound] {
        [
            // Rainy Day Collection (nature)
            Sound(id: "drizzle", name: "Drizzle", category: .nature, fileName: "drizzle.m4a", isPremium: true, iconName: "cloud.drizzle", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "drizzle_preview.m4a"),
            Sound(id: "thunderstorm", name: "Thunderstorm", category: .nature, fileName: "thunderstorm.m4a", isPremium: true, iconName: "cloud.bolt.rain", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "thunderstorm_preview.m4a"),
            Sound(id: "rain_tin_roof", name: "Rain on Tin Roof", category: .nature, fileName: "rain_tin_roof.m4a", isPremium: true, iconName: "house", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "rain_tin_roof_preview.m4a"),
            Sound(id: "rain_tent", name: "Rain on Tent", category: .nature, fileName: "rain_tent.m4a", isPremium: true, iconName: "tent", packID: "app.fiqhrodedhen.Saranera.pack.rainy_day", previewFileName: "rain_tent_preview.m4a"),

            // Ocean Dreams (nature)
            Sound(id: "beach_waves", name: "Beach Waves", category: .nature, fileName: "beach_waves.m4a", isPremium: true, iconName: "beach.umbrella", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "beach_waves_preview.m4a"),
            Sound(id: "underwater", name: "Underwater", category: .nature, fileName: "underwater.m4a", isPremium: true, iconName: "figure.swimming", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "underwater_preview.m4a"),
            Sound(id: "harbor", name: "Harbor", category: .nature, fileName: "harbor.m4a", isPremium: true, iconName: "ferry", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "harbor_preview.m4a"),
            Sound(id: "seagulls", name: "Seagulls", category: .nature, fileName: "seagulls.m4a", isPremium: true, iconName: "bird", packID: "app.fiqhrodedhen.Saranera.pack.ocean_dreams", previewFileName: "seagulls_preview.m4a"),

            // Lo-Fi Study (ambient)
            Sound(id: "lofi_beats", name: "Lo-Fi Beats", category: .ambient, fileName: "lofi_beats.m4a", isPremium: true, iconName: "headphones", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "lofi_beats_preview.m4a"),
            Sound(id: "vinyl_crackle", name: "Vinyl Crackle", category: .ambient, fileName: "vinyl_crackle.m4a", isPremium: true, iconName: "record.circle", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "vinyl_crackle_preview.m4a"),
            Sound(id: "keyboard_typing", name: "Keyboard Typing", category: .ambient, fileName: "keyboard_typing.m4a", isPremium: true, iconName: "keyboard", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "keyboard_typing_preview.m4a"),
            Sound(id: "pen_writing", name: "Pen Writing", category: .ambient, fileName: "pen_writing.m4a", isPremium: true, iconName: "pencil.line", packID: "app.fiqhrodedhen.Saranera.pack.lofi_study", previewFileName: "pen_writing_preview.m4a"),

            // Nusantara (environment)
            Sound(id: "gamelan", name: "Gamelan", category: .environment, fileName: "gamelan.m4a", isPremium: true, iconName: "music.note", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "gamelan_preview.m4a"),
            Sound(id: "rice_paddies", name: "Rice Paddies", category: .environment, fileName: "rice_paddies.m4a", isPremium: true, iconName: "leaf.arrow.circlepath", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "rice_paddies_preview.m4a"),
            Sound(id: "jungle_river", name: "Jungle River", category: .environment, fileName: "jungle_river.m4a", isPremium: true, iconName: "tropicalstorm", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "jungle_river_preview.m4a"),
            Sound(id: "traditional_market", name: "Traditional Market", category: .environment, fileName: "traditional_market.m4a", isPremium: true, iconName: "storefront", packID: "app.fiqhrodedhen.Saranera.pack.nusantara", previewFileName: "traditional_market_preview.m4a"),

            // City Nights (urban)
            Sound(id: "distant_traffic", name: "Distant Traffic", category: .urban, fileName: "distant_traffic.m4a", isPremium: true, iconName: "car", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "distant_traffic_preview.m4a"),
            Sound(id: "train_passing", name: "Train Passing", category: .urban, fileName: "train_passing.m4a", isPremium: true, iconName: "tram", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "train_passing_preview.m4a"),
            Sound(id: "apartment_window", name: "Apartment Window", category: .urban, fileName: "apartment_window.m4a", isPremium: true, iconName: "window.casement", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "apartment_window_preview.m4a"),
            Sound(id: "late_night_diner", name: "Late Night Diner", category: .urban, fileName: "late_night_diner.m4a", isPremium: true, iconName: "fork.knife", packID: "app.fiqhrodedhen.Saranera.pack.city_nights", previewFileName: "late_night_diner_preview.m4a"),
        ]
    }

    static var grouped: [SoundCategory: [Sound]] {
        Dictionary(grouping: catalog, by: \.category)
    }
}
