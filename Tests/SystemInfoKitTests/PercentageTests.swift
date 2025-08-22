import Foundation
import Testing

@testable import SystemInfoKit

struct PercentageTests {
    @Test(arguments: [
        .init(
            locale: Locale(languageCode: .english, languageRegion: .unitedStates),
            expectedValue: 88.9,
            expectedDescription: "88.9%"
        ),
        .init(
            locale: Locale(languageCode: .chinese, script: .hanSimplified),
            expectedValue: 88.9,
            expectedDescription: "88.9%"
        ),
        .init(
            locale: Locale(languageCode: .french, languageRegion: .france),
            expectedValue: 88.9,
            expectedDescription: "88,9%"
        ),
        .init(
            locale: Locale(languageCode: .japanese, languageRegion: .japan),
            expectedValue: 88.9,
            expectedDescription: "88.9%"
        ),
        .init(
            locale: Locale(languageCode: .korean, languageRegion: .southKorea),
            expectedValue: 88.9,
            expectedDescription: "88.9%"
        ),
    ] as [PercentageProperty])
    func initialize(_ property: PercentageProperty) async {
        let sut = Percentage(rawValue: 0.8888, locale: property.locale)
        #expect(sut.value == property.expectedValue)
        #expect(sut.description == property.expectedDescription)
    }
}

struct PercentageProperty {
    var locale: Locale
    var expectedValue: Double
    var expectedDescription: String
}
