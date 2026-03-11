import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            SidebarStatusView()
                .navigationSplitViewColumnWidth(min: 320, ideal: 360, max: 400)
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

    private var effectiveCount: Int {
        viewModel.diagnostics.filter { $0.status == .effective }.count
    }

    private var partialCount: Int {
        viewModel.diagnostics.filter { $0.status == .partial }.count
    }

    private var inactiveCount: Int {
        viewModel.diagnostics.filter { $0.status == .notEffective }.count
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DashboardTheme.sidebarTop, DashboardTheme.sidebarBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(DashboardTheme.accent.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 32)
                .offset(x: 120, y: -250)

            Circle()
                .fill(DashboardTheme.mint.opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 46)
                .offset(x: -90, y: 300)

            VStack(alignment: .leading, spacing: 18) {
                SidebarOverviewCard(
                    summary: viewModel.statusSummary,
                    total: viewModel.tools.count,
                    effectiveCount: effectiveCount,
                    partialCount: partialCount,
                    inactiveCount: inactiveCount
                )

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.tools.isEmpty {
                            SidebarEmptyState()
                        }

                        ForEach(viewModel.tools) { tool in
                            ToolDiagnosisCard(tool: tool, diagnosis: viewModel.diagnosis(for: tool.id))
                        }
                    }
                }
                .scrollIndicators(.never)
            }
            .padding(18)
        }
    }
}

private struct SidebarOverviewCard: View {
    let summary: String
    let total: Int
    let effectiveCount: Int
    let partialCount: Int
    let inactiveCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CLI 生效状态")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 10) {
                SidebarMetricPill(title: "已生效", value: "\(effectiveCount)", tint: DashboardTheme.mint)
                SidebarMetricPill(title: "部分", value: "\(partialCount)", tint: DashboardTheme.amber)
                SidebarMetricPill(title: "未生效", value: "\(inactiveCount)", tint: DashboardTheme.rose)
            }

            HStack(spacing: 8) {
                Label("\(total) 个 CLI", systemImage: "terminal")
                Text("检测结果随同步实时更新")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.68))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.20), radius: 20, x: 0, y: 10)
    }
}

private struct SidebarMetricPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct SidebarEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("未发现可管理的 CLI", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.white)
            Text("切换工作区或刷新检测后，这里会列出当前支持的 CLI。")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.68))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ToolDiagnosisCard: View {
    let tool: CLITool
    let diagnosis: ToolDiagnosis?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(tool.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(diagnosis?.summary ?? "等待检测")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                StatusBadge(status: diagnosis?.status)
            }

            HStack(spacing: 8) {
                SidebarTag(
                    title: diagnosis?.cliInstalled == true ? "CLI 已就绪" : "CLI 未安装",
                    icon: diagnosis?.cliInstalled == true ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                SidebarTag(title: aliasText(diagnosis?.configuredAliases), icon: "shippingbox")
            }

            VStack(spacing: 10) {
                diagnosisLine("命令", diagnosis?.cliInstalled == true ? "\(tool.cliCommand) (\(diagnosis?.cliPath ?? ""))" : "未安装")
                diagnosisLine("官方路径", tool.officialPath)
                diagnosisLine("当前已配置", aliasText(diagnosis?.configuredAliases))
                diagnosisLine("外部已有", aliasText(diagnosis?.unmanagedConfigured))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DashboardTheme.statusColor(diagnosis?.status).opacity(0.96))
                .frame(width: 4)
                .padding(.vertical, 18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func diagnosisLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.56))
                .frame(width: 74, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.88))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
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

private struct SidebarTag: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
    }
}

private struct StatusBadge: View {
    let status: EffectivenessStatus?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.18))
        )
        .foregroundStyle(color)
    }

    private var label: String {
        status?.label ?? "待检测"
    }

    private var color: Color {
        DashboardTheme.statusColor(status)
    }
}

