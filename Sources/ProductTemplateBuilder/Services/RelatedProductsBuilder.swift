import Foundation

final class RelatedProductsBuilder {
    func makeRows(from table: WorkbookTable) throws -> [RelatedProductRow] {
        let ozelAlanHeader = try requiredHeader(["OZELALAN1", "OZEL ALAN 1", "ÖZELALAN1", "ÖZEL ALAN 1"], in: table.headers)
        let cardIDHeader = try requiredHeader(["URUNKARTIID", "URUN KART ID", "ÜRÜN KART ID"], in: table.headers)

        var cardIDsByGroup: [String: [String]] = [:]
        for row in table.rows {
            let group = (row[ozelAlanHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let cardID = (row[cardIDHeader] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !group.isEmpty, !cardID.isEmpty else { continue }

            var cardIDs = cardIDsByGroup[group] ?? []
            if !cardIDs.contains(cardID) {
                cardIDs.append(cardID)
            }
            cardIDsByGroup[group] = cardIDs
        }

        return cardIDsByGroup.keys.sorted(by: localizedNumericLessThan).flatMap { group -> [RelatedProductRow] in
            let ascending = (cardIDsByGroup[group] ?? []).sorted(by: localizedNumericLessThan)
            guard ascending.count > 1 else { return [] }
            let descending = ascending.reversed()

            return ascending.flatMap { relatedID in
                descending.map { productID in
                    RelatedProductRow(productCardID: productID, relatedProductCardID: relatedID)
                }
            }
        }
    }

    private func requiredHeader(_ candidates: [String], in headers: [String]) throws -> String {
        if let header = headers.first(where: { header in
            candidates.contains { ExcelHeaderNormalizer.matches(header, $0) }
        }) {
            return header
        }
        throw RelatedProductsBuilderError.missingRequiredColumn(candidates[0])
    }

    private func localizedNumericLessThan(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.numeric, .caseInsensitive], locale: Locale(identifier: "tr_TR")) == .orderedAscending
    }
}

enum RelatedProductsBuilderError: LocalizedError {
    case missingRequiredColumn(String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredColumn(let column):
            "İlgili ürünler için gerekli kolon bulunamadı: \(column)"
        }
    }
}
