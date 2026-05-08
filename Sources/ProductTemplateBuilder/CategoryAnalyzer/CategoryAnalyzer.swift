import Foundation

final class CategoryAnalyzer {
    private let reader = ExcelReader()

    func analyze(url: URL) throws -> CategoryAnalysis {
        let table = try reader.readFirstSheet(from: url)
        let tipler = try reader.readSheetIfExists(named: "tipler", from: url)
        return CategoryAnalysis(
            categories: uniqueValues(in: table, candidates: ["KATEGORI", "KATEGORİ", "Kategori", "KATEGORİLER"]),
            breadcrumbs: uniqueValues(in: table, candidates: ["BREADCRUMB", "Breadcrumb", "Kategori Breadcrumb", "KATEGORIYOLU", "KATEGORİ YOLU"]),
            introTypes: introTypes(from: tipler)
        )
    }

    private func uniqueValues(in table: WorkbookTable, candidates: [String]) -> [CategoryOption] {
        guard let header = table.headers.first(where: { header in candidates.contains(where: { ExcelHeaderNormalizer.matches(header, $0) }) }) else {
            return []
        }
        let values = Set(table.rows.compactMap { row -> String? in
            let value = row[header]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        })
        return values.sorted { $0.localizedStandardCompare($1) == .orderedAscending }.map(CategoryOption.init(value:))
    }

    private func introTypes(from table: WorkbookTable?) -> [IntroType: String] {
        var result: [IntroType: String] = [.tip1: "Tip 1", .tip2: "Tip 2", .tip3: "Tip 3"]
        guard let table else { return result }
        for type in IntroType.allCases {
            if let header = table.headers.first(where: { ExcelHeaderNormalizer.matches($0, type.rawValue) || ExcelHeaderNormalizer.matches($0, type.rawValue.replacingOccurrences(of: " ", with: "")) }),
               let value = table.rows.first?[header],
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result[type] = value
            }
        }
        return result
    }
}

struct CategoryAnalysis {
    var categories: [CategoryOption]
    var breadcrumbs: [CategoryOption]
    var introTypes: [IntroType: String]
}
