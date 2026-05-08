import Foundation

final class XLSXArchive {
    let sourceURL: URL
    let workingURL: URL

    init(sourceURL: URL, copyToTemporaryDirectory: Bool = false) throws {
        self.sourceURL = sourceURL
        self.workingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("xlsx-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workingURL, withIntermediateDirectories: true)
        let inputURL = copyToTemporaryDirectory ? try Self.copySource(sourceURL) : sourceURL
        try Self.run("/usr/bin/unzip", arguments: ["-q", inputURL.path, "-d", workingURL.path])
    }

    deinit {
        try? FileManager.default.removeItem(at: workingURL)
    }

    func repack(to outputURL: URL) throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        try Self.run("/usr/bin/zip", arguments: ["-qr", outputURL.path, "."], currentDirectory: workingURL)
    }

    func document(at relativePath: String) throws -> XMLDocument {
        let url = workingURL.appendingPathComponent(relativePath)
        return try XMLDocument(contentsOf: url, options: [.nodePreserveWhitespace])
    }

    func write(_ document: XMLDocument, to relativePath: String) throws {
        let data = document.xmlData(options: [.nodePrettyPrint])
        try data.write(to: workingURL.appendingPathComponent(relativePath))
    }

    func textFile(at relativePath: String) throws -> String {
        try String(contentsOf: workingURL.appendingPathComponent(relativePath), encoding: .utf8)
    }

    func sheetPath(named sheetName: String? = nil, first: Bool = false) throws -> (name: String, path: String) {
        let workbook = try document(at: "xl/workbook.xml")
        let rels = try document(at: "xl/_rels/workbook.xml.rels")
        let relNodes = try rels.nodes(forXPath: "//*[local-name()='Relationship']")
        var targets: [String: String] = [:]
        for node in relNodes {
            guard let element = node as? XMLElement,
                  let id = element.attribute(forName: "Id")?.stringValue,
                  let target = element.attribute(forName: "Target")?.stringValue else { continue }
            targets[id] = target.hasPrefix("/") ? String(target.dropFirst()) : "xl/\(target)"
        }

        let sheetNodes = try workbook.nodes(forXPath: "//*[local-name()='sheet']")
        for node in sheetNodes {
            guard let element = node as? XMLElement,
                  let name = element.attribute(forName: "name")?.stringValue,
                  let relID = element.attribute(forName: "r:id")?.stringValue,
                  let path = targets[relID] else { continue }
            if first || sheetName == nil || name.localizedCaseInsensitiveCompare(sheetName!) == .orderedSame {
                return (name, path)
            }
        }
        throw XLSXError.sheetNotFound(sheetName ?? "first sheet")
    }

    func allSheetPaths() throws -> [(name: String, path: String)] {
        let workbook = try document(at: "xl/workbook.xml")
        let rels = try document(at: "xl/_rels/workbook.xml.rels")
        let relNodes = try rels.nodes(forXPath: "//*[local-name()='Relationship']")
        var targets: [String: String] = [:]
        for node in relNodes {
            guard let element = node as? XMLElement,
                  let id = element.attribute(forName: "Id")?.stringValue,
                  let target = element.attribute(forName: "Target")?.stringValue else { continue }
            targets[id] = target.hasPrefix("/") ? String(target.dropFirst()) : "xl/\(target)"
        }
        return try workbook.nodes(forXPath: "//*[local-name()='sheet']").compactMap { node in
            guard let element = node as? XMLElement,
                  let name = element.attribute(forName: "name")?.stringValue,
                  let relID = element.attribute(forName: "r:id")?.stringValue,
                  let path = targets[relID] else { return nil }
            return (name, path)
        }
    }

    private static func copySource(_ sourceURL: URL) throws -> URL {
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).xlsx")
        try FileManager.default.copyItem(at: sourceURL, to: target)
        return target
    }

    private static func run(_ launchPath: String, arguments: [String], currentDirectory: URL? = nil) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown zip error"
            throw XLSXError.archiveFailed(message)
        }
    }
}

enum XLSXError: LocalizedError {
    case archiveFailed(String)
    case sheetNotFound(String)
    case missingSheetData
    case missingHeaderRow

    var errorDescription: String? {
        switch self {
        case .archiveFailed(let message): "Excel archive operation failed: \(message)"
        case .sheetNotFound(let sheet): "Sheet not found: \(sheet)"
        case .missingSheetData: "The Excel sheet is missing sheetData."
        case .missingHeaderRow: "The Excel sheet has no header row."
        }
    }
}
