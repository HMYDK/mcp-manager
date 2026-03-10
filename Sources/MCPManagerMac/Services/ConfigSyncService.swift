import Foundation

final class ConfigSyncService {
    private let managedStart = "# >>> MCP-MANAGER START >>>"
    private let managedEnd = "# <<< MCP-MANAGER END <<<"
    private let fileManager = FileManager.default

    func sync(state: PersistedState, tools: [CLITool]) -> SyncReport {
        let aliasMap = buildAliasMap(for: state.servers)

        let results = tools.map { tool in
            do {
                return try writeToolConfig(state: state, tool: tool, aliasMap: aliasMap)
            } catch {
                return ToolSyncResult(
                    toolID: tool.id,
                    ok: false,
                    path: tool.officialPath,
                    count: 0,
                    format: tool.format,
                    message: error.localizedDescription
                )
            }
        }

        let diagnostics = tools.map { diagnose(state: state, tool: $0, aliasMap: aliasMap) }

        return SyncReport(
            timestamp: isoNow(),
            aliasMap: aliasMap,
            results: results,
            diagnostics: diagnostics
        )
    }

    func scan(state: PersistedState, tools: [CLITool]) -> ScanReport {
        let aliasMap = buildAliasMap(for: state.servers)
        let diagnostics = tools.map { diagnose(state: state, tool: $0, aliasMap: aliasMap) }

        return ScanReport(
            timestamp: isoNow(),
            aliasMap: aliasMap,
            diagnostics: diagnostics
        )
    }

    private func writeToolConfig(state: PersistedState, tool: CLITool, aliasMap: [String: String]) throws -> ToolSyncResult {
        let enabledEntries = enabledEntries(for: state, tool: tool, aliasMap: aliasMap)
        let managedAliases = Set(aliasMap.values)

        switch tool.format {
        case .codexToml:
            try writeCodexToml(path: tool.officialPath, enabledEntries: enabledEntries)
        case .claudeProjectJSON:
            try writeClaudeProjectJSON(path: tool.officialPath, enabledEntries: enabledEntries, managedAliases: managedAliases)
        case .geminiProjectJSON:
            try writeGeminiProjectJSON(path: tool.officialPath, enabledEntries: enabledEntries, managedAliases: managedAliases)
        }

        return ToolSyncResult(
            toolID: tool.id,
            ok: true,
            path: tool.officialPath,
            count: enabledEntries.count,
            format: tool.format,
            message: ""
        )
    }

    private func writeCodexToml(path: String, enabledEntries: [(alias: String, server: MCPServer)]) throws {
        try ensureParentDirectoryExists(for: path)

        let existing = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        let block = renderCodexManagedBlock(enabledEntries)
        let next = replacingManagedBlock(in: existing, with: block)

        try next.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func writeClaudeProjectJSON(path: String, enabledEntries: [(alias: String, server: MCPServer)], managedAliases: Set<String>) throws {
        try ensureParentDirectoryExists(for: path)
        var root = try readJSONObject(path: path)

        var mcpServers = (root["mcpServers"] as? [String: Any]) ?? [:]

        for alias in managedAliases {
            mcpServers.removeValue(forKey: alias)
        }

        for entry in enabledEntries {
            let payload: [String: Any] = [
                "command": entry.server.command,
                "args": entry.server.args,
                "env": entry.server.env
            ]
            mcpServers[entry.alias] = payload
        }

        root["mcpServers"] = mcpServers
        try writeJSONObject(path: path, object: root)
    }

    private func writeGeminiProjectJSON(path: String, enabledEntries: [(alias: String, server: MCPServer)], managedAliases: Set<String>) throws {
        try ensureParentDirectoryExists(for: path)
        var root = try readJSONObject(path: path)

        var mcpServers = (root["mcpServers"] as? [String: Any]) ?? [:]

        for alias in managedAliases {
            mcpServers.removeValue(forKey: alias)
        }

        for entry in enabledEntries {
            var payload: [String: Any] = [
                "command": entry.server.command,
                "args": entry.server.args,
                "env": entry.server.env
            ]
            if !entry.server.cwd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                payload["cwd"] = entry.server.cwd
            }
            mcpServers[entry.alias] = payload
        }

        root["mcpServers"] = mcpServers
        try writeJSONObject(path: path, object: root)
    }

