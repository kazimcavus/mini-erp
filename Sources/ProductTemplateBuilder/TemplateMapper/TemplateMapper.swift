import Foundation

final class TemplateMapper {
    private enum CellContent {
        case inheritBaseline
        case value(String)
    }

    func makeRows(
        products: [ProductEntry],
        baselineKeyedByHeader: [String: String],
        startingBarcode: String,
        variationRowsByProductID: [UUID: [VariationRow]],
        templateHeaders: [String]
    ) -> [TemplateRow] {
        var barcodeGenerator = BarcodeGenerator(startingBarcode: startingBarcode)

        return products.flatMap { product in
            let variations = variationRowsByProductID[product.id] ?? []
            let targetColors = product.resolvedOutputColors()

            return targetColors.flatMap { targetColor in
                variations.enumerated().map { variationIndex, variation in
                    let ordinal = variationIndex + 1
                    let barcode = barcodeGenerator.next()
                    var row: [String: String] = [:]
                    let phrase = product.sourceColorPhrase.trimmingCharacters(in: .whitespacesAndNewlines)

                    for header in templateHeaders {
                        let baseline = baselineKeyedByHeader[header] ?? ""
                        switch cellContent(
                            header: header,
                            product: product,
                            variation: variation,
                            barcode: barcode,
                            targetColor: targetColor,
                            phrase: phrase,
                            variationOrdinal: ordinal
                        ) {
                        case .inheritBaseline:
                            row[header] = baseline
                        case .value(let string):
                            row[header] = string
                        }
                    }
                    return TemplateRow(values: row)
                }
            }
        }
    }

    private func cellContent(
        header: String,
        product: ProductEntry,
        variation: VariationRow,
        barcode: String,
        targetColor: String,
        phrase: String,
        variationOrdinal: Int
    ) -> CellContent {
        let discountedRaw = bilgilerDerivedString(variation.discountedPrice, phrase: phrase, targetColor: targetColor)
        let discountedForExport = ListPriceCalculator.discountedPriceStringRoundedToNearestFive(discountedRaw)

        if matches(header, ["ACIKLAMA", "AÇIKLAMA", "DESCRIPTION"]) {
            return .value("")
        }
        if matches(header, ["STOKKODU", "STOK KODU"]) { return .value(product.stockCode) }
        if matches(header, ["URUNADI", "ÜRÜNADI", "URUN ADI", "ÜRÜN ADI", "PRODUCTNAME"]) { return .value(product.productName) }
        if matches(header, ["VARYASYONKODU", "VARYASYON KODU"]) {
            var code = bilgilerDerivedString(variation.variationCode, phrase: phrase, targetColor: targetColor)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if code.isEmpty {
                code = "\(product.stockCode)-\(variationOrdinal)"
            }
            return .value(code)
        }
        if matches(header, ["INDIRIMLIFIYAT", "İNDİRİMLİFİYAT", "INDIRIMLI FIYAT", "İNDİRİMLİ FİYAT"]) {
            return .value(discountedForExport)
        }
        if matches(header, ["SATISFIYATI", "SATIŞ FİYATI", "SATIS FIYATI"]) {
            return .value(
                ListPriceCalculator.listPriceString(
                    fromDiscounted: discountedForExport,
                    preset: product.strikeThroughDiscountPreset
                )
            )
        }
        if matches(header, ["OZELALAN1", "ÖZELALAN1", "OZEL ALAN 1", "ÖZEL ALAN 1"]) {
            return .value(stockPrefix(product.stockCode))
        }
        if matches(header, ["ONYAZI", "ÖNYAZI", "ON YAZI", "ÖN YAZI"]) {
            return .value(introHTML(for: product.introType))
        }
        if matches(header, ["KATEGORI", "KATEGORİ", "KATEGORILER", "KATEGORİLER", "CATEGORY"]) {
            return .value(product.category)
        }
        if matches(header, ["BREADCRUMB", "BREADCRUMBKAT", "KATEGORIYOLU", "KATEGORİ YOLU"]) {
            return .value(product.breadcrumb)
        }
        if matches(header, ["BARKOD", "BARCODE", "BARKODU", "GTIN", "EAN"]) {
            return .value(barcode)
        }
        if matches(header, ["RENK", "COLOR"]) {
            return .value(targetColor)
        }

        if let source = variation.values.first(where: { ExcelHeaderNormalizer.matches($0.key, header) })?.value {
            return .value(bilgilerDerivedString(source, phrase: phrase, targetColor: targetColor))
        }
        return .inheritBaseline
    }

    /// Bilgiler hücreleri: örnek Renk kelimesini değiştirir ve `Renk;Bej,Ölçü;…` içinde Renk tarafını hedef renkle günceller.
    private func bilgilerDerivedString(_ raw: String, phrase: String, targetColor: String) -> String {
        let afterPhrase = replacingPhrase(raw, source: phrase, target: targetColor)
        return replaceRenkSemicolonFragments(afterPhrase, targetColor: targetColor)
    }

    /// `Renk;…` ve `RENK ; …` vb. ilk virgül öncesindeki çiftleri hedef renkle günceller; `Ölçü;80x150` dokunulmaz.
    private func replaceRenkSemicolonFragments(_ value: String, targetColor: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"(?i)Renk\s*;\s*[^,]+"#, options: []) else {
            return value
        }
        let full = NSRange(location: 0, length: (value as NSString).length)
        let matchRanges = regex.matches(in: value, options: [], range: full).map(\.range)
        guard !matchRanges.isEmpty else { return value }

        var result = value
        for matchRange in matchRanges.reversed() {
            guard let swiftRange = Range(matchRange, in: result) else { continue }
            let fragment = String(result[swiftRange])
            guard let semi = fragment.firstIndex(of: ";") else {
                result.replaceSubrange(swiftRange, with: "Renk;\(targetColor)")
                continue
            }
            let keyPart = fragment[..<semi].trimmingCharacters(in: .whitespaces)
            let replacement = "\(keyPart);\(targetColor)"
            result.replaceSubrange(swiftRange, with: replacement)
        }
        return result
    }

    private func matches(_ header: String, _ candidates: [String]) -> Bool {
        candidates.contains { ExcelHeaderNormalizer.matches(header, $0) }
    }

    private func stockPrefix(_ stockCode: String) -> String {
        guard let range = stockCode.range(of: "R") else { return stockCode }
        return String(stockCode[..<range.lowerBound])
    }

    private func introHTML(for type: IntroType) -> String {
        EmbeddedCatalog.introTemplates.first { $0.id == type }?.html ?? ""
    }

    private func replacingPhrase(_ value: String, source phrase: String, target: String) -> String {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return value }
        return value.replacingOccurrences(
            of: trimmed,
            with: target,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: nil
        )
    }
}
