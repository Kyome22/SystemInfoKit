import Foundation
import Testing

@testable import SystemInfoKit

struct PercentageTests {
    @Test(arguments: [
        .init(language: .english, expectedDescription: "88.9%"),
        .init(language: .french, expectedDescription: "88,9%"),
        .init(language: .japanese, expectedDescription: "88.9%"),
        .init(language: .korean, expectedDescription: "88.9%"),
        .init(language: .simplifiedChinese, expectedDescription: "88.9%"),
    ] as [PercentageProperty])
    func initialize(_ property: PercentageProperty) {
        let sut = Percentage(rawValue: 0.8888, width: 4, language: property.language)
        #expect(sut.value == 88.9)
        #expect(sut.description == property.expectedDescription)
    }
}

struct PercentageProperty {
    var language: Language
    var expectedDescription: String
}
