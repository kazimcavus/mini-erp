import Foundation

final class TechnicalDetailsBuilder {
    private let technicalProperties: [(name: String, candidates: [String])] = [
        ("Taban", ["Taban"]),
        ("Üretim Şekli", ["Üretim Şekli", "Uretim Sekli", "ÜretimSekli"]),
        ("Şekil", ["Şekil", "Sekil"]),
        ("Materyal", ["Materyal", "Malzeme"]),
        ("Hav Yüksekliği", ["Hav Yüksekliği", "Hav Yuksekligi", "Hav Yüksekliği (mm)", "Hav"]),
        ("Saçak Tipi", ["Saçak Tipi", "Sacak Tipi", "Saçak", "Sacak"]),
    ]

    private let originProperty = "Menşei"
    private let originValue = "Türkiye'de üretilmiştir."

    func products(from ticimaxTable: WorkbookTable, sourceTable: WorkbookTable) throws -> (products: [TechnicalDetailProductSelection], missingSourceStockCodes: [String]) {
        let ticimaxStockHeader = try requiredHeader(["STOKKODU", "STOK KODU"], in: ticimaxTable.headers, label: "Ürün listesinde stok kodu")
        let cardIDHeader = try requiredHeader(["URUNKARTIID", "URUN KART ID", "ÜRÜN KART ID"], in: ticimaxTable.headers, label: "Ürün listesinde ürün kartı kimliği")
        let productNameHeader = try requiredHeader(["URUNADI", "ÜRÜNADI", "URUN ADI", "ÜRÜN ADI"], in: ticimaxTable.headers, label: "Ürün listesinde ürün adı")
        let sourceStockHeader = try requiredHeader(["STOKKODU", "STOK KODU"], in: sourceTable.headers, label: "Ürünler listesinde stok kodu")

        let sourceStockCodes = Set(sourceTable.rows.map { normalizedStock($0[sourceStockHeader] ?? "") }.filter { !$0.isEmpty })
        var seen = Set<String>()
        var products: [TechnicalDetailProductSelection] = []
        var missing: [String] = []

        for row in ticimaxTable.rows {
            let stockCode = (row[ticimaxStockHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = normalizedStock(stockCode)
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)

            if !sourceStockCodes.contains(normalized) {
                missing.append(stockCode)
                continue
            }

            products.append(
                TechnicalDetailProductSelection(
                    productCardID: (row[cardIDHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                    stockCode: stockCode,
                    productName: (row[productNameHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        }

        return (products, missing)
    }

    func makeRows(
        ticimaxTable: WorkbookTable,
        sourceTable: WorkbookTable,
        originStockCodes: Set<String>
    ) throws -> [TechnicalDetailRow] {
        let sourceStockHeader = try requiredHeader(["STOKKODU", "STOK KODU"], in: sourceTable.headers, label: "Ürünler listesinde stok kodu")
        var sourceRowsByStock: [String: [String: String]] = [:]
        for row in sourceTable.rows {
            let stock = normalizedStock(row[sourceStockHeader] ?? "")
            guard !stock.isEmpty, sourceRowsByStock[stock] == nil else { continue }
            sourceRowsByStock[stock] = row
        }

        let selectable = try products(from: ticimaxTable, sourceTable: sourceTable).products
        return selectable.flatMap { product -> [TechnicalDetailRow] in
            guard let sourceRow = sourceRowsByStock[normalizedStock(product.stockCode)] else { return [] }
            var rows: [TechnicalDetailRow] = []

            for item in technicalProperties {
                let value = value(for: item.candidates, in: sourceRow).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                rows.append(row(product: product, property: item.name, value: value))
            }

            if originStockCodes.contains(product.stockCode) {
                rows.append(row(product: product, property: originProperty, value: originValue))
            }

            return rows
        }
    }

    private func row(product: TechnicalDetailProductSelection, property: String, value: String) -> TechnicalDetailRow {
        TechnicalDetailRow(
            productCardID: product.productCardID,
            stockCode: product.stockCode,
            productName: product.productName,
            definition: "Halı Özellikleri",
            property: property,
            value: value
        )
    }

    private func value(for candidates: [String], in row: [String: String]) -> String {
        for candidate in candidates {
            if let match = row.first(where: { ExcelHeaderNormalizer.matches($0.key, candidate) })?.value {
                return match
            }
        }
        return ""
    }

    private func requiredHeader(_ candidates: [String], in headers: [String], label: String) throws -> String {
        if let header = headers.first(where: { header in
            candidates.contains { ExcelHeaderNormalizer.matches(header, $0) }
        }) {
            return header
        }
        throw TechnicalDetailsBuilderError.missingRequiredColumn(label)
    }

    private func normalizedStock(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(with: Locale(identifier: "en_US_POSIX"))
    }
}

enum TechnicalDetailsBuilderError: LocalizedError {
    case missingRequiredColumn(String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredColumn(let column):
            "Teknik detaylar için gerekli kolon bulunamadı: \(column)"
        }
    }
}
