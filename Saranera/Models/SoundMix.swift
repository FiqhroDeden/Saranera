import Foundation

struct MixComponent: Codable, Hashable, Sendable {
    let soundID: String
    var volume: Float
}

struct SoundMix: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var components: [MixComponent]
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, components: [MixComponent], isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.components = components
        self.isFavorite = isFavorite
    }
}
