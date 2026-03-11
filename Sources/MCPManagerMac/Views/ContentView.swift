import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            SidebarStatusView()
                .navigationSplitViewColumnWidth(min: 300, ideal: 340)
        } detail: {
            MainWorkspaceView()
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MCP Manager")
                    .font(.title2.weight(.semibold))
                Text("参考 macOS 应用的侧边状态总览")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)

            MacPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("CLI 生效状态")
                        .font(.headline)
                    Text(viewModel.statusSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        BadgeMetric(title: "CLI", value: "\(viewModel.tools.count)", color: .blue)
                        BadgeMetric(title: "MCP", value: "\(viewModel.state.servers.count)", color: .purple)
                    }
                }
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.tools) { tool in
                        ToolDiagnosisCard(tool: tool, diagnosis: viewModel.diagnosis(for: tool.id))
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct ToolDiagnosisCard: View {
    let tool: CLITool
    let diagnosis: ToolDiagnosis?

    var body: some View {
        MacPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .foregroundStyle(.secondary)
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
        }
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

private struct BadgeMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color.opacity(0.12)))
    }
}

private struct MacPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
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
                        .frame(minWidth: 280, maxWidth: 340)
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
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .underPageBackgroundColor).opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var workspaceHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("工作区")
                    .font(.headline)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}

private struct ServerListPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MCP 列表")
                .font(.headline)

            List(selection: $viewModel.selectedServerID) {
                ForEach(viewModel.state.servers) { server in
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
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
                VStack(spacing: 10) {
                    inputRow(title: "名称") { TextField("例如：filesystem", text: binding.name) }
                    inputRow(title: "命令") { TextField("例如：npx", text: binding.command) }
                    inputRow(title: "参数") { TextField("空格分隔", text: $argsText) }
                    inputRow(title: "工作目录") { TextField("可选", text: binding.cwd) }
                    inputRow(title: "环境变量") { TextField("JSON", text: $envText) }
                    inputRow(title: "说明") { TextField("可选", text: binding.description) }
                }
                .frame(minHeight: 240)

                if !validationMessage.isEmpty {
                    Text(validationMessage)
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
        .onAppear {
            reloadDraft()
        }
        .onChange(of: viewModel.selectedServerID) { _, _ in
            reloadDraft()
            validationMessage = ""
        }
    }

    private func inputRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
                .textFieldStyle(.roundedBorder)
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
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
