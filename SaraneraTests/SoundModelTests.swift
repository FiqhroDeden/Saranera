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
        #expect(Sound.freeSounds.count == 12)
    }

    @Test func catalogHasPremiumSounds() {
        #expect(Sound.premiumSounds.count == 20)
    }

    @Test func catalogTotalIs32Sounds() {
        #expect(Sound.catalog.count == 32)
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

    @Test func freeSoundsHaveNilPackID() {
        for sound in Sound.freeSounds {
            #expect(sound.packID == nil)
            #expect(sound.isFree == true)
        }
    }

    @Test func premiumSoundsHavePackID() {
        for sound in Sound.premiumSounds {
            #expect(sound.packID != nil)
            #expect(sound.isFree == false)
            #expect(sound.isPremium == true)
        }
    }

    @Test func premiumSoundsHavePreviewFileName() {
        for sound in Sound.premiumSounds {
            #expect(sound.previewFileName != nil)
        }
    }

    // MARK: - Sound Grouping

    @Test func soundsGroupByCategory() {
        let grouped = Sound.grouped
        #expect(grouped[.nature]?.count == 12)
        #expect(grouped[.ambient]?.count == 7)
        #expect(grouped[.environment]?.count == 7)
        #expect(grouped[.urban]?.count == 6)
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

    // MARK: - SoundPack Catalog

    @Test func soundPackCatalogHasFivePacks() {
        #expect(SoundPack.catalog.count == 5)
    }

    @Test func soundPacksHaveUniqueIDs() {
        let ids = SoundPack.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func soundPackSoundsExistInCatalog() {
        let allSoundIDs = Set(Sound.catalog.map(\.id))
        for pack in SoundPack.catalog {
            for soundID in pack.soundIDs {
                #expect(allSoundIDs.contains(soundID), "Sound '\(soundID)' from pack '\(pack.id)' not found in Sound.catalog")
            }
        }
    }

    @Test func soundPackLookupBySoundID() {
        let pack = SoundPack.pack(for: "drizzle")
        #expect(pack != nil)
        #expect(pack?.id == "app.fiqhrodedhen.Saranera.pack.rainy_day")
    }

    @Test func soundPackLookupReturnsNilForFreeSound() {
        let pack = SoundPack.pack(for: "rain")
        #expect(pack == nil)
    }

    @Test func eachPackHasFourSounds() {
        for pack in SoundPack.catalog {
            #expect(pack.soundIDs.count == 4, "Pack '\(pack.id)' should have 4 sounds but has \(pack.soundIDs.count)")
        }
    }
}
