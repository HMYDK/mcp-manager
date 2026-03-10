# MCP Manager (macOS, SwiftUI)

这是一个仅支持 macOS 的原生桌面应用（SwiftUI），用于统一管理本地 MCP 服务，并控制它们在各 CLI 中的启用状态。

## 核心能力

- 只使用官方配置目录（内置锁定）
  - Codex CLI: `~/.codex/config.toml`
  - Claude Code (project): `<workspace>/.mcp.json`
  - Gemini CLI (project): `<workspace>/.gemini/settings.json`
- 统一维护 MCP 服务（命令、参数、env、cwd、描述）
- 矩阵开关控制 `MCP x CLI`
- 同步并检测
  - 写入各 CLI 官方配置
  - 检查 CLI 是否安装
  - 检查配置是否与矩阵一致
  - 展示每个 CLI 当前已配置 MCP 与外部已有 MCP

## 技术栈

- Swift 6
- SwiftUI (macOS 14+)
- 无前端 Web 运行时依赖

## 运行

```bash
swift build
swift run MCPManagerMac
```

## 目录结构

- `Package.swift`
- `Sources/MCPManagerMac/`
  - `MCPManagerMacApp.swift`
  - `Models.swift`
  - `Services/`
  - `ViewModels/`
  - `Views/`

## 状态文件

默认路径：

- `~/.mcp-manager/state.json`

若 home 不可写，会回退到：

- `<workspace>/.mcp-manager-data/state.json`
