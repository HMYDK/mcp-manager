# MCP Manager

Unified MCP Server Manager for AI Agent CLIs.

## Features

- **Unified Management**: Manage all your MCP servers in one place
- **Multi-CLI Support**: Claude Code, Gemini CLI, QoderCLI
- **Auto-Scan**: Automatically discover installed MCP servers (npm/pip)
- **One-Click Enable**: Enable servers for multiple CLIs at once
- **Status Monitoring**: Real-time server status (running/stopped/error)
- **Dark/Light Theme**: Beautiful UI with theme support

## Installation

### macOS / Windows

Download the latest release from [Releases](https://github.com/HMYDK/mcp-manager/releases).

### From Source

```bash
git clone https://github.com/HMYDK/mcp-manager.git
cd mcp-manager
npm install
npm run dev
```

## Usage

1. Launch MCP Manager
2. Scan for installed MCP servers or add manually
3. Enable servers for your preferred AI CLIs
4. Manage server lifecycle (start/stop/restart)

## Built With

- Electron
- TypeScript
- React
- TailwindCSS
- SQLite
- Zustand

## License

MIT
