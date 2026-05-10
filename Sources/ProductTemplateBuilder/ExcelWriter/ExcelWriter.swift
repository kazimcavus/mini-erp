import Foundation

final class ExcelWriter {
    func writeRelatedProducts(outputURL: URL, rows: [RelatedProductRow]) throws {
        try writeSimpleWorkbook(
            outputURL: outputURL,
            headers: ["URUNKARTIID", "ILGILIURUNKARTIID"],
            rows: rows.map { [$0.productCardID, $0.relatedProductCardID] }
        )
    }

    func writeTechnicalDetails(outputURL: URL, rows: [TechnicalDetailRow]) throws {
        try writeSimpleWorkbook(
            outputURL: outputURL,
            headers: ["UrunKartID", "StokKodu", "UrunAdi", "Tanim", "Ozellik", "Deger"],
            rows: rows.map { [$0.productCardID, $0.stockCode, $0.productName, $0.definition, $0.property, $0.value] }
        )
    }

    /// `Bilgiler.xlsx` için: yalnızca değer hücreleri (formül yok), `Fiyatlar` + `Varyasyon` (eski Metaryal metni).
    func writeSimplifiedBilgilerExport(outputURL: URL, rows: [[String]]) throws {
        try writeSimpleWorkbook(outputURL: outputURL, headers: ["Fiyatlar", "Varyasyon"], rows: rows)
    }

    private func writeSimpleWorkbook(outputURL: URL, headers: [String], rows: [[String]]) throws {
        let workingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("simple-workbook-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workingURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workingURL) }

        try FileManager.default.createDirectory(at: workingURL.appendingPathComponent("_rels", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workingURL.appendingPathComponent("xl/_rels", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workingURL.appendingPathComponent("xl/worksheets", isDirectory: true), withIntermediateDirectories: true)

        try writeText(contentTypesXML, to: workingURL.appendingPathComponent("[Content_Types].xml"))
        try writeText(rootRelationshipsXML, to: workingURL.appendingPathComponent("_rels/.rels"))
        try writeText(workbookXML, to: workingURL.appendingPathComponent("xl/workbook.xml"))
        try writeText(workbookRelationshipsXML, to: workingURL.appendingPathComponent("xl/_rels/workbook.xml.rels"))
        try writeText(simpleWorksheetXML(headers: headers, rows: rows), to: workingURL.appendingPathComponent("xl/worksheets/sheet1.xml"))

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        try runZip(outputURL: outputURL, workingURL: workingURL)
    }

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

    private func simpleWorksheetXML(headers: [String], rows: [[String]]) -> String {
        let headerCells = headers.enumerated().map { columnIndex, value in
            inlineStringCellXML(reference: "\(ExcelReader.columnLetters(for: columnIndex + 1))1", value: value)
        }.joined()

        let dataRows = rows.enumerated().map { rowOffset, values in
            let rowIndex = rowOffset + 2
            let cells = values.enumerated().map { columnIndex, value in
                inlineStringCellXML(reference: "\(ExcelReader.columnLetters(for: columnIndex + 1))\(rowIndex)", value: value)
            }.joined()
            return """
            <row r="\(rowIndex)">\(cells)</row>
            """
        }.joined()

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheetData>
            <row r="1">\(headerCells)</row>
            \(dataRows)
          </sheetData>
        </worksheet>
        """
    }

    private func inlineStringCellXML(reference: String, value: String) -> String {
        """
        <c r="\(xmlEscaped(reference))" t="inlineStr"><is><t xml:space="preserve">\(xmlEscaped(value))</t></is></c>
        """
    }

    private func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func writeText(_ value: String, to url: URL) throws {
        try value.data(using: .utf8)?.write(to: url)
    }

    private func runZip(outputURL: URL, workingURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-qr", outputURL.path, "."]
        process.currentDirectoryURL = workingURL
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown zip error"
            throw XLSXError.archiveFailed(message)
        }
    }

    private var contentTypesXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        </Types>
        """
    }

    private var rootRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private var workbookXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """
    }

    private var workbookRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        </Relationships>
        """
    }
}
