import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var state: PersistedState
    @Published var tools: [CLITool] = []
    @Published var diagnostics: [ToolDiagnosis] = []
    @Published var logs: [String] = []
    @Published var selectedServerID: String?

    private let store: AppStateStore
    private let syncService: ConfigSyncService

    init(store: AppStateStore = AppStateStore(), syncService: ConfigSyncService = ConfigSyncService()) {
        self.store = store
        self.syncService = syncService
        self.state = .default(workspaceRoot: FileManager.default.currentDirectoryPath)
    }

    func load() {
        do {
            state = try store.load()
            refreshTools()
            normalizeMatrix()
            state.updatedAt = isoNow()
            _ = try store.save(state)
            scanOnly(logToConsole: false)
            log("状态加载完成：\(store.filePath)")
        } catch {
            log("状态加载失败：\(error.localizedDescription)")
        }
    }

    func refreshTools() {
        tools = ToolRegistry.tools(forWorkspaceRoot: state.workspaceRoot)
    }

    func setWorkspaceRoot(_ path: String) {
        state.workspaceRoot = path
        refreshTools()
        normalizeMatrix()
        persistState(logMessage: "工作区已切换到 \(path)")
        scanOnly(logToConsole: false)
    }

    func addServer() {
        let server = MCPServer.empty()
        state.servers.append(server)
        normalizeMatrix()
        selectedServerID = server.id
        persistState(logMessage: "新增 MCP：\(server.name)")
    }

    func removeServer(id: String) {
        guard let index = state.servers.firstIndex(where: { $0.id == id }) else {
            return
        }

        let name = state.servers[index].name
        state.servers.remove(at: index)
        state.matrix.removeValue(forKey: id)

        if selectedServerID == id {
            selectedServerID = state.servers.first?.id
        }

        normalizeMatrix()
        persistState(logMessage: "已删除 MCP：\(name)")
    }

    func updateServer(_ server: MCPServer) {
        guard let index = state.servers.firstIndex(where: { $0.id == server.id }) else {
            return
        }

        state.servers[index] = server
        normalizeMatrix()
        persistState(logMessage: "已保存 MCP：\(server.name)")
    }

    func setEnabled(serverID: String, toolID: String, enabled: Bool) {
        var row = state.matrix[serverID] ?? [:]
        row[toolID] = enabled
        state.matrix[serverID] = row
        persistState(logMessage: "开关变更：\(serverID) -> \(toolID) = \(enabled ? "on" : "off")")
    }

    func isEnabled(serverID: String, toolID: String) -> Bool {
        state.matrix[serverID]?[toolID] == true
    }

    func syncAndScan() {
        refreshTools()
        normalizeMatrix()

        let report = syncService.sync(state: state, tools: tools)
        diagnostics = report.diagnostics

        let success = report.results.filter(\.ok).count
        let total = report.results.count
        log("同步完成：\(success)/\(total) 成功")

        for result in report.results where !result.ok {
            log("同步失败 [\(result.toolID)]：\(result.message)")
        }
    }

    func scanOnly(logToConsole: Bool = true) {
        refreshTools()
        normalizeMatrix()

        let report = syncService.scan(state: state, tools: tools)
        diagnostics = report.diagnostics

        if logToConsole {
            log("检测完成：\(statusSummary)")
        }
    }

    var statusSummary: String {
        let total = diagnostics.count
        guard total > 0 else {
            return "暂无检测结果"
        }

        let effective = diagnostics.filter { $0.status == .effective }.count
        let partial = diagnostics.filter { $0.status == .partial }.count
        let notEffective = diagnostics.filter { $0.status == .notEffective }.count

        return "\(effective)/\(total) 已生效，\(partial) 部分生效，\(notEffective) 未生效"
    }

    func diagnosis(for toolID: String) -> ToolDiagnosis? {
        diagnostics.first(where: { $0.toolID == toolID })
    }

    func selectFirstServerIfNeeded() {
        if selectedServerID == nil {
            selectedServerID = state.servers.first?.id
        }
    }

    private func normalizeMatrix() {
        var next: [String: [String: Bool]] = [:]

        for server in state.servers {
            var row: [String: Bool] = [:]
            let existing = state.matrix[server.id] ?? [:]
            for tool in tools {
                row[tool.id] = existing[tool.id] ?? false
            }
            next[server.id] = row
        }

        state.matrix = next
    }

    private func persistState(logMessage: String) {
        state.updatedAt = isoNow()

        do {
            _ = try store.save(state)
            log(logMessage)
        } catch {
            log("保存失败：\(error.localizedDescription)")
        }
    }

    private func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let line = "[\(formatter.string(from: Date()))] \(message)"
        logs.insert(line, at: 0)
    }
}
