import SwiftUI

@main
struct MCPManagerMacApp: App {
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
