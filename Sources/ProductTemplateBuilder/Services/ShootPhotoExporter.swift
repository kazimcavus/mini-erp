import Foundation

/// Çekim klasöründeki tüm görselleri masaüstünde `DDMMYYYY-Fotograflar` adlı bir klasöre kopyalar.
enum ShootPhotoExporter {
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "webp", "tiff", "tif", "gif", "bmp", "raw", "dng"
    ]

    struct Result: Sendable {
        var copiedCount: Int
        var destinationFolder: URL
    }

    static func copyAllImages(from sourceRoot: URL) throws -> Result {
        let fm = FileManager.default
        guard let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            throw NSError(
                domain: "ShootPhotoExporter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Masaüstü klasörü açılamadı."]
            )
        }

        let folderName = Self.todayFotograflarFolderName()
        let destFolder = desktop.appendingPathComponent(folderName, isDirectory: true)
        try fm.createDirectory(at: destFolder, withIntermediateDirectories: true)

        let images = try collectImageURLs(from: sourceRoot)
        var copied = 0
        for src in images {
            let uniqueName = uniqueFileName(in: destFolder, originalName: src.lastPathComponent)
            let dest = destFolder.appendingPathComponent(uniqueName)
            try fm.copyItem(at: src, to: dest)
            copied += 1
        }

        return Result(copiedCount: copied, destinationFolder: destFolder)
    }

    private static func todayFotograflarFolderName() -> String {
        let now = Date()
        let cal = Calendar.current
        let d = cal.component(.day, from: now)
        let m = cal.component(.month, from: now)
        let y = cal.component(.year, from: now)
        return String(format: "%02d%02d%04d-Fotograflar", d, m, y)
    }

    private static func collectImageURLs(from root: URL) throws -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            let ext = url.pathExtension.lowercased()
            guard Self.imageExtensions.contains(ext) else { continue }
            urls.append(url)
        }
        return urls.sorted { $0.path < $1.path }
    }

    private static func uniqueFileName(in destFolder: URL, originalName: String) -> String {
        let fm = FileManager.default
        let ns = originalName as NSString
        let base = ns.deletingPathExtension
        let ext = ns.pathExtension
        var candidate = originalName
        var n = 2
        while fm.fileExists(atPath: destFolder.appendingPathComponent(candidate).path) {
            candidate = ext.isEmpty ? "\(base)-\(n)" : "\(base)-\(n).\(ext)"
            n += 1
        }
        return candidate
    }
}