private struct MainWorkspaceView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DashboardTheme.backgroundTop, DashboardTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(DashboardTheme.accentSoft.opacity(0.22))
                .frame(width: 520, height: 520)
                .blur(radius: 60)
                .offset(x: 360, y: -280)

            Circle()
                .fill(DashboardTheme.mint.opacity(0.12))
                .frame(width: 420, height: 420)
                .blur(radius: 50)
                .offset(x: -300, y: 260)

            ScrollView {
                VStack(spacing: 18) {
                    WorkspaceHeroPanel()

                    HStack(alignment: .top, spacing: 16) {
                        ServerListPanel()
                            .frame(minWidth: 300, maxWidth: 360)
                        ServerEditorPanel()
                            .frame(maxWidth: .infinity)
                    }

                    MatrixPanel()
                    LogPanel()
                }
                .padding(20)
            }
            .scrollIndicators(.never)
        }
    }
}

private struct WorkspaceHeroPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    private var enabledLinkCount: Int {
        viewModel.state.matrix.values.reduce(0) { partialResult, row in
            partialResult + row.values.filter { $0 }.count
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MCP 控制台")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(DashboardTheme.ink)

                    Text("统一管理多个 CLI 的 MCP 配置、检测结果和启用关系。")
                        .font(.body)
                        .foregroundStyle(DashboardTheme.muted)

                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(DashboardTheme.accent)
                        Text(viewModel.state.workspaceRoot)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DashboardTheme.ink)
                            .textSelection(.enabled)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.70))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.80), lineWidth: 1)
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Button {
                        viewModel.syncAndScan()
                    } label: {
                        Label("同步并检测", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DashboardTheme.accent)
                    .controlSize(.large)

                    Button {
                        if let selected = selectDirectoryPanel(initialPath: viewModel.state.workspaceRoot) {
                            viewModel.setWorkspaceRoot(selected)
                        }
                    } label: {
                        Label("切换工作区", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        viewModel.addServer()
                    } label: {
                        Label("新增 MCP", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 12) {
                MetricHighlight(title: "MCP", value: "\(viewModel.state.servers.count)", subtitle: "当前工作区服务", tint: DashboardTheme.accent)
                MetricHighlight(title: "CLI", value: "\(viewModel.tools.count)", subtitle: "已识别客户端", tint: DashboardTheme.mint)
                MetricHighlight(title: "启用关系", value: "\(enabledLinkCount)", subtitle: "矩阵中已打开", tint: DashboardTheme.amber)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.96), DashboardTheme.accentSoft.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: DashboardTheme.shadow, radius: 22, x: 0, y: 14)
    }
}

