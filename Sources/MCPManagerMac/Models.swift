import Foundation

enum ToolFormat: String, Codable, Hashable {
    case codexToml = "codex_toml"
    case claudeProjectJSON = "claude_project_json"
    case geminiProjectJSON = "gemini_project_json"
}

enum ToolScope: String, Codable, Hashable {
    case user
    case project
}

struct CLITool: Identifiable, Hashable {
    let id: String
    let name: String
    let cliCommand: String
    let format: ToolFormat
    let scope: ToolScope
    let officialPath: String
    let docsURL: String
    let verifyArgs: [String]
}

struct MCPServer: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var command: String
    var args: [String]
    var env: [String: String]
    var cwd: String
    var description: String

    static func empty() -> MCPServer {
        MCPServer(
            id: "srv-\(UUID().uuidString)",
            name: "new-mcp",
            command: "",
            args: [],
            env: [:],
            cwd: "",
            description: ""
        )
    }
}

struct PersistedState: Codable {
    var version: Int
    var workspaceRoot: String
    var servers: [MCPServer]
    var matrix: [String: [String: Bool]]
    var updatedAt: String

    static func `default`(workspaceRoot: String) -> PersistedState {
        PersistedState(
            version: 1,
            workspaceRoot: workspaceRoot,
            servers: [],
            matrix: [:],
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

enum EffectivenessStatus: String {
    case effective
    case partial
    case notEffective

    var label: String {
        switch self {
        case .effective:
            return "已生效"
        case .partial:
            return "部分生效"
        case .notEffective:
            return "未生效"
        }
    }
}

struct CLIVerification {
    var attempted: Bool
    var ok: Bool?
    var output: String
    var exitCode: Int32?
    var matched: [String]
}

struct ToolDiagnosis: Identifiable {
    var id: String { toolID }

    let toolID: String
    let toolName: String
    let cliCommand: String
    let cliPath: String
    let cliInstalled: Bool
    let status: EffectivenessStatus
    let summary: String
    let officialPath: String
    let configPath: String
    let pathIsOfficial: Bool
    let configExists: Bool
    let enabledCount: Int
    let enabledAliases: [String]
    let configuredCount: Int
    let configuredAliases: [String]
    let unmanagedConfigured: [String]
    let missingEnabled: [String]
    let managedButDisabled: [String]
    let parseError: String
    let cliVerification: CLIVerification
}

struct ToolSyncResult: Identifiable {
    var id: String { toolID }

    let toolID: String
    let ok: Bool
    let path: String
    let count: Int
    let format: ToolFormat?
    let message: String
}

struct SyncReport {
    let timestamp: String
    let aliasMap: [String: String]
    let results: [ToolSyncResult]
    let diagnostics: [ToolDiagnosis]
}

struct ScanReport {
    let timestamp: String
    let aliasMap: [String: String]
    let diagnostics: [ToolDiagnosis]
}
