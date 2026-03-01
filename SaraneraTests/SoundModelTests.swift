import Testing
@testable import Saranera

@MainActor
struct SoundModelTests {

    // MARK: - SoundCategory

    @Test func soundCategoryHasFourCases() {
        #expect(SoundCategory.allCases.count == 4)
    }

    @Test func soundCategoryDisplayNames() {
        #expect(SoundCategory.nature.displayName == "Nature")
        #expect(SoundCategory.ambient.displayName == "Ambient")
        #expect(SoundCategory.environment.displayName == "Environment")
        #expect(SoundCategory.urban.displayName == "Urban")
    }

    // MARK: - Sound Catalog

    @Test func catalogHas12FreeSounds() {
        #expect(Sound.catalog.count == 12)
    }

    @Test func catalogHasNoPremiuimSounds() {
        let premiumSounds = Sound.catalog.filter { $0.isPremium }
        #expect(premiumSounds.isEmpty)
    }

    @Test func catalogCoversAllCategories() {
        let categories = Set(Sound.catalog.map(\.category))
        #expect(categories.count == 4)
    }

    @Test func catalogSoundsHaveUniqueIDs() {
        let ids = Sound.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func soundLookupByID() {
        let rain = Sound.catalog.first { $0.id == "rain" }
        #expect(rain != nil)
        #expect(rain?.name == "Rain")
        #expect(rain?.category == .nature)
        #expect(rain?.iconName == "cloud.rain")
    }

    // MARK: - Sound Grouping

    @Test func soundsGroupByCategory() {
        let grouped = Sound.grouped
        #expect(grouped[.nature]?.count == 4)
        #expect(grouped[.ambient]?.count == 3)
        #expect(grouped[.environment]?.count == 3)
        #expect(grouped[.urban]?.count == 2)
    }

    // MARK: - SoundMix

    @Test func soundMixCreation() {
        let mix = SoundMix(
            name: "Rainy Cafe",
            components: [
                MixComponent(soundID: "rain", volume: 0.8),
                MixComponent(soundID: "coffee_shop", volume: 0.6)
            ]
        )
        #expect(mix.name == "Rainy Cafe")
        #expect(mix.components.count == 2)
        #expect(mix.isFavorite == false)
    }
}
