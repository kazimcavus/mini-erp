import AppKit
import Foundation

enum FilePanelService {
    @MainActor
    static func chooseFolder(title: String? = nil) -> URL? {
        let panel = NSOpenPanel()
        if let title { panel.title = title }
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }

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
    static func saveXLSX(defaultName: String, title: String? = nil, message: String? = nil) -> URL? {
        let panel = NSSavePanel()
        if let title { panel.title = title }
        if let message { panel.message = message }
        panel.allowedContentTypes = [.init(filenameExtension: "xlsx")!]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }
}