    private func diagnose(state: PersistedState, tool: CLITool, aliasMap: [String: String]) -> ToolDiagnosis {
        let managedAliases = Set(aliasMap.values)
        let enabled = enabledEntries(for: state, tool: tool, aliasMap: aliasMap)
        let enabledAliases = enabled.map(\.alias)

        let cliPath = ProcessRunner.which(tool.cliCommand)
        let cliInstalled = !cliPath.isEmpty
        let configPath = tool.officialPath
        let configExists = fileManager.fileExists(atPath: configPath)

        var configuredAliases: [String] = []
        var parseError = ""

        do {
            configuredAliases = try readConfiguredAliases(tool: tool)
        } catch {
            parseError = error.localizedDescription
        }

        let configuredSet = Set(configuredAliases)
        let missingEnabled = enabledAliases.filter { !configuredSet.contains($0) }
        let managedButDisabled = managedAliases.filter { configuredSet.contains($0) && !enabledAliases.contains($0) }.sorted()
        let unmanagedConfigured = configuredAliases.filter { !managedAliases.contains($0) }

        let verification: CLIVerification
        if cliInstalled {
            verification = runCLIVerification(tool: tool, enabledAliases: enabledAliases, workspaceRoot: state.workspaceRoot)
        } else {
            verification = CLIVerification(attempted: false, ok: nil, output: "", exitCode: nil, matched: [])
        }

        var status: EffectivenessStatus = .effective
        var summary = "配置生效"

        if !cliInstalled {
            status = .notEffective
            summary = "未检测到 \(tool.cliCommand) 命令"
        } else if !parseError.isEmpty {
            status = .notEffective
            summary = "配置文件解析失败"
        } else if !missingEnabled.isEmpty || !managedButDisabled.isEmpty {
            status = .partial
            summary = "配置与启用矩阵不一致"
        } else if verification.attempted, verification.ok == false {
            status = .partial
            summary = "CLI 探测未完全匹配"
        }

        return ToolDiagnosis(
            toolID: tool.id,
            toolName: tool.name,
            cliCommand: tool.cliCommand,
            cliPath: cliPath,
            cliInstalled: cliInstalled,
            status: status,
            summary: summary,
            officialPath: tool.officialPath,
            configPath: configPath,
            pathIsOfficial: true,
            configExists: configExists,
            enabledCount: enabledAliases.count,
            enabledAliases: enabledAliases,
            configuredCount: configuredAliases.count,
            configuredAliases: configuredAliases,
            unmanagedConfigured: unmanagedConfigured,
            missingEnabled: missingEnabled,
            managedButDisabled: managedButDisabled,
            parseError: parseError,
            cliVerification: verification
        )
    }

    private func runCLIVerification(tool: CLITool, enabledAliases: [String], workspaceRoot: String) -> CLIVerification {
        guard !tool.verifyArgs.isEmpty else {
            return CLIVerification(attempted: false, ok: nil, output: "", exitCode: nil, matched: [])
        }

        let result = ProcessRunner.run(
            command: tool.cliCommand,
            arguments: tool.verifyArgs,
            currentDirectory: workspaceRoot,
            timeout: 6
        )

        let combinedOutput = [result.stdout, result.stderr]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let matched = enabledAliases.filter { combinedOutput.contains($0) }
        let ok = (result.exitCode == 0) && (matched.count == enabledAliases.count)

        return CLIVerification(
            attempted: true,
            ok: ok,
            output: combinedOutput,
            exitCode: result.exitCode,
            matched: matched
        )
    }

    private func readConfiguredAliases(tool: CLITool) throws -> [String] {
        let path = tool.officialPath
        guard fileManager.fileExists(atPath: path) else {
            return []
        }

        switch tool.format {
        case .codexToml:
            let content = try String(contentsOfFile: path, encoding: .utf8)
            return parseCodexConfiguredAliases(content)
        case .claudeProjectJSON, .geminiProjectJSON:
            let root = try readJSONObject(path: path)
            let mcpServers = (root["mcpServers"] as? [String: Any]) ?? [:]
            return mcpServers.keys.sorted()
        }
    }

