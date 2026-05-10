import Foundation

/// Tüm önyazı tipleri `Resources/TipNOnyazi.html` dosyalarından yüklenir.
enum BundledIntroHTML {
    static let tip1: String = load("Tip1Onyazi")
    static let tip2: String = load("Tip2Onyazi")
    static let tip3: String = load("Tip3Onyazi")
    static let tip4: String = load("Tip4Onyazi")
    static let tip5: String = load("Tip5Onyazi")

    private static func load(_ name: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "html"),
              let html = try? String(contentsOf: url, encoding: .utf8),
              !html.isEmpty
        else {
            assertionFailure("Eksik gömülü önyazı: \(name).html")
            return ""
        }
        return html
    }
}
