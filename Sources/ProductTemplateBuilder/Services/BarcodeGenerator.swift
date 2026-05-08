import Foundation

struct BarcodeGenerator {
    private let width: Int
    private var current: Decimal?

    init(startingBarcode: String) {
        let trimmed = startingBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.width = trimmed.count
        self.current = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX"))
    }

    mutating func next() -> String {
        guard let value = current else { return "" }
        let output = NSDecimalNumber(decimal: value).stringValue
        current = value + Decimal(1)
        if output.count < width {
            return String(repeating: "0", count: width - output.count) + output
        }
        return output
    }
}
