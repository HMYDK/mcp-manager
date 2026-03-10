import Foundation

final class AppStateStore {
    private let fileManager: FileManager
    private let stateURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.stateURL = AppStateStore.resolveStateURL(fileManager: fileManager)
    }

    func load() throws -> PersistedState {
        try ensureStateFileExists()

        let data = try Data(contentsOf: stateURL)
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(PersistedState.self, from: data)
        } catch {
            let fallback = PersistedState.default(workspaceRoot: defaultWorkspaceRoot())
            return fallback
        }
    }

    @discardableResult
    func save(_ state: PersistedState) throws -> PersistedState {
        let normalized = state
        try ensureParentDirectoryExists()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(normalized)
        try data.write(to: stateURL, options: .atomic)

        return normalized
    }

    var filePath: String {
        stateURL.path
    }

    private func ensureStateFileExists() throws {
        try ensureParentDirectoryExists()

        guard !fileManager.fileExists(atPath: stateURL.path) else {
            return
        }

        let initial = PersistedState.default(workspaceRoot: defaultWorkspaceRoot())
        _ = try save(initial)
    }

    private func ensureParentDirectoryExists() throws {
        let folder = stateURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }

    private static func resolveStateURL(fileManager: FileManager) -> URL {
        let home = fileManager.homeDirectoryForCurrentUser
        let primaryDir = home.appendingPathComponent(".mcp-manager", isDirectory: true)

        do {
            try fileManager.createDirectory(at: primaryDir, withIntermediateDirectories: true)
            return primaryDir.appendingPathComponent("state.json", isDirectory: false)
        } catch {
            let fallbackDir = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
                .appendingPathComponent(".mcp-manager-data", isDirectory: true)
            try? fileManager.createDirectory(at: fallbackDir, withIntermediateDirectories: true)
            return fallbackDir.appendingPathComponent("state.json", isDirectory: false)
        }
    }

    private func defaultWorkspaceRoot() -> String {
        fileManager.currentDirectoryPath
    }
}
