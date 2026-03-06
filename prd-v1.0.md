# MCP Manager - 产品需求文档 (PRD)

**版本**: v1.0  
**创建时间**: 2026-03-06  
**创建人**: 项目经理 (@project-manager:matrix-local.hiclaw.io:18080)  
**状态**: 待张凯确认  

---

## 1. 产品概述

### 1.1 产品名称
**MCP Manager**

### 1.2 产品定位
统一管理本地所有 MCP Server 的桌面应用，让各种 Agent CLI（Claude Code、Gemini CLI、QoderCLI 等）都能复用同一套 MCP 配置。

### 1.3 目标用户
- 使用多个 Agent CLI 的开发者
- 需要频繁切换/管理 MCP Server 的用户
- 希望简化 MCP 配置流程的技术人员

### 1.4 核心价值
- **统一管理**：一个界面管理所有 MCP Server
- **配置复用**：一次配置，多 CLI 复用
- **降低门槛**：简化 MCP Server 的安装和配置流程

---

## 2. 功能需求

### 2.1 MVP（核心功能）

#### 2.1.1 MCP Server 管理
| 功能 | 描述 | 优先级 |
|------|------|--------|
| 扫描已安装 Server | 自动扫描本地已安装的 MCP Server（npm global、pip 等） | P0 |
| 注册 Server | 手动添加已安装但未扫描到的 Server | P0 |
| 一键安装 | 内置常用 MCP Server 列表，点击即可通过 npm/pip 安装 | P0 |
| 卸载/移除 | 从管理列表移除（可选是否同时卸载包） | P0 |
| 启用/禁用 | 快速切换 Server 的启用状态 | P0 |
| 状态监控 | 显示 Server 运行状态（运行/停止/错误） | P1 |

#### 2.1.2 Agent CLI 配置
| 功能 | 描述 | 优先级 |
|------|------|--------|
| 多 CLI 支持 | 支持 Claude Code、Gemini CLI、QoderCLI | P0 |
| 一键启用 | 为选中的 CLI 自动配置 MCP Server | P0 |
| 全选操作 | 一键为所有 CLI 启用某 MCP Server | P0 |
| 配置编辑 | 支持编辑 MCP Server 的 JSON/YAML 配置 | P1 |
| 配置验证 | 检查配置文件格式是否正确 | P1 |

#### 2.1.3 用户界面
| 功能 | 描述 | 优先级 |
|------|------|--------|
| Server 列表 | 展示所有 MCP Server 及状态 | P0 |
| 搜索过滤 | 快速查找 Server | P0 |
| 深色/浅色模式 | 跟随系统或手动切换 | P1 |
| 状态指示 | 颜色 + 图标清晰显示状态 | P0 |

### 2.2 后续迭代（非 MVP）

| 功能 | 描述 | 优先级 |
|------|------|--------|
| MCP Server 市场 | 推荐常用 MCP Server 列表 | P2 |
| 配置模板库 | 预设常用 Server 配置模板 | P2 |
| 使用统计 | 分析 MCP Server 使用频率 | P3 |
| 云同步 | 通过 Git 或 WebDAV 同步配置 | P2 |
| 更多 CLI 支持 | Cursor 等其他工具 | P2 |

---

## 3. 技术规格

### 3.1 技术栈
| 组件 | 技术选型 |
|------|----------|
| 应用框架 | Electron |
| 开发语言 | TypeScript |
| UI 框架 | React + TailwindCSS |
| 本地存储 | SQLite（Server 元数据） |
| 配置文件 | JSON（Manager 自身配置） |

### 3.2 数据存储

#### 3.2.1 Manager 自身配置
- **位置**: Electron `app.getPath('userData')`
  - macOS: `~/Library/Application Support/mcp-manager/`
  - Windows: `%APPDATA%/mcp-manager/`
- **文件**:
  - `config.json` - 窗口位置、主题、偏好设置
  - `mcp-servers.db` - SQLite 数据库，存储 Server 元数据

#### 3.2.2 Agent CLI 配置
保持各 CLI 原生配置格式和位置：
- **Claude Code**: `~/.claude/settings.json`
- **Gemini CLI**: （调研后补充）
- **QoderCLI**: （调研后补充）

### 3.3 插件化架构
每种 Agent CLI 作为独立的配置适配器，便于后续扩展：
```
adapters/
├── claude-code.ts
├── gemini-cli.ts
├── qoder-cli.ts
└── [future-cli].ts
```

---

## 4. UI/UX 设计

