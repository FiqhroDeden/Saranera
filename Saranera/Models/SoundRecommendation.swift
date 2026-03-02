import Foundation
import FoundationModels

@Generable(description: "A single sound suggestion within a recommendation")
struct SoundSuggestion {
    @Guide(description: "The sound identifier from the catalog, e.g. 'rain', 'coffeeShop', 'ocean_waves'")
    var soundId: String

    @Guide(description: "Volume level for this sound", .range(0...100))
    var volume: Int
}

@Generable(description: "A personalized soundscape recommendation based on user's mood")
struct SoundRecommendation {
    @Guide(description: "Suggested sounds to play", .count(1...3))
    var sounds: [SoundSuggestion]

    @Guide(description: "Suggested timer duration in minutes", .range(5...120))
    var timerMinutes: Int

    @Guide(description: "Fade-out duration in minutes for sleep mode, 0 for focus mode", .range(0...15))
    var fadeOutMinutes: Int

    @Guide(description: "Brief explanation of why this soundscape was chosen for the user's mood")
    var reasoning: String
}