    private func parseCodexConfiguredAliases(_ content: String) -> [String] {
        var aliases = Set<String>()

        let quotedPattern = #"\[mcp_servers\."([^"]+)"\]"#
        let barePattern = #"\[mcp_servers\.([A-Za-z0-9_-]+)\]"#

        aliases.formUnion(matches(in: content, pattern: quotedPattern, group: 1))
        aliases.formUnion(matches(in: content, pattern: barePattern, group: 1))

        return aliases.sorted()
    }

    private func matches(in text: String, pattern: String, group: Int) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        return regex
            .matches(in: text, options: [], range: range)
            .compactMap { match in
                guard match.numberOfRanges > group else {
                    return nil
                }
                let captureRange = match.range(at: group)
                guard captureRange.location != NSNotFound else {
                    return nil
                }
                return nsText.substring(with: captureRange)
            }
    }

    private func readJSONObject(path: String) throws -> [String: Any] {
        guard fileManager.fileExists(atPath: path) else {
            return [:]
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        if data.isEmpty {
            return [:]
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let root = json as? [String: Any] else {
            throw NSError(domain: "MCPManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "JSON 根节点不是对象"])
        }
        return root
    }

    private func writeJSONObject(path: String, object: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    private func replacingManagedBlock(in existing: String, with block: String) -> String {
        let escapedStart = NSRegularExpression.escapedPattern(for: managedStart)
        let escapedEnd = NSRegularExpression.escapedPattern(for: managedEnd)
        let pattern = "\(escapedStart)[\\s\\S]*?\(escapedEnd)\\n?"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: (existing as NSString).length)
            if regex.firstMatch(in: existing, options: [], range: range) != nil {
                return regex.stringByReplacingMatches(in: existing, options: [], range: range, withTemplate: block + "\n")
            }
        }

        if existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return block + "\n"
        }

        return existing.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + block + "\n"
    }

    private func renderCodexManagedBlock(_ entries: [(alias: String, server: MCPServer)]) -> String {
        var lines: [String] = [
            managedStart,
            "# This section is generated by MCP Manager."
        ]

        for entry in entries {
            lines.append("")
            lines.append("[mcp_servers.\(tomlKey(entry.alias))]")
            lines.append("command = \(tomlString(entry.server.command))")
            let argsText = entry.server.args.map(tomlString).joined(separator: ", ")
            lines.append("args = [\(argsText)]")

            let envPairs = entry.server.env
                .sorted { $0.key < $1.key }
                .map { "\(tomlKey($0.key)) = \(tomlString($0.value))" }
                .joined(separator: ", ")
            lines.append("env = { \(envPairs) }")
        }

        lines.append("")
        lines.append(managedEnd)

        return lines.joined(separator: "\n")
    }

    private func tomlString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func tomlKey(_ value: String) -> String {
        let plain = value.range(of: #"^[A-Za-z0-9_-]+$"#, options: .regularExpression) != nil
        return plain ? value : tomlString(value)
    }

    private func ensureParentDirectoryExists(for path: String) throws {
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parent.path) {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        }
    }

    private func enabledEntries(for state: PersistedState, tool: CLITool, aliasMap: [String: String]) -> [(alias: String, server: MCPServer)] {
        state.servers
            .filter { server in
                state.matrix[server.id]?[tool.id] == true
            }
            .compactMap { server in
                guard let alias = aliasMap[server.id] else {
                    return nil
                }
                return (alias, server)
            }
    }

    private func buildAliasMap(for servers: [MCPServer]) -> [String: String] {
        var map: [String: String] = [:]
        var used: Set<String> = []

        for (index, server) in servers.enumerated() {
            let fallback = "mcp-\(index + 1)"
            let base = sanitizeAlias(server.name, fallback: fallback)

            var alias = base
            var counter = 2
            while used.contains(alias) {
                alias = "\(base)-\(counter)"
                counter += 1
            }

            used.insert(alias)
            map[server.id] = alias
        }

        return map
    }

    private func sanitizeAlias(_ name: String, fallback: String) -> String {
        let lower = name.lowercased()
        let replaced = lower.replacingOccurrences(of: #"[^a-z0-9_-]+"#, with: "-", options: .regularExpression)
        let collapsed = replaced.replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
        let trimmed = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
