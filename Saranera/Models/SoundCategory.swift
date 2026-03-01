import Foundation

enum SoundCategory: String, CaseIterable, Codable, Sendable {
    case nature
    case ambient
    case environment
    case urban

    var displayName: String {
        switch self {
        case .nature: "Nature"
        case .ambient: "Ambient"
        case .environment: "Environment"
        case .urban: "Urban"
        }
    }

    var iconName: String {
        switch self {
        case .nature: "leaf"
        case .ambient: "waveform"
        case .environment: "house"
        case .urban: "building.2"
        }
    }
}
