import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // When launched via `swift run`, enforce foreground app behavior.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            sender.windows.forEach { window in
                window.makeKeyAndOrderFront(nil)
            }
        }
        sender.activate(ignoringOtherApps: true)
        return true
    }
}

@main
struct MCPManagerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("MCP Manager") {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.load()
                    viewModel.selectFirstServerIfNeeded()
                }
        }
        .defaultSize(width: 1380, height: 900)
        .windowResizability(.contentMinSize)
    }
}