### 4.1 设计风格
- **风格**: 简洁 + 专业
- **模式**: 深色模式优先，支持浅色模式
- **参考**: Raycast、Warp Terminal

### 4.2 核心界面

#### 4.2.1 主界面 - Server 列表
```
┌────────────────────────────────────────────────┐
│  MCP Manager                          [-][□][X]│
├────────────────────────────────────────────────┤
│  🔍 搜索 Server...                             │
│                                                │
│  ┌──────────────────────────────────────────┐  │
│  │ ☐ @modelcontextprotocol/server-memory   │  │
│  │   🟢 运行中  |  npm: @mcp/memory         │  │
│  │   [Claude] [Gemini] [QoderCLI] [编辑]    │  │
│  ├──────────────────────────────────────────┤  │
│  │ ☐ @modelcontextprotocol/server-files    │  │
│  │   🔴 已停止  |  npm: @mcp/files          │  │
│  │   [✓] [✓] [ ] [编辑]                     │  │
│  ├──────────────────────────────────────────┤  │
│  │ ☐ @anthropic/mcp-server-time            │  │
│  │   ⚠️  未安装  |  npm: @anthropic/time    │  │
│  │   [安装]                                  │  │
│  └──────────────────────────────────────────┘  │
│                                                │
│  [+ 添加 Server]  [刷新]                       │
└────────────────────────────────────────────────┘
```

#### 4.2.2 Server 详情/编辑
- Server 名称、描述
- 安装路径/包名
- 配置参数（JSON/YAML 编辑器）
- 日志查看
- 测试连接

### 4.3 交互细节
- 复选框快速启用/禁用 CLI 配置
- 右键菜单：安装/卸载/编辑/删除
- 拖拽排序（可选）
- 键盘快捷键（可选）

---

## 5. 平台支持

| 平台 | 版本 | 支持 |
|------|------|------|
| macOS | 12.0+ | ✅ |
| Windows | 10+ | ✅ |
| Linux | - | ⏳ 后续考虑 |

---

## 6. 非功能需求

### 6.1 性能
- 启动时间 < 3 秒
- Server 扫描时间 < 5 秒
- 配置更新即时生效

### 6.2 安全
- 不存储任何 API Key 或敏感凭证
- 配置文件读写需用户授权
- 安装操作需用户确认

### 6.3 可维护性
- 代码覆盖率 > 70%
- 完整的开发文档
- 清晰的模块边界

---

## 7. 开发计划（待全栈小张估算）

### 7.1 阶段划分
| 阶段 | 内容 | 预计工时 |
|------|------|----------|
| Phase 1 | 项目骨架 + 基础 UI | TBD |
| Phase 2 | Server 扫描/注册功能 | TBD |
| Phase 3 | CLI 配置适配器 | TBD |
| Phase 4 | 安装/卸载功能 | TBD |
| Phase 5 | 测试 + 优化 | TBD |

### 7.2 里程碑
- **MVP 完成**: TBD（全栈小张评估后补充）
- **Beta 测试**: TBD
- **正式发布**: TBD

---

## 8. 风险与依赖

### 8.1 技术风险
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 各 CLI 配置格式变化 | 中 | 插件化架构，快速适配 |
| Electron 原生模块兼容性 | 中 | 充分测试，提供降级方案 |
| MCP 协议变更 | 低 | 关注官方动态，及时更新 |

### 8.2 外部依赖
- npm/pip 包管理器可用
- 各 Agent CLI 保持 MCP 配置格式稳定

---

## 9. 成功指标

### 9.1 产品指标
- 支持的 MCP Server 数量 > 10
- 支持的 Agent CLI 数量 >= 3
- 用户配置时间减少 50%

### 9.2 技术指标
- 无崩溃运行
- 配置同步准确率 100%

---

## 10. 附录

### 10.1 术语表
| 术语 | 解释 |
|------|------|
| MCP | Model Context Protocol，AI 模型上下文协议 |
| MCP Server | 提供特定能力的 MCP 服务 |
| Agent CLI | 支持 MCP 的命令行工具（Claude Code 等） |

### 10.2 参考资料
- MCP 官方文档：https://modelcontextprotocol.io/
- Claude Code MCP 配置：（待补充）
- Gemini CLI 配置：（待补充）
- QoderCLI 配置：（待补充）

---

## 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| v1.0 | 2026-03-06 | 初稿 | 项目经理 |

---

**审批流程**:
- [ ] 张凯确认
- [ ] 全栈小张 review
- [ ] 最终确认，开始开发
