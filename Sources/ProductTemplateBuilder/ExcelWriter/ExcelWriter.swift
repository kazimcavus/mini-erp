import Foundation

final class ExcelWriter {
    func write(templateURL: URL, outputURL: URL, headers: [String], rows: [TemplateRow]) throws {
        let archive = try XLSXArchive(sourceURL: templateURL, copyToTemporaryDirectory: true)
        let sheet = try archive.sheetPath(first: true)
        let document = try archive.document(at: sheet.path)
        guard let sheetData = try document.nodes(forXPath: "//*[local-name()='sheetData']").first as? XMLElement else {
            throw XLSXError.missingSheetData
        }
        let existingRows = (sheetData.children ?? []).compactMap { $0 as? XMLElement }.filter { $0.localName == "row" || $0.name == "row" }
        let hasHeaderRow = existingRows.contains { $0.attribute(forName: "r") != nil }
        guard hasHeaderRow else {
            throw XLSXError.missingHeaderRow
        }

        for row in existingRows.dropFirst() {
            row.detach()
        }

        for (offset, templateRow) in rows.enumerated() {
            let rowIndex = offset + 2
            let row = XMLElement(name: "row")
            row.addAttribute(XMLNode.attribute(withName: "r", stringValue: "\(rowIndex)") as! XMLNode)
            for (columnIndex, header) in headers.enumerated() {
                let value = templateRow.values[header] ?? ""
                let column = ExcelReader.columnLetters(for: columnIndex + 1)
                row.addChild(inlineStringCell(reference: "\(column)\(rowIndex)", value: value))
            }
            sheetData.addChild(row)
        }

        stripSheetVisualFormatting(in: document)
        try archive.write(document, to: sheet.path)
        try disableTableStripes(in: archive)
        try archive.repack(to: outputURL)
    }

    /// Şablondan gelen dolgu / şerit için: tüm `sheetData` hücre ve satırlarından stil indeksini siler,
    /// koşullu biçimlendirmeyi ve sütun varsayılan stilini kaldırır; tablo şeridini kapatır.
    private func stripSheetVisualFormatting(in document: XMLDocument) {
        let cellNodes = (try? document.nodes(forXPath: "//*[local-name()='sheetData']//*[local-name()='c']")) ?? []
        for case let cell as XMLElement in cellNodes {
            cell.removeAttribute(forName: "s")
        }

        let rowNodes = (try? document.nodes(forXPath: "//*[local-name()='sheetData']//*[local-name()='row']")) ?? []
        for case let rowEl as XMLElement in rowNodes {
            rowEl.removeAttribute(forName: "s")
            rowEl.removeAttribute(forName: "customFormat")
        }

        let conditionalNodes = (try? document.nodes(forXPath: "//*[local-name()='worksheet']//*[local-name()='conditionalFormatting']")) ?? []
        for node in conditionalNodes {
            node.detach()
        }

        let colNodes = (try? document.nodes(forXPath: "//*[local-name()='cols']/*[local-name()='col']")) ?? []
        for case let col as XMLElement in colNodes {
            col.removeAttribute(forName: "style")
        }
    }

    /// `xl/tables/*.xml` içinde satır/sütun şeritlerini kapatır (alterne renkler).
    private func disableTableStripes(in archive: XLSXArchive) throws {
        let tablesDir = archive.workingURL.appendingPathComponent("xl/tables", isDirectory: true)
        guard FileManager.default.fileExists(atPath: tablesDir.path) else { return }
        let files = try FileManager.default.contentsOfDirectory(at: tablesDir, includingPropertiesForKeys: nil)
        for url in files where url.pathExtension.lowercased() == "xml" {
            let relative = "xl/tables/\(url.lastPathComponent)"
            let tableDoc = try archive.document(at: relative)
            let tableElements = try tableDoc.nodes(forXPath: "//*[local-name()='table']")
            guard !tableElements.isEmpty else { continue }
            for case let tbl as XMLElement in tableElements {
                tbl.removeAttribute(forName: "showRowStripes")
                tbl.removeAttribute(forName: "showColumnStripes")
                tbl.addAttribute(XMLNode.attribute(withName: "showRowStripes", stringValue: "0") as! XMLNode)
                tbl.addAttribute(XMLNode.attribute(withName: "showColumnStripes", stringValue: "0") as! XMLNode)
            }
            try archive.write(tableDoc, to: relative)
        }
    }

    /// Stil / dolgu kullanmıyoruz — çıktı hücreleri renksiz (varsayı Excel görünümü).
    private func inlineStringCell(reference: String, value: String) -> XMLElement {
        let cell = XMLElement(name: "c")
        cell.addAttribute(XMLNode.attribute(withName: "r", stringValue: reference) as! XMLNode)
        cell.addAttribute(XMLNode.attribute(withName: "t", stringValue: "inlineStr") as! XMLNode)
        let inline = XMLElement(name: "is")
        let text = XMLElement(name: "t", stringValue: value)
        text.addAttribute(XMLNode.attribute(withName: "xml:space", stringValue: "preserve") as! XMLNode)
        inline.addChild(text)
        cell.addChild(inline)
        return cell
    }
}
