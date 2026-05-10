import Foundation

struct BilgilerBatchResult: Sendable {
    var convertedCount: Int
    var skipped: [String]
    var failures: [String]
}

/// Ana klasörün **bir alt seviye** klasörlerinde `Bilgiler.xlsx` arar; sadece `Fiyatlar` ve `Metaryal` sütunlarını
/// değer olarak yeni bir çalışma kitabına yazar (`Metaryal` başlığı `Varyasyon` olur), dosya adı `KlasörAdı.xlsx`.
enum BilgilerFolderBatchNormalizer {
    private static let bilgilerFileName = "Bilgiler.xlsx"
    private static let fiyatCandidates = ["Fiyatlar", "FIYATLAR", "FİYATLAR"]
    private static let metaryalCandidates = ["Metaryal", "Materyal", "METARYAL", "Material"]

    static func process(rootFolder: URL, reader: ExcelReader, writer: ExcelWriter) throws -> BilgilerBatchResult {
        let fm = FileManager.default
        var converted = 0
        var skipped: [String] = []
        var failures: [String] = []

        let children = try fm.contentsOfDirectory(
            at: rootFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for item in children {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue else { continue }

            let bilgilerURL = item.appendingPathComponent(bilgilerFileName, isDirectory: false)
            guard fm.fileExists(atPath: bilgilerURL.path) else {
                skipped.append("\(item.lastPathComponent): \(bilgilerFileName) yok")
                continue
            }

            let folderName = item.lastPathComponent
            let outputURL = item.appendingPathComponent("\(folderName).xlsx", isDirectory: false)

            do {
                let table = try reader.readFirstSheet(from: bilgilerURL, includeFullyEmptyRows: true)
                guard let fiyatCol = resolveHeader(in: table.headers, candidates: fiyatCandidates),
                      let metaCol = resolveHeader(in: table.headers, candidates: metaryalCandidates)
                else {
                    let need = "\(folderName): Fiyatlar veya Metaryal sütunu bulunamadı (başlık: \(table.headers.joined(separator: ", ").prefix(120))…)."
                    skipped.append(String(need.prefix(280)))
                    continue
                }

                let rows: [[String]] = table.rows.map { row in
                    let fiyatRaw = row[fiyatCol] ?? ""
                    let varyasyon = row[metaCol] ?? ""
                    return [ListPriceCalculator.formatSimplifiedBilgilerFiyat(fiyatRaw), varyasyon]
                }
                try writer.writeSimplifiedBilgilerExport(outputURL: outputURL, rows: rows)
                converted += 1
            } catch {
                failures.append("\(folderName): \(error.localizedDescription)")
            }
        }

        return BilgilerBatchResult(convertedCount: converted, skipped: skipped, failures: failures)
    }

    private static func resolveHeader(in headers: [String], candidates: [String]) -> String? {
        for h in headers {
            for c in candidates where ExcelHeaderNormalizer.matches(h, c) {
                return h
            }
        }
        return nil
    }
}
