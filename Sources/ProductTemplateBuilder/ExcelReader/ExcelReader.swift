import Foundation

final class ExcelReader {
    func readFirstSheet(from url: URL) throws -> WorkbookTable {
        let archive = try XLSXArchive(sourceURL: url)
        let sheet = try archive.sheetPath(first: true)
        return try readTable(archive: archive, sheetName: sheet.name, sheetPath: sheet.path)
    }

    func readSheet(named name: String, from url: URL) throws -> WorkbookTable {
        let archive = try XLSXArchive(sourceURL: url)
        let sheet = try archive.sheetPath(named: name)
        return try readTable(archive: archive, sheetName: sheet.name, sheetPath: sheet.path)
    }

    func readSheetIfExists(named name: String, from url: URL) throws -> WorkbookTable? {
        let archive = try XLSXArchive(sourceURL: url)
        guard let sheet = try archive.allSheetPaths().first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            return nil
        }
        return try readTable(archive: archive, sheetName: sheet.name, sheetPath: sheet.path)
    }

    func readHeaders(fromTemplate url: URL) throws -> [String] {
        try readFirstSheet(from: url).headers
    }

    /// First spreadsheet row after the header row, keyed by header name (baseline / “sabit” values).
    /// Unlike `readTable`, this keeps the row even if every column is blank.
    func readBaselineRow(fromTemplate url: URL) throws -> [String: String] {
        let archive = try XLSXArchive(sourceURL: url)
        let sheet = try archive.sheetPath(first: true)
        return try readBaselineKeyedByHeaders(archive: archive, sheetPath: sheet.path)
    }

    private func readBaselineKeyedByHeaders(archive: XLSXArchive, sheetPath: String) throws -> [String: String] {
        let sharedStrings = try readSharedStrings(archive: archive)
        let document = try archive.document(at: sheetPath)
        let rowNodes = try document.nodes(forXPath: "//*[local-name()='sheetData']/*[local-name()='row']")
        let parsedRows = rowNodes.compactMap { node -> (Int, [String: String])? in
            guard let row = node as? XMLElement else { return nil }
            let rowIndex = Int(row.attribute(forName: "r")?.stringValue ?? "") ?? 0
            var values: [String: String] = [:]
            for case let cell as XMLElement in row.children ?? [] where cell.localName == "c" || cell.name == "c" {
                guard let ref = cell.attribute(forName: "r")?.stringValue else { continue }
                let column = Self.columnLetters(from: ref)
                values[column] = cellValue(cell, sharedStrings: sharedStrings)
            }
            return (rowIndex, values)
        }
        guard let header = parsedRows.sorted(by: { $0.0 < $1.0 }).first else { throw XLSXError.missingHeaderRow }
        let columns = header.1.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
        let firstDataSorted = parsedRows
            .filter { $0.0 > header.0 }
            .sorted(by: { $0.0 < $1.0 })

        guard let firstDataRow = firstDataSorted.first else { return [:] }

        var row: [String: String] = [:]
        for (column, headerName) in columns {
            row[headerName] = firstDataRow.1[column] ?? ""
        }
        return row
    }

    private func readTable(archive: XLSXArchive, sheetName: String, sheetPath: String) throws -> WorkbookTable {
        let sharedStrings = try readSharedStrings(archive: archive)
        let document = try archive.document(at: sheetPath)
        let rowNodes = try document.nodes(forXPath: "//*[local-name()='sheetData']/*[local-name()='row']")
        let parsedRows = rowNodes.compactMap { node -> (Int, [String: String])? in
            guard let row = node as? XMLElement else { return nil }
            let rowIndex = Int(row.attribute(forName: "r")?.stringValue ?? "") ?? 0
            var values: [String: String] = [:]
            for case let cell as XMLElement in row.children ?? [] where cell.localName == "c" || cell.name == "c" {
                guard let ref = cell.attribute(forName: "r")?.stringValue else { continue }
                let column = Self.columnLetters(from: ref)
                values[column] = cellValue(cell, sharedStrings: sharedStrings)
            }
            return (rowIndex, values)
        }
        guard let header = parsedRows.sorted(by: { $0.0 < $1.0 }).first else { throw XLSXError.missingHeaderRow }
        let headers = header.1.sorted(by: { Self.columnNumber($0.key) < Self.columnNumber($1.key) }).map(\.value)
        let columns = header.1.reduce(into: [String: String]()) { $0[$1.key] = $1.value }

        let rows = parsedRows
            .filter { $0.0 > header.0 }
            .sorted(by: { $0.0 < $1.0 })
            .map { parsed -> [String: String] in
                var row: [String: String] = [:]
                for (column, header) in columns {
                    row[header] = parsed.1[column] ?? ""
                }
                return row
            }
            .filter { row in row.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
        return WorkbookTable(sheetName: sheetName, headers: headers, rows: rows)
    }

    private func readSharedStrings(archive: XLSXArchive) throws -> [String] {
        let path = archive.workingURL.appendingPathComponent("xl/sharedStrings.xml")
        guard FileManager.default.fileExists(atPath: path.path) else { return [] }
        let document = try XMLDocument(contentsOf: path, options: [])
        return try document.nodes(forXPath: "//*[local-name()='si']").map { node in
            let textNodes = try node.nodes(forXPath: ".//*[local-name()='t']")
            return textNodes.compactMap(\.stringValue).joined()
        }
    }

    private func cellValue(_ cell: XMLElement, sharedStrings: [String]) -> String {
        let type = cell.attribute(forName: "t")?.stringValue
        if type == "inlineStr" {
            return (try? cell.nodes(forXPath: ".//*[local-name()='t']").compactMap(\.stringValue).joined()) ?? ""
        }
        guard let raw = (try? cell.nodes(forXPath: "*[local-name()='v']").first?.stringValue) ?? nil else { return "" }
        if type == "s", let index = Int(raw), sharedStrings.indices.contains(index) {
            return sharedStrings[index]
        }
        return raw
    }

    static func columnLetters(from cellReference: String) -> String {
        String(cellReference.prefix { $0.isLetter })
    }

    static func columnNumber(_ letters: String) -> Int {
        letters.uppercased().unicodeScalars.reduce(0) { $0 * 26 + Int($1.value - 64) }
    }

    static func columnLetters(for number: Int) -> String {
        var number = number
        var result = ""
        while number > 0 {
            let remainder = (number - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            number = (number - 1) / 26
        }
        return result
    }
}
