import Foundation

protocol SystemRepository: Sendable, Localizable {
    init(_ dependencies: Dependencies, language: Language)
    func update()
    func reset()
}

extension SystemRepository {
    init(_ dependencies: Dependencies, language: Language = .automatic) {
        self.init(dependencies, language: language)
    }
}
