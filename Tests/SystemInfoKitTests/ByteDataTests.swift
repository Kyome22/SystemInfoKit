import Foundation
import Testing

@testable import SystemInfoKit

struct ByteDataTests {
    @Test(arguments: [
        .init(
            locale: Locale(languageCode: .english, languageRegion: .unitedStates),
            expectedValue: 888.89,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            locale: Locale(languageCode: .chinese, script: .hanSimplified),
            expectedValue: 888.89,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            locale: Locale(languageCode: .french, languageRegion: .france),
            expectedValue: 888.89,
            expectedUnit: "Go",
            expectedDescription: "888,9 Go"
        ),
        .init(
            locale: Locale(languageCode: .japanese, languageRegion: .japan),
            expectedValue: 888.89,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            locale: Locale(languageCode: .korean, languageRegion: .southKorea),
            expectedValue: 888.89,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
    ] as [ByteDataProperty])
    func initialize(_ property: ByteDataProperty) async {
        let sut = ByteData(byteCount: 888888888888, locale: property.locale)
        #expect(sut.value == property.expectedValue)
        #expect(sut.unit == property.expectedUnit)
        #expect(sut.description == property.expectedDescription)
    }
}

struct ByteDataProperty {
    var locale: Locale
    var expectedValue: Double
    var expectedUnit: String
    var expectedDescription: String
}
