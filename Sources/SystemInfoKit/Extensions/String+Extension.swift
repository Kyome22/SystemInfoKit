import RegexBuilder

extension String {
    func separate() -> (count: String, unit: String)? {
        let count = Reference(Substring.self)
        let unit = Reference(Substring.self)
        let regex = Regex {
            Capture(as: count) {
                ChoiceOf {
                    Regex {
                        OneOrMore(.digit)
                        ChoiceOf {
                            "."
                            ","
                        }
                        OneOrMore(.digit)
                    }
                    OneOrMore(.digit)
                }
            }
            Optionally(.whitespace)
            Capture(as: unit) {
                OneOrMore(.word)
            }
        }
        guard let match = firstMatch(of: regex) else { return nil }
        return (String(match[count]), String(match[unit]))
    }
}
