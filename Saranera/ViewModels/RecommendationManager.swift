import Foundation
import FoundationModels
import Observation

enum ModelAvailability: Sendable, Equatable {
    case available
    case notEnabled
    case notEligible
    case notReady
}

enum RecommendationState: Sendable, Equatable {
    case idle
    case loading
    case streaming
    case completed
    case error
}

enum RecommendationMode: Sendable {
    case focus
    case sleep
}

@Observable
final class RecommendationManager {

    // MARK: - Public State

    private(set) var availability: ModelAvailability = .notEligible
    var state: RecommendationState = .idle
    var partialResult: SoundRecommendation.PartiallyGenerated?
    var result: SoundRecommendation?
    var errorMessage: String?

    // MARK: - Private

    private var currentTask: Task<Void, Never>?

    // MARK: - Availability

    func checkAvailability() {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            availability = .available
        case .unavailable(.appleIntelligenceNotEnabled):
            availability = .notEnabled
        case .unavailable(.deviceNotEligible):
            availability = .notEligible
        case .unavailable(.modelNotReady):
            availability = .notReady
        case .unavailable:
            availability = .notEligible
        }
    }

    // MARK: - Instructions

    func buildInstructions(mode: RecommendationMode, availableSounds: [Sound]) -> String {
        let modeString = mode == .focus ? "focus" : "sleep"
        let soundList = availableSounds
            .map { "- \"\($0.id)\": \($0.name) (\($0.category.displayName))" }
            .joined(separator: "\n")

        return """
            You are Serenara's sound recommendation assistant. The user is in \(modeString) mode.

            AVAILABLE SOUNDS (only suggest from this list):
            \(soundList)

            RULES:
            - Only use soundId values from the available sounds list above.
            - Suggest 1 to 3 sounds that complement each other.
            - Set volume (0-100) for each sound. Primary sounds should be 50-80, secondary/accent sounds 20-50.
            - For focus mode: suggest timer durations of 25, 50, or longer for deep work. Set fadeOutMinutes to 0.
            - For sleep mode: suggest timer durations of 30-90 minutes. Set fadeOutMinutes between 2-15.
            - Match the soundscape to the user's described mood, activity, or atmosphere.
            - Nature sounds (rain, ocean, forest) are calming and good for both focus and sleep.
            - Noise sounds (white, brown, pink) are excellent for masking distractions during focus.
            - Brown noise is especially good for deep concentration.
            - Environment sounds (fireplace, wind, crickets) add warmth and atmosphere.
            - Urban sounds (coffee shop, library) create a productive ambience for focus.
            - Keep reasoning brief (1-2 sentences).
            """
    }

    // MARK: - Recommend

    func recommend(mood: String, mode: RecommendationMode, availableSounds: [Sound]) async {
        currentTask?.cancel()
        state = .loading
        result = nil
        partialResult = nil
        errorMessage = nil

        let instructions = buildInstructions(mode: mode, availableSounds: availableSounds)

        do {
            let session = LanguageModelSession(instructions: instructions)
            let stream = session.streamResponse(
                to: "The user says: \(mood)",
                generating: SoundRecommendation.self
            )

            state = .streaming

            for try await snapshot in stream {
                partialResult = snapshot.content
            }

            // Stream completed — extract final result
            if let partial = partialResult,
               let sounds = partial.sounds,
               let timerMinutes = partial.timerMinutes,
               let fadeOutMinutes = partial.fadeOutMinutes,
               let reasoning = partial.reasoning {
                let validSoundIds = Set(availableSounds.map(\.id))
                let validSuggestions = sounds.compactMap { suggestion -> SoundSuggestion? in
                    guard let soundId = suggestion.soundId,
                          let volume = suggestion.volume,
                          validSoundIds.contains(soundId) else { return nil }
                    return SoundSuggestion(soundId: soundId, volume: volume)
                }

                guard !validSuggestions.isEmpty else {
                    state = .error
                    errorMessage = "No valid sounds in recommendation"
                    return
                }

                result = SoundRecommendation(
                    sounds: validSuggestions,
                    timerMinutes: timerMinutes,
                    fadeOutMinutes: fadeOutMinutes,
                    reasoning: reasoning
                )
                state = .completed
            } else {
                state = .error
                errorMessage = "Incomplete recommendation received"
            }
        } catch let error as LanguageModelSession.GenerationError {
            state = .error
            switch error {
            case .exceededContextWindowSize:
                errorMessage = "Too many sounds to process"
            case .guardrailViolation:
                errorMessage = "Could not generate a recommendation"
            default:
                errorMessage = "Something went wrong"
            }
        } catch is CancellationError {
            return
        } catch {
            state = .error
            errorMessage = "Something went wrong"
        }
    }

    // MARK: - Reset

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
        result = nil
        partialResult = nil
        errorMessage = nil
    }
}
