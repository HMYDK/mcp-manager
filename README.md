# MCP Manager

**跨平台桌面应用** - 统一管理 MCP Server，让各种 AI Agent CLI 复用同一套配置。

## 🖥️ 平台支持

- ✅ macOS 12.0+
- ✅ Windows 10+
- ⏳ Linux（计划中）

## Features

- **Unified Management**: Manage all your MCP servers in one place
- **Multi-CLI Support**: Claude Code, Gemini CLI, QoderCLI
- **Auto-Scan**: Automatically discover installed MCP servers (npm/pip)
- **One-Click Enable**: Enable servers for multiple CLIs at once
- **Status Monitoring**: Real-time server status (running/stopped/error)
- **Dark/Light Theme**: Beautiful UI with theme support

## 📥 安装

### macOS / Windows（推荐）

**下载桌面应用安装包**：[Releases](https://github.com/HMYDK/mcp-manager/releases)

- macOS: `.dmg` 或 `.zip`
- Windows: `.exe` 安装程序

### 从源码构建

```bash
git clone https://github.com/HMYDK/mcp-manager.git
cd mcp-manager
npm install
npm run electron:build
```

## 💻 使用说明

1. **启动桌面应用** - 双击安装包或从源码运行
2. **扫描 MCP Server** - 自动发现已安装的 npm/pip 包
3. **配置 CLI 集成** - 一键为 Claude Code、Gemini CLI、QoderCLI 启用
4. **管理 Server 生命周期** - 启动/停止/监控状态

## Built With

- Electron
- TypeScript
- React
- TailwindCSS
- SQLite
- Zustand

## License

MIT
