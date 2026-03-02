import Foundation

struct SoundPack: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let category: SoundCategory
    let soundIDs: [String]
    let odrTag: String
    let previewImageName: String

    static func pack(for soundID: String) -> SoundPack? {
        catalog.first { $0.soundIDs.contains(soundID) }
    }

    static let catalog: [SoundPack] = [
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.rainy_day",
            name: "Rainy Day Collection",
            description: "Immerse yourself in the soothing sounds of rain, from gentle drizzles to rolling thunderstorms.",
            category: .nature,
            soundIDs: ["drizzle", "thunderstorm", "rain_tin_roof", "rain_tent"],
            odrTag: "pack_rainy_day",
            previewImageName: "pack_rainy_day"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.ocean_dreams",
            name: "Ocean Dreams",
            description: "Drift away with calming ocean sounds, from beach waves to serene underwater ambience.",
            category: .nature,
            soundIDs: ["beach_waves", "underwater", "harbor", "seagulls"],
            odrTag: "pack_ocean_dreams",
            previewImageName: "pack_ocean_dreams"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.lofi_study",
            name: "Lo-Fi Study",
            description: "Create the perfect study atmosphere with lo-fi beats and cozy ambient sounds.",
            category: .ambient,
            soundIDs: ["lofi_beats", "vinyl_crackle", "keyboard_typing", "pen_writing"],
            odrTag: "pack_lofi_study",
            previewImageName: "pack_lofi_study"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.nusantara",
            name: "Nusantara",
            description: "Experience the rich soundscape of the Indonesian archipelago, from gamelan to jungle rivers.",
            category: .environment,
            soundIDs: ["gamelan", "rice_paddies", "jungle_river", "traditional_market"],
            odrTag: "pack_nusantara",
            previewImageName: "pack_nusantara"
        ),
        SoundPack(
            id: "app.fiqhrodedhen.Saranera.pack.city_nights",
            name: "City Nights",
            description: "Unwind with the ambient sounds of city life after dark.",
            category: .urban,
            soundIDs: ["distant_traffic", "train_passing", "apartment_window", "late_night_diner"],
            odrTag: "pack_city_nights",
            previewImageName: "pack_city_nights"
        ),
    ]
}
