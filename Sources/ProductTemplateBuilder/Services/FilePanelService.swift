import AppKit
import Foundation

enum FilePanelService {
    @MainActor
    static func chooseXLSX() -> URL? {
        let panel = NSOpenPanel()
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
