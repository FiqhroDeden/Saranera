import Foundation
import Testing
@testable import Saranera

@MainActor
struct RecommendationManagerTests {

    // MARK: - Initial State

    @Test func initialStateIsIdle() {
        let manager = RecommendationManager()
        #expect(manager.state == .idle)
        #expect(manager.result == nil)
        #expect(manager.partialResult == nil)
        #expect(manager.errorMessage == nil)
    }

    // MARK: - Instruction Building

    @Test func buildInstructionsContainsSoundCatalog() {
        let manager = RecommendationManager()
        let sounds = [
            Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
            Sound(id: "fire", name: "Fireplace", category: .environment, fileName: "fire.m4a", isPremium: false, iconName: "flame"),
        ]
        let instructions = manager.buildInstructions(mode: .focus, availableSounds: sounds)

        #expect(instructions.contains("rain"))
        #expect(instructions.contains("Rain"))
        #expect(instructions.contains("fire"))
        #expect(instructions.contains("Fireplace"))
        #expect(instructions.contains("focus"))
    }

    @Test func buildInstructionsContainsMode() {
        let manager = RecommendationManager()
        let sounds = [Sound.catalog[0]]

        let focusInstructions = manager.buildInstructions(mode: .focus, availableSounds: sounds)
        #expect(focusInstructions.contains("focus"))

        let sleepInstructions = manager.buildInstructions(mode: .sleep, availableSounds: sounds)
        #expect(sleepInstructions.contains("sleep"))
    }

    @Test func buildInstructionsExcludesUnavailableSounds() {
        let manager = RecommendationManager()
        let sounds = [
            Sound(id: "rain", name: "Rain", category: .nature, fileName: "rain.m4a", isPremium: false, iconName: "cloud.rain"),
        ]
        let instructions = manager.buildInstructions(mode: .focus, availableSounds: sounds)

        #expect(instructions.contains("rain"))
        #expect(!instructions.contains("\"thunder\""))
    }

    // MARK: - Reset

    @Test func resetClearsState() {
        let manager = RecommendationManager()
        manager.errorMessage = "test error"
        manager.state = .error

        manager.reset()

        #expect(manager.state == .idle)
        #expect(manager.result == nil)
        #expect(manager.partialResult == nil)
        #expect(manager.errorMessage == nil)
    }
}
