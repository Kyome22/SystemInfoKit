import Foundation
import Testing

@testable import SystemInfoKit

struct PercentageTests {
    @Test(arguments: [
        .init(
            locale: Locale(languageCode: .english, languageRegion: .unitedStates),
            expectedDescription: "88.9%"
        ),
        .init(
            locale: Locale(languageCode: .chinese, script: .hanSimplified),
            expectedDescription: "88.9%"
        ),
        .init(
            locale: Locale(languageCode: .french, languageRegion: .france),
            expectedDescription: "88,9%"
        ),
        .init(
            locale: Locale(languageCode: .japanese, languageRegion: .japan),
            expectedDescription: "88.9%"
        ),
        .init(
            locale: Locale(languageCode: .korean, languageRegion: .southKorea),
            expectedDescription: "88.9%"
        ),
    ] as [PercentageProperty])
    func initialize(_ property: PercentageProperty) {
        let sut = Percentage(rawValue: 0.8888, locale: property.locale)
        #expect(sut.value == 88.9)
        #expect(sut.description == property.expectedDescription)
    }
}

struct PercentageProperty {
    var locale: Locale
    var expectedDescription: String
}
