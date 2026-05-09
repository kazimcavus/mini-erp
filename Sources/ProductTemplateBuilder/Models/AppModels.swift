import Foundation

struct FileSettings: Equatable {
    var variationURL: URL?
}

struct ProductDraftRow: Identifiable, Equatable {
    let id = UUID()
    var stockCode = ""
    var productName = ""
    var color = ""

    var isEmpty: Bool {
        stockCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        color.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ProductEntry: Identifiable, Equatable {
    let id: UUID
    var stockCode: String
    var productName: String
    /// Used when `outputColorVariants` is empty (single-color export).
    var color: String
    /// Text to replace in Bilgiler / varyasyon alanları (ör. `Krem`). Empty = no phrase replacement.
    var sourceColorPhrase: String
    /// When non-empty, each value becomes one exported color (rows × variants). When empty, `color` is used once.
    var outputColorVariants: [String]
    var introType: IntroType
    var category: String
    var breadcrumb: String
    var variationFileURL: URL
    /// İndirimli fiyattan SATISFIYATI (liste) geri hesap oranı.
    var strikeThroughDiscountPreset: StrikeThroughDiscountPreset

    /// Renkler dışa aktarım sırası.
    func resolvedOutputColors() -> [String] {
        let trimmed = outputColorVariants.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if trimmed.isEmpty {
            return [color.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        return trimmed
    }

    init(
        id: UUID = UUID(),
        stockCode: String,
        productName: String,
        color: String,
        sourceColorPhrase: String = "",
        outputColorVariants: [String] = [],
        introType: IntroType,
        category: String,
        breadcrumb: String,
        variationFileURL: URL,
        strikeThroughDiscountPreset: StrikeThroughDiscountPreset = .percentOff20
    ) {
        self.id = id
        self.stockCode = stockCode
        self.productName = productName
        self.color = color
        self.sourceColorPhrase = sourceColorPhrase
        self.outputColorVariants = outputColorVariants
        self.introType = introType
        self.category = category
        self.breadcrumb = breadcrumb
        self.variationFileURL = variationFileURL
        self.strikeThroughDiscountPreset = strikeThroughDiscountPreset
    }
}

enum IntroType: String, CaseIterable, Identifiable {
    case tip1 = "Tip 1"
    case tip2 = "Tip 2"
    case tip3 = "Tip 3"

    var id: String { rawValue }
}

struct CategoryOption: Identifiable, Hashable {
    var id: String { value }
    let value: String
}

enum AppDefaults {
    static let mainTemplateURL = URL(fileURLWithPath: "/Users/kazimcavus/Downloads/2501-Urun-Yukleme-Sablon-1-Son.xlsx")
}

struct VariationRow: Equatable {
    var values: [String: String]
    var variationCode: String {
        let direct = value(for: [
            "VARYASYONKODU",
            "VARYASYON KODU",
            "VARYASYONKOD",
            "Varyasyon Kodu",
            "VaryasyonKodu",
            "VARYASYON KOD",
        ])
        if !direct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return direct }

        guard let (_, val) = values.first(where: { pair in
            let key = pair.key
            let val = pair.value
            let n = ExcelHeaderNormalizer.normalize(key)
            let nonempty = !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            guard nonempty else { return false }
            return n.contains("VARYASYON") && n.contains("KOD") && !n.contains("INDIRIM")
        }) else { return "" }

        return val
    }
    var discountedPrice: String {
        value(for: [
            "Fiyatlar",
            "FIYATLAR",
            "FİYATLAR",
            "INDIRIMLIFIYAT",
            "İNDİRİMLİFİYAT",
            "INDIRIMLI FIYAT",
            "İndirimli Fiyat",
            "M2 fiyatı",
            "M2 FIYATI",
            "M2 FİYATI",
        ])
    }

    func value(for candidates: [String]) -> String {
        for candidate in candidates {
            if let match = values.first(where: { ExcelHeaderNormalizer.matches($0.key, candidate) })?.value {
                return match
            }
        }
        return ""
    }
}

struct WorkbookTable {
    var sheetName: String
    var headers: [String]
    var rows: [[String: String]]
}

struct TemplateRow {
    var values: [String: String]
}

struct RelatedProductRow: Equatable {
    var productCardID: String
    var relatedProductCardID: String
}

struct TechnicalDetailRow: Equatable {
    var productCardID: String
    var stockCode: String
    var productName: String
    var definition: String
    var property: String
    var value: String
}

struct TechnicalDetailProductSelection: Identifiable, Equatable {
    var id: String { stockCode }
    var productCardID: String
    var stockCode: String
    var productName: String
}

struct TechnicalDetailDraft: Identifiable {
    let id = UUID()
    var ticimaxTable: WorkbookTable
    var sourceTable: WorkbookTable
    var products: [TechnicalDetailProductSelection]
    var selectedOriginStockCodes: Set<String>
    var missingSourceStockCodes: [String]
}

enum AppStatus: Equatable {
    case idle
    case success(String)
    case failure(String)
    case warning(String)

    var message: String? {
        switch self {
        case .idle: nil
        case .success(let message), .failure(let message), .warning(let message): message
        }
    }
}
