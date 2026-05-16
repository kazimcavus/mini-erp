import Foundation

struct PriceUpdateExportResult {
    var headers: [String]
    var rows: [[String]]
    var matchedSKUCount: Int
    var unmatchedPriceSKUs: [String]
    var invalidPriceSKUs: [String]
}

final class PriceUpdateBuilder {
    func makeExport(
        productTable: WorkbookTable,
        priceTable: WorkbookTable,
        preset: StrikeThroughDiscountPreset
    ) throws -> PriceUpdateExportResult {
        let stockHeader = try requiredHeader(["STOKKODU", "STOK KODU"], in: productTable.headers, label: "ürün listesinde STOKKODU")
        let variationHeader = try requiredHeader(["VARYASYON"], in: productTable.headers, label: "ürün listesinde VARYASYON")
        let discountedHeader = try requiredHeader(["INDIRIMLIFIYAT", "İNDİRİMLİFİYAT", "INDIRIMLI FIYAT", "İNDİRİMLİ FİYAT"], in: productTable.headers, label: "ürün listesinde INDIRIMLIFIYAT")
        let listHeader = try requiredHeader(["SATISFIYATI", "SATIŞ FİYATI", "SATIS FIYATI"], in: productTable.headers, label: "ürün listesinde SATISFIYATI")

        let priceLookup = try makePriceLookup(from: priceTable)
        guard !priceLookup.pricesBySKU.isEmpty else {
            throw PriceUpdateBuilderError.noUsablePrices
        }

        var outputRows: [[String]] = []
        var matchedSKUs = Set<String>()
        var invalidMeasureRows: [String] = []

        for row in productTable.rows {
            let sku = (row[stockHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedSKU = Self.normalizedSKU(sku)
            guard !normalizedSKU.isEmpty, let squareMeterPrice = priceLookup.pricesBySKU[normalizedSKU] else { continue }

            let variation = row[variationHeader] ?? ""
            guard let squareMeters = Self.squareMeters(fromVariation: variation) else {
                invalidMeasureRows.append("\(sku.isEmpty ? "-" : sku) / \(variation.isEmpty ? "VARYASYON boş" : variation)")
                continue
            }

            let rawDiscounted = squareMeterPrice * squareMeters
            let discountedString = ListPriceCalculator.formatPlainTurkish(displayOf: rawDiscounted)
            let listString = Self.listPriceStringRoundedToNearestFive(fromDiscounted: rawDiscounted, preset: preset)

            var updatedRow = row
            updatedRow[discountedHeader] = discountedString
            updatedRow[listHeader] = listString
            outputRows.append(productTable.headers.map { updatedRow[$0] ?? "" })
            matchedSKUs.insert(normalizedSKU)
        }

        if !invalidMeasureRows.isEmpty {
            throw PriceUpdateBuilderError.invalidMeasureRows(invalidMeasureRows)
        }
        guard !outputRows.isEmpty else {
            throw PriceUpdateBuilderError.noMatchingRows
        }

        let unmatched = priceLookup.orderedValidSKUs
            .filter { !matchedSKUs.contains($0.normalized) }
            .map(\.original)

        return PriceUpdateExportResult(
            headers: productTable.headers,
            rows: outputRows,
            matchedSKUCount: matchedSKUs.count,
            unmatchedPriceSKUs: unmatched,
            invalidPriceSKUs: priceLookup.invalidPriceSKUs
        )
    }

    static func squareMeters(fromVariation raw: String) -> Decimal? {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:Ölçü|Olcu)\s*;\s*([0-9]+(?:[,.][0-9]+)?)\s*[xX×]\s*([0-9]+(?:[,.][0-9]+)?)"#,
            options: [.caseInsensitive]
        ) else { return nil }

        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, options: [], range: range),
              match.numberOfRanges >= 3,
              let widthRange = Range(match.range(at: 1), in: raw),
              let heightRange = Range(match.range(at: 2), in: raw),
              let width = ListPriceCalculator.parseDecimal(String(raw[widthRange])),
              let height = ListPriceCalculator.parseDecimal(String(raw[heightRange])),
              width > 0,
              height > 0
        else {
            return nil
        }

        return (width * height) / Decimal(10000)
    }

    private struct PriceLookup {
        var pricesBySKU: [String: Decimal]
        var orderedValidSKUs: [(normalized: String, original: String)]
        var invalidPriceSKUs: [String]
    }

    private func makePriceLookup(from table: WorkbookTable) throws -> PriceLookup {
        let skuHeader = try requiredHeader(["SKU", "STOKKODU", "STOK KODU"], in: table.headers, label: "fiyat listesinde SKU")
        let priceHeader = try requiredHeader(
            ["FIYAT", "FİYAT", "M2 FIYATI", "M2 FİYATI", "M² FIYATI", "M² FİYATI", "M FIYATI", "M FİYATI", "METREKARE FIYATI", "METREKARE FİYATI"],
            in: table.headers,
            label: "fiyat listesinde Fiyat"
        )

        var pricesBySKU: [String: Decimal] = [:]
        var orderedValidSKUs: [(normalized: String, original: String)] = []
        var invalidPriceSKUs: [String] = []

        for row in table.rows {
            let sku = (row[skuHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = Self.normalizedSKU(sku)
            guard !normalized.isEmpty else { continue }

            let priceRaw = row[priceHeader] ?? ""
            guard let price = ListPriceCalculator.parseDecimal(priceRaw), price > 0 else {
                invalidPriceSKUs.append(sku)
                continue
            }

            if pricesBySKU[normalized] == nil {
                pricesBySKU[normalized] = price
                orderedValidSKUs.append((normalized: normalized, original: sku))
            }
        }

        return PriceLookup(pricesBySKU: pricesBySKU, orderedValidSKUs: orderedValidSKUs, invalidPriceSKUs: invalidPriceSKUs)
    }

    private func requiredHeader(_ candidates: [String], in headers: [String], label: String) throws -> String {
        if let header = headers.first(where: { header in
            candidates.contains { ExcelHeaderNormalizer.matches(header, $0) }
        }) {
            return header
        }
        throw PriceUpdateBuilderError.missingRequiredColumn(label)
    }

    private static func normalizedSKU(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(with: Locale(identifier: "en_US_POSIX"))
    }

    private static func listPriceStringRoundedToNearestFive(fromDiscounted discounted: Decimal, preset: StrikeThroughDiscountPreset) -> String {
        let factor = preset.discountedAsFractionOfList
        guard discounted > 0, factor > 0 else { return "" }
        let rawList = discounted / factor
        let roundedList = ListPriceCalculator.roundToNearestMultiple(of: Decimal(5), value: rawList)
        return ListPriceCalculator.formatPlainTurkish(displayOf: roundedList)
    }
}

enum PriceUpdateBuilderError: LocalizedError {
    case missingRequiredColumn(String)
    case noUsablePrices
    case noMatchingRows
    case invalidMeasureRows([String])

    var errorDescription: String? {
        switch self {
        case .missingRequiredColumn(let column):
            return "Fiyat güncelleme için gerekli kolon bulunamadı: \(column)"
        case .noUsablePrices:
            return "Fiyat listesinde kullanılabilir SKU ve fiyat satırı bulunamadı."
        case .noMatchingRows:
            return "Fiyat listesindeki SKU'lar ürün listesinde bulunamadı."
        case .invalidMeasureRows(let rows):
            let preview = rows.prefix(5).joined(separator: " · ")
            let suffix = rows.count > 5 ? " · …" : ""
            return "Ölçüsü okunamayan eşleşmiş ürün satırı var: \(preview)\(suffix)"
        }
    }
}
