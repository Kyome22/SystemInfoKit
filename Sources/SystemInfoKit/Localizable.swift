import Foundation

protocol Localizable {
    var language: Language { get }

    func string(format: String, _ arguments: any CVarArg...) -> String
    func string(localized: String.LocalizationValue) -> String
}

extension Localizable {
    func string(format: String, _ arguments: any CVarArg...) -> String {
        String(format: format, locale: language.locale, arguments: arguments)
    }

    func string(localized: String.LocalizationValue) -> String {
        String(localized: localized, bundle: language.bundle)
    }
}
