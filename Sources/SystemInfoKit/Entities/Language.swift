import Foundation

enum Language {
    case automatic
    case chineseSimplified
    case english
    case french
    case german
    case japanese
    case korean

    var locale: Locale {
        switch self {
        case .automatic:
            Locale.current
        case .chineseSimplified:
            Locale(languageCode: .chinese, script: .hanSimplified)
        case .english:
            Locale(languageCode: .english)
        case .french:
            Locale(languageCode: .french)
        case .german:
            Locale(languageCode: .german)
        case .japanese:
            Locale(languageCode: .japanese)
        case .korean:
            Locale(languageCode: .korean)
        }
    }

    var bundle: Bundle? {
        if self != .automatic, let path = Bundle.module.path(forResource: locale.identifier, ofType: "lproj") {
            Bundle(path: path)
        } else {
            Bundle.module
        }
    }
}
