import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            SidebarStatusView()
                .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        } detail: {
            MainWorkspaceView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.scanOnly()
                } label: {
                    Label("检测生效", systemImage: "waveform.path.ecg")
                }

                Button {
                    viewModel.syncAndScan()
                } label: {
                    Label("同步并检测", systemImage: "arrow.triangle.2.circlepath")
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

private struct SidebarStatusView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    private var diagnosisStats: (effective: Int, partial: Int, notEffective: Int, total: Int) {
        let effective = viewModel.diagnostics.filter { $0.status == .effective }.count
        let partial = viewModel.diagnostics.filter { $0.status == .partial }.count
        let notEffective = viewModel.diagnostics.filter { $0.status == .notEffective }.count
        return (effective, partial, notEffective, viewModel.diagnostics.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("CLI 生效状态")
                    .font(.title3.weight(.semibold))
                Text(viewModel.statusSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    QuickStatPill(title: "已生效", value: diagnosisStats.effective, color: .green)
                    QuickStatPill(title: "部分生效", value: diagnosisStats.partial, color: .orange)
                    QuickStatPill(title: "未生效", value: diagnosisStats.notEffective, color: .red)
                }
            }

            Divider()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.tools) { tool in
                        ToolDiagnosisCard(tool: tool, diagnosis: viewModel.diagnosis(for: tool.id))
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
    }
}

private struct QuickStatPill: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.headline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.14))
        )
    }
}

private struct ToolDiagnosisCard: View {
    let tool: CLITool
    let diagnosis: ToolDiagnosis?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(tool.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: diagnosis?.status ?? .notEffective)
            }

            line("命令", diagnosis?.cliInstalled == true ? "\(tool.cliCommand) (\(diagnosis?.cliPath ?? ""))" : "未安装")
            line("官方路径", tool.officialPath)
            line("当前已配置 MCP", aliasText(diagnosis?.configuredAliases))
            line("外部已有 MCP", aliasText(diagnosis?.unmanagedConfigured))

            Text(diagnosis?.summary ?? "等待检测")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }

    private func aliasText(_ values: [String]?) -> String {
        guard let values, !values.isEmpty else {
            return "无"
        }
        return values.joined(separator: ", ")
    }
}

private struct StatusBadge: View {
    let status: EffectivenessStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.18))
            )
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .effective:
            return .green
        case .partial:
            return .orange
        case .notEffective:
            return .red
        }
    }
}

