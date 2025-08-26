import Foundation
import Testing

@testable import SystemInfoKit

struct ByteDataTests {
    @Test(arguments: [
        .init(
            locale: Locale(languageCode: .english, languageRegion: .unitedStates),
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            locale: Locale(languageCode: .chinese, script: .hanSimplified),
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            locale: Locale(languageCode: .french, languageRegion: .france),
            expectedValue: 888.889,
            expectedUnit: "Go",
            expectedDescription: "888,9 Go"
        ),
        .init(
            locale: Locale(languageCode: .japanese, languageRegion: .japan),
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            locale: Locale(languageCode: .korean, languageRegion: .southKorea),
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
    ] as [LocaleByteDataProperty])
    func initialize(_ property: LocaleByteDataProperty) {
        let sut = ByteData(byteCount: 888888888888, locale: property.locale)
        #expect(sut.value == property.expectedValue)
        #expect(sut.unit == property.expectedUnit)
        #expect(sut.description == property.expectedDescription)
    }

    @Test(arguments: [
        .init(input: .zero, expectedValue: 0.0, expectedUnit: "B"),
        .init(input: 888, expectedValue: 888.0, expectedUnit: "B"),
        .init(input: 888888, expectedValue: 888.888, expectedUnit: "kB"),
        .init(input: 888888888, expectedValue: 888.889, expectedUnit: "MB"),
        .init(input: 888888888888, expectedValue: 888.889, expectedUnit: "GB"),
        .init(input: 888888888888888, expectedValue: 888.889, expectedUnit: "TB"),
        .init(input: 888888888888888888, expectedValue: 888.889, expectedUnit: "PB"),
        .init(input: Int64.max, expectedValue: 9.223, expectedUnit: "EB"),
    ] as [ScaleByteDataProperty])
    func scale(_ property: ScaleByteDataProperty) {
        let sut = ByteData(
            byteCount: property.input,
            locale: Locale(languageCode: .english, languageRegion: .unitedStates)
        )
        #expect(sut.value == property.expectedValue)
        #expect(sut.unit == property.expectedUnit)
    }
}

struct LocaleByteDataProperty {
    var locale: Locale
    var expectedValue: Double
    var expectedUnit: String
    var expectedDescription: String
}

struct ScaleByteDataProperty {
    var input: Int64
    var expectedValue: Double
    var expectedUnit: String
}
