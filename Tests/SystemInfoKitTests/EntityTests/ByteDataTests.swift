import Foundation
import Testing

@testable import SystemInfoKit

struct ByteDataTests {
    @Test(arguments: [
        .init(
            language: .chineseSimplified,
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            language: .english,
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            language: .french,
            expectedValue: 888.889,
            expectedUnit: "Go",
            expectedDescription: "888,9 Go"
        ),
        .init(
            language: .german,
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888,9 GB"
        ),
        .init(
            language: .japanese,
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
        .init(
            language: .korean,
            expectedValue: 888.889,
            expectedUnit: "GB",
            expectedDescription: "888.9 GB"
        ),
    ] as [ByteDataProperty])
    func initialize(_ property: ByteDataProperty) {
        let sut = ByteData(byteCount: 888888888888, language: property.language)
        let readableValue = sut.readableValue
        #expect(readableValue.value == property.expectedValue)
        #expect(readableValue.unit == property.expectedUnit)
        #expect(sut.description == property.expectedDescription)
    }

    @Test(arguments: [
        .init(input: .zero, expectedValue: 0.0, expectedUnit: "B"),
        .init(input: 888, expectedValue: 888.0, expectedUnit: "B"),
        .init(input: 888888, expectedValue: 888.888, expectedUnit: "kB"),
        .init(input: 888888800, expectedValue: 888.889, expectedUnit: "MB"),
        .init(input: 888888800000, expectedValue: 888.889, expectedUnit: "GB"),
        .init(input: 888888800000000, expectedValue: 888.889, expectedUnit: "TB"),
        .init(input: 888888800000000000, expectedValue: 888.889, expectedUnit: "PB"),
        .init(input: 888888800000000000000, expectedValue: 888.889, expectedUnit: "EB"),
    ] as [ScaleByteDataProperty])
    func scale(_ property: ScaleByteDataProperty) {
        let sut = ByteData(byteCount: property.input, language: .english)
        let readableValue = sut.readableValue
        #expect(readableValue.value == property.expectedValue)
        #expect(readableValue.unit == property.expectedUnit)
    }
}

struct ByteDataProperty {
    var language: Language
    var expectedValue: Double
    var expectedUnit: String
    var expectedDescription: String
}

struct ScaleByteDataProperty {
    var input: Double
    var expectedValue: Double
    var expectedUnit: String
}
