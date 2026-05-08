import Foundation

enum ExcelHeaderNormalizer {
    static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "i")
            .uppercased(with: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    static func matches(_ lhs: String, _ rhs: String) -> Bool {
        normalize(lhs) == normalize(rhs)
    }
}
