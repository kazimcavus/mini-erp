import AppKit
import SwiftUI

@main
struct ProductTemplateBuilderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup(AppBranding.windowTitle) {
            MainView()
                .environmentObject(viewModel)
                .frame(minWidth: 1120, minHeight: 720)
                .task {
                    // Terminalden başlatıldığında pencereyi öne al.
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows where window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
