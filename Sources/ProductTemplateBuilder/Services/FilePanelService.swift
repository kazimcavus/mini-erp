import AppKit
import Foundation

enum FilePanelService {
    @MainActor
    static func chooseXLSX(title: String? = nil) -> URL? {
        let panel = NSOpenPanel()
        if let title { panel.title = title }
        panel.allowedContentTypes = [.init(filenameExtension: "xlsx")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    @MainActor
    static func saveXLSX(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "xlsx")!]
        panel.nameFieldStringValue = defaultName
        return panel.runModal() == .OK ? panel.url : nil
    }
}