private struct MetricHighlight: View {
    let title: String
    let value: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(DashboardTheme.muted)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.60))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct ServerListPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        PanelSurface {
            VStack(alignment: .leading, spacing: 14) {
                PanelHeader(
                    title: "MCP 列表",
                    subtitle: "选择一个服务后在右侧编辑详情。"
                )

                if viewModel.state.servers.isEmpty {
                    EmptyPanelState(
                        title: "还没有 MCP",
                        message: "先新增一个服务，再配置命令、参数和启用关系。",
                        icon: "shippingbox"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.state.servers) { server in
                                ServerRowCard(server: server, selected: viewModel.selectedServerID == server.id)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.removeServer(id: server.id)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .frame(minHeight: 360)
                    .scrollIndicators(.never)
                }

                if let selectedServerID = viewModel.selectedServerID {
                    Button(role: .destructive) {
                        viewModel.removeServer(id: selectedServerID)
                    } label: {
                        Label("删除选中 MCP", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .onAppear {
            viewModel.selectFirstServerIfNeeded()
        }
    }
}

private struct ServerRowCard: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let server: MCPServer
    let selected: Bool

    private var enabledCount: Int {
        viewModel.state.matrix[server.id]?.values.filter { $0 }.count ?? 0
    }

    var body: some View {
        Button {
            viewModel.selectedServerID = server.id
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.headline)
                            .foregroundStyle(selected ? Color.white : DashboardTheme.ink)
                        Text(server.command.isEmpty ? "未填写命令" : server.command)
                            .font(.caption)
                            .foregroundStyle(selected ? Color.white.opacity(0.84) : DashboardTheme.muted)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text("\(enabledCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selected ? .white : DashboardTheme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selected ? Color.white.opacity(0.16) : DashboardTheme.accent.opacity(0.12))
                        )
                }

                if !server.description.isEmpty {
                    Text(server.description)
                        .font(.caption)
                        .foregroundStyle(selected ? Color.white.opacity(0.82) : DashboardTheme.muted)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Label("\(server.args.count) 参数", systemImage: "slider.horizontal.3")
                    Label(server.cwd.isEmpty ? "默认目录" : "自定义目录", systemImage: "folder")
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(selected ? Color.white.opacity(0.74) : DashboardTheme.muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        selected
                            ? LinearGradient(
                                colors: [DashboardTheme.accent, DashboardTheme.accentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.86), Color.white.opacity(0.66)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? Color.white.opacity(0.28) : DashboardTheme.border.opacity(0.60), lineWidth: 1)
            )
            .shadow(color: selected ? DashboardTheme.accent.opacity(0.20) : Color.clear, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
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
        PanelSurface {
            VStack(alignment: .leading, spacing: 16) {
                PanelHeader(
                    title: "MCP 详情",
                    subtitle: "配置命令、参数、环境变量和工作目录。"
                )

                if let binding = selectedServerBinding {
                    VStack(spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            LabeledField(
                                title: "名称",
                                caption: "用于展示和生成配置别名。",
                                placeholder: "例如 filesystem",
                                text: binding.name
                            )
                            LabeledField(
                                title: "命令",
                                caption: "启动 MCP 的可执行文件。",
                                placeholder: "例如 npx",
                                text: binding.command,
                                monospaced: true
                            )
                        }

                        HStack(alignment: .top, spacing: 14) {
                            LabeledField(
                                title: "参数",
                                caption: "使用空格分隔，保存时会拆分成数组。",
                                placeholder: "例如 -y @modelcontextprotocol/server-filesystem",
                                text: $argsText,
                                monospaced: true
                            )
                            LabeledField(
                                title: "工作目录",
                                caption: "留空时使用默认目录。",
                                placeholder: "/path/to/workspace",
                                text: binding.cwd,
                                monospaced: true
                            )
                        }

                        LabeledTextEditor(
                            title: "环境变量 JSON",
                            caption: "填写 JSON 对象，保存时会转为字符串字典。",
                            text: $envText,
                            monospaced: true,
                            minHeight: 116
                        )

                        LabeledTextEditor(
                            title: "说明",
                            caption: "记录用途、注意事项或接入方式。",
                            text: binding.description,
                            minHeight: 92
                        )

                        HStack {
                            if !validationMessage.isEmpty {
                                Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(DashboardTheme.rose)
                            }

                            Spacer()

                            Button("保存当前 MCP") {
                                save(server: binding)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DashboardTheme.accent)
                        }
                    }
                } else {
                    EmptyPanelState(
                        title: "请选择一个 MCP",
                        message: "从左侧列表选择一个服务，或先新增一个服务再开始编辑。",
                        icon: "square.and.pencil"
                    )
                    .frame(minHeight: 340)
                }
            }
        }
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
            envText = text
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

private struct LabeledField: View {
    let title: String
    let caption: String
    let placeholder: String
    @Binding var text: String
    var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DashboardTheme.ink)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.muted)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .foregroundStyle(DashboardTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.76))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(DashboardTheme.border.opacity(0.70), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LabeledTextEditor: View {
    let title: String
    let caption: String
    @Binding var text: String
    var monospaced = false
    var minHeight: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DashboardTheme.ink)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.muted)
            }

            TextEditor(text: $text)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .foregroundStyle(DashboardTheme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.76))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(DashboardTheme.border.opacity(0.70), lineWidth: 1)
                )
        }
    }
}