private struct MainWorkspaceView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                workspaceHeader

                HStack(alignment: .top, spacing: 14) {
                    ServerListPanel()
                        .frame(minWidth: 300, maxWidth: 360)
                    ServerEditorPanel()
                        .frame(maxWidth: .infinity)
                }

                MatrixPanel()
                LogPanel()
            }
            .padding(14)
        }
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .underPageBackgroundColor)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var workspaceHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MCP 控制台")
                        .font(.title2.weight(.semibold))
                    Text(viewModel.state.workspaceRoot)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                Button {
                    if let selected = selectDirectoryPanel(initialPath: viewModel.state.workspaceRoot) {
                        viewModel.setWorkspaceRoot(selected)
                    }
                } label: {
                    Label("切换工作区", systemImage: "folder")
                }

                Button {
                    viewModel.addServer()
                } label: {
                    Label("新增 MCP", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 10) {
                Label("MCP 数量：\(viewModel.state.servers.count)", systemImage: "shippingbox")
                    .font(.caption)
                Label("CLI 数量：\(viewModel.tools.count)", systemImage: "terminal")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ServerListPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var searchText = ""

    private var filteredServers: [MCPServer] {
        let source = viewModel.state.servers
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return source
        }

        return source.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) ||
            $0.command.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MCP 列表")
                    .font(.headline)
                Spacer()
                Text("\(filteredServers.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }

            TextField("搜索名称或命令", text: $searchText)
                .textFieldStyle(.roundedBorder)

            List(selection: $viewModel.selectedServerID) {
                ForEach(filteredServers) { server in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.name)
                            .font(.body.weight(.medium))
                        Text(server.command.isEmpty ? "未填写命令" : server.command)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(server.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.removeServer(id: server.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .frame(minHeight: 300)

            if let selectedServerID = viewModel.selectedServerID {
                Button(role: .destructive) {
                    viewModel.removeServer(id: selectedServerID)
                } label: {
                    Label("删除选中 MCP", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear {
            viewModel.selectFirstServerIfNeeded()
        }
    }
}

private struct ServerEditorPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    @State private var argsText = ""
    @State private var envText = "{}"
    @State private var validationMessage = ""

    private struct EnvParseError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MCP 详情")
                .font(.headline)

            if let binding = selectedServerBinding {
                Form {
                    TextField("名称", text: binding.name)
                    TextField("命令", text: binding.command)
                    TextField("参数（空格分隔）", text: $argsText)
                    TextField("工作目录（可选）", text: binding.cwd)
                    TextField("环境变量 JSON", text: $envText)
                    TextField("说明", text: binding.description)
                }
                .formStyle(.grouped)
                .frame(minHeight: 240)

                if !validationMessage.isEmpty {
                    Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                HStack {
                    Spacer()
                    Button("保存当前 MCP") {
                        save(server: binding)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("请选择一个 MCP，或新增后开始配置。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear {
            reloadDraft()
        }
        .onChange(of: viewModel.selectedServerID) { _, _ in
            reloadDraft()
            validationMessage = ""
        }
    }

    private var selectedServerBinding: Binding<MCPServer>? {
        guard let selectedServerID = viewModel.selectedServerID,
              let index = viewModel.state.servers.firstIndex(where: { $0.id == selectedServerID })
        else {
            return nil
        }

        return $viewModel.state.servers[index]
    }

    private func reloadDraft() {
        guard let selectedServerID = viewModel.selectedServerID,
              let server = viewModel.state.servers.first(where: { $0.id == selectedServerID })
        else {
            argsText = ""
            envText = "{}"
            return
        }

        argsText = server.args.joined(separator: " ")
        if let data = try? JSONSerialization.data(withJSONObject: server.env, options: [.prettyPrinted]),
           let text = String(data: data, encoding: .utf8) {
            envText = text.replacingOccurrences(of: "\n", with: "")
        } else {
            envText = "{}"
        }
    }

    private func save(server binding: Binding<MCPServer>) {
        let args = argsText
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        do {
            let env = try parseEnv(text: envText)
            validationMessage = ""
            binding.wrappedValue.args = args
            binding.wrappedValue.env = env
            viewModel.updateServer(binding.wrappedValue)
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private func parseEnv(text: String) throws -> [String: String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return [:]
        }

        guard let data = trimmed.data(using: .utf8) else {
            throw EnvParseError(message: "环境变量 JSON 编码失败")
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            guard let object = json as? [String: Any] else {
                throw EnvParseError(message: "环境变量必须是 JSON 对象")
            }

            var env: [String: String] = [:]
            for (key, value) in object {
                env[key] = String(describing: value)
            }
            return env
        } catch {
            throw EnvParseError(message: "环境变量 JSON 解析失败：\(error.localizedDescription)")
        }
    }
}

private struct MatrixPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("启用矩阵")
                .font(.headline)
            Text("勾选表示该 CLI 会启用对应 MCP")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.state.servers.isEmpty || viewModel.tools.isEmpty {
                Text("请先添加 MCP 或设置工作区。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Text("MCP / CLI")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 220, alignment: .leading)
                            ForEach(viewModel.tools) { tool in
                                Text(tool.name)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 120)
                            }
                        }
                        .padding(.bottom, 4)

                        ForEach(viewModel.state.servers) { server in
                            HStack(spacing: 10) {
                                Text(server.name)
                                    .font(.body)
                                    .frame(width: 220, alignment: .leading)

                                ForEach(viewModel.tools) { tool in
                                    Toggle("", isOn: binding(serverID: server.id, toolID: tool.id))
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .frame(width: 120)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(10)
                }
                .frame(minHeight: 210)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.03))
                )
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func binding(serverID: String, toolID: String) -> Binding<Bool> {
        Binding {
            viewModel.isEnabled(serverID: serverID, toolID: toolID)
        } set: { value in
            viewModel.setEnabled(serverID: serverID, toolID: toolID, enabled: value)
        }
    }
}

private struct LogPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("操作日志")
                    .font(.headline)
                Spacer()
                Button("清空") {
                    viewModel.logs.removeAll()
                }
                .buttonStyle(.borderless)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                .padding(10)
            }
            .frame(minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

@MainActor
private func selectDirectoryPanel(initialPath: String) -> String? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.title = "选择工作区目录"
    panel.directoryURL = URL(fileURLWithPath: initialPath, isDirectory: true)

    return panel.runModal() == .OK ? panel.url?.path : nil
}
