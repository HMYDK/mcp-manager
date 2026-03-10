import Foundation

enum ToolRegistry {
    static func tools(forWorkspaceRoot workspaceRoot: String) -> [CLITool] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let workspaceURL = URL(fileURLWithPath: workspaceRoot, isDirectory: true)

        return [
            CLITool(
                id: "codex-cli",
                name: "Codex CLI",
                cliCommand: "codex",
                format: .codexToml,
                scope: .user,
                officialPath: URL(fileURLWithPath: home)
                    .appendingPathComponent(".codex", isDirectory: true)
                    .appendingPathComponent("config.toml", isDirectory: false)
                    .path,
                docsURL: "https://platform.openai.com/docs/guides/tools-remote-mcp",
                verifyArgs: ["mcp", "list"]
            ),
            CLITool(
                id: "claude-code",
                name: "Claude Code",
                cliCommand: "claude",
                format: .claudeProjectJSON,
                scope: .project,
                officialPath: workspaceURL.appendingPathComponent(".mcp.json", isDirectory: false).path,
                docsURL: "https://docs.anthropic.com/en/docs/claude-code/mcp",
                verifyArgs: ["mcp", "list"]
            ),
            CLITool(
                id: "gemini-cli",
                name: "Gemini CLI",
                cliCommand: "gemini",
                format: .geminiProjectJSON,
                scope: .project,
                officialPath: workspaceURL
                    .appendingPathComponent(".gemini", isDirectory: true)
                    .appendingPathComponent("settings.json", isDirectory: false)
                    .path,
                docsURL: "https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html",
                verifyArgs: ["mcp", "list", "--scope", "project"]
            )
        ]
    }
}
