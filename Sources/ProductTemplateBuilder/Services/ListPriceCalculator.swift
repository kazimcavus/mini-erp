import Foundation

/// İndirimli fiyattan “üstü çizili” (liste) fiyat: liste × (1 − oran) = indirimli.
enum StrikeThroughDiscountPreset: String, CaseIterable, Identifiable, Hashable {
    /// İndirimli = liste × 0,8  →  liste = indirimli / 0,8
    case percentOff20
    /// İndirimli = liste × 0,5  →  liste = indirimli / 0,5
    case percentOff50

    var id: String { rawValue }

    var rawValue: String {
        switch self {
        case .percentOff20: return "20"
        case .percentOff50: return "50"
        }
    }

    var label: String {
        switch self {
        case .percentOff20: return "%20 indirim (liste geri hesapla)"
        case .percentOff50: return "%50 indirim (liste geri hesapla)"
        }
    }

    /// İndirimli fiyat = tam fiyat × çarpan
    var discountedAsFractionOfList: Decimal {
        switch self {
        case .percentOff20: return Decimal(string: "0.8")!
        case .percentOff50: return Decimal(string: "0.5")!
        }
    }
}

enum ListPriceCalculator {
    /// Türkçe / basit biçimli fiyat dizgesini sayıya çevirir.
    static func parseDecimal(_ raw: String) -> Decimal? {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        t = t.replacingOccurrences(of: "₺", with: "")
        t = t.replacingOccurrences(of: "TL", with: "", options: [.caseInsensitive, .diacriticInsensitive])
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }

        if t.contains(",") && t.contains(".") {
            t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else if t.contains(",") {
            t = t.replacingOccurrences(of: ",", with: ".")
        }
        return Decimal(string: t, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Elle doldurulmuş şablondaki gibi: binlik ayraç yok, ondalık `,`, gereksiz sondaki sıfırlar düşer.
    static func formatPlainTurkish(displayOf value: Decimal) -> String {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "tr_TR")
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = false
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        guard var s = nf.string(from: NSDecimalNumber(decimal: value)) else { return "" }
        if s.contains(",") {
            while s.last == "0" {
                s.removeLast()
            }
            if s.last == "," {
                s.removeLast()
            }
        }
        return s
    }

    /// Hücre metni sayıya çevrilebiliyorsa aynı Türkçe düzene getirir; metin veya boşsa olduğu gibi bırakır.
    static func formatPlainTurkishIfNumeric(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let d = parseDecimal(trimmed) else { return raw }
        return formatPlainTurkish(displayOf: d)
    }

    /// En yakın `step` katına yuvarlar (örn. step = 5 → …1270, 1275, 1280…).
    static func roundToNearestMultiple(of step: Decimal, value: Decimal) -> Decimal {
        guard step > 0 else { return value }
        let divided = value / step
        var quotient = divided
        var roundedQuotient = Decimal()
        NSDecimalRound(&roundedQuotient, &quotient, 0, .plain)
        return roundedQuotient * step
    }

    /// İndirimli fiyat yazılırken: sayı ise en yakın 5 TL’ye yuvarlanır; metin ise dokunulmaz (Türkçe biçimde yazılır).
    static func discountedPriceStringRoundedToNearestFive(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let d = parseDecimal(trimmed) else { return raw }
        let rounded = roundToNearestMultiple(of: Decimal(5), value: d)
        return formatPlainTurkish(displayOf: rounded)
    }

    /// İndirimli fiyattan liste (üstü çizili) fiyatı hesaplar; aynı biçimle döner.
    static func listPriceString(fromDiscounted discountedRaw: String, preset: StrikeThroughDiscountPreset) -> String {
        let trimmed = discountedRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let discounted = parseDecimal(trimmed), discounted > 0 else { return "" }

        let factor = preset.discountedAsFractionOfList
        guard factor > 0 else { return "" }

        var list = discounted / factor
        var rounded = Decimal()
        NSDecimalRound(&rounded, &list, 2, .plain)
        return formatPlainTurkish(displayOf: rounded)
    }
}