private struct MatrixPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        PanelSurface {
            VStack(alignment: .leading, spacing: 16) {
                PanelHeader(
                    title: "启用矩阵",
                    subtitle: "决定每个 CLI 应该启用哪些 MCP。"
                )

                if viewModel.state.servers.isEmpty || viewModel.tools.isEmpty {
                    EmptyPanelState(
                        title: "没有可展示的矩阵",
                        message: "先新增 MCP，或切换到包含受支持 CLI 的工作区。",
                        icon: "tablecells"
                    )
                } else {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Text("MCP / CLI")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DashboardTheme.muted)
                                    .frame(width: 240, alignment: .leading)

                                ForEach(viewModel.tools) { tool in
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(DashboardTheme.statusColor(viewModel.diagnosis(for: tool.id)?.status))
                                            .frame(width: 8, height: 8)
                                        Text(tool.name)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(DashboardTheme.ink)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(width: 128, height: 58)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color.white.opacity(0.70))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(DashboardTheme.border.opacity(0.56), lineWidth: 1)
                                    )
                                }
                            }

                            ForEach(viewModel.state.servers) { server in
                                MatrixRow(server: server)
                            }
                        }
                        .padding(4)
                    }
                    .frame(minHeight: 230)
                }
            }
        }
    }
}

private struct MatrixRow: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let server: MCPServer

    private var enabledCount: Int {
        viewModel.state.matrix[server.id]?.values.filter { $0 }.count ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)
                    .foregroundStyle(DashboardTheme.ink)
                Text("\(enabledCount) / \(viewModel.tools.count) 已启用")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.muted)
            }
            .frame(width: 240, alignment: .leading)

            ForEach(viewModel.tools) { tool in
                Toggle("", isOn: binding(serverID: server.id, toolID: tool.id))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .frame(width: 128, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.72))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(DashboardTheme.border.opacity(0.52), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.86), Color.white.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(DashboardTheme.border.opacity(0.56), lineWidth: 1)
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
        PanelSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    PanelHeader(
                        title: "操作日志",
                        subtitle: "最近的状态加载、保存、同步和检测都会记录在这里。"
                    )

                    Spacer()

                    Button("清空") {
                        viewModel.logs.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(DashboardTheme.muted)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if viewModel.logs.isEmpty {
                            Text("暂无日志")
                                .font(.callout)
                                .foregroundStyle(Color.white.opacity(0.56))
                        } else {
                            ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { _, line in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(DashboardTheme.accentSoft)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)

                                    Text(line)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.88))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .frame(minHeight: 170)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DashboardTheme.consoleTop, DashboardTheme.consoleBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
}

private struct PanelSurface<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DashboardTheme.surfaceStrong, DashboardTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.88), lineWidth: 1)
        )
        .shadow(color: DashboardTheme.shadow, radius: 20, x: 0, y: 12)
    }
}

private struct PanelHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DashboardTheme.ink)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(DashboardTheme.muted)
        }
    }
}

private struct EmptyPanelState: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(DashboardTheme.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(DashboardTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DashboardTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.60))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(DashboardTheme.border.opacity(0.54), lineWidth: 1)
        )
    }
}

private enum DashboardTheme {
    static let backgroundTop = Color(red: 0.96, green: 0.95, blue: 0.91)
    static let backgroundBottom = Color(red: 0.88, green: 0.91, blue: 0.95)

    static let sidebarTop = Color(red: 0.12, green: 0.16, blue: 0.23)
    static let sidebarBottom = Color(red: 0.21, green: 0.27, blue: 0.34)

    static let surface = Color.white.opacity(0.78)
    static let surfaceStrong = Color.white.opacity(0.92)
    static let border = Color(red: 0.80, green: 0.84, blue: 0.89)

    static let accent = Color(red: 0.10, green: 0.44, blue: 0.88)
    static let accentSoft = Color(red: 0.48, green: 0.69, blue: 0.95)
    static let mint = Color(red: 0.30, green: 0.74, blue: 0.63)
    static let amber = Color(red: 0.92, green: 0.63, blue: 0.18)
    static let rose = Color(red: 0.84, green: 0.37, blue: 0.43)

    static let ink = Color(red: 0.15, green: 0.19, blue: 0.24)
    static let muted = Color(red: 0.43, green: 0.48, blue: 0.55)

    static let consoleTop = Color(red: 0.13, green: 0.16, blue: 0.22)
    static let consoleBottom = Color(red: 0.08, green: 0.10, blue: 0.14)

    static let shadow = Color.black.opacity(0.08)

    static func statusColor(_ status: EffectivenessStatus?) -> Color {
        switch status {
        case .effective:
            return mint
        case .partial:
            return amber
        case .notEffective:
            return rose
        case .none:
            return accentSoft
        }
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
