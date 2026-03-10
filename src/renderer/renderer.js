let state = null;
let diagnostics = [];

const elToolStatusList = document.getElementById('tool-status-list');
const elServerList = document.getElementById('server-list');
const elMatrixWrap = document.getElementById('matrix-wrap');
const elLog = document.getElementById('log');
const elHealthSummary = document.getElementById('health-summary');
const elWorkspaceLabel = document.getElementById('workspace-label');

const serverTemplate = document.getElementById('server-item-template');

function log(message, data) {
  const ts = new Date().toLocaleString();
  const payload = data ? `\n${JSON.stringify(data, null, 2)}` : '';
  elLog.textContent = `[${ts}] ${message}${payload}\n` + elLog.textContent;
}

function parseArgs(text) {
  const value = String(text || '').trim();
  if (!value) return [];
  return value.split(/\s+/g);
}

function parseEnv(text) {
  const value = String(text || '').trim();
  if (!value) return {};

  try {
    const parsed = JSON.parse(value);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error('环境变量必须是 JSON 对象');
    }
    return parsed;
  } catch {
    throw new Error('环境变量必须是 JSON，例如 {"API_KEY":"xxx"}');
  }
}

function diagnosisByToolId(toolId) {
  return diagnostics.find((item) => item.toolId === toolId);
}

function statusLabel(status) {
  if (status === 'effective') return '已生效';
  if (status === 'partial') return '部分生效';
  return '未生效';
}

function statusClass(status) {
  if (status === 'effective') return 'badge-effective';
  if (status === 'partial') return 'badge-partial';
  return 'badge-not';
}

function formatAliasList(values) {
  if (!Array.isArray(values) || values.length === 0) {
    return '无';
  }
  return values.join(', ');
}

function renderHealthSummary() {
  const total = diagnostics.length;
  const effectiveCount = diagnostics.filter((item) => item.status === 'effective').length;
  const partialCount = diagnostics.filter((item) => item.status === 'partial').length;
  const notCount = diagnostics.filter((item) => item.status === 'not_effective').length;

  elHealthSummary.textContent = `工具状态：${effectiveCount}/${total} 已生效，${partialCount} 部分生效，${notCount} 未生效`;
}

function renderToolStatus() {
  elToolStatusList.innerHTML = '';

  if (state.tools.length === 0) {
    elToolStatusList.innerHTML = '<p class="empty-state">暂无工具。</p>';
    return;
  }

  for (const tool of state.tools) {
    const diagnosis = diagnosisByToolId(tool.id);

    const card = document.createElement('article');
    card.className = 'tool-card';

    const head = document.createElement('div');
    head.className = 'tool-head';

    const title = document.createElement('h3');
    title.className = 'tool-name';
    title.textContent = tool.name;

    const badge = document.createElement('span');
    badge.className = `badge ${statusClass(diagnosis?.status || 'not_effective')}`;
    badge.textContent = statusLabel(diagnosis?.status || 'not_effective');

    head.appendChild(title);
    head.appendChild(badge);

    const meta = document.createElement('div');
    meta.className = 'tool-meta';

    const commandLine = diagnosis?.cliInstalled
      ? `${tool.cliCommand} 已安装 (${diagnosis.cliPath})`
      : `${tool.cliCommand} 未安装`;

    meta.innerHTML = `
      <div><strong>命令：</strong><span class="mono">${commandLine}</span></div>
      <div><strong>官方路径：</strong><span class="mono">${tool.officialPath}</span></div>
      <div><strong>配置文件：</strong>${diagnosis?.configExists ? '已存在' : '不存在（同步时会创建）'}</div>
      <div><strong>启用数：</strong>${diagnosis?.enabledCount ?? 0}</div>
      <div><strong>当前已配置 MCP：</strong>${diagnosis ? formatAliasList(diagnosis.configuredAliases) : '检测中'}</div>
      <div><strong>外部已有 MCP：</strong>${diagnosis ? formatAliasList(diagnosis.unmanagedConfigured) : '检测中'}</div>
    `;

    const summary = document.createElement('div');
    summary.className = 'tool-summary';

    const warnings = [];
    if (diagnosis?.missingEnabled?.length) {
      warnings.push(`缺失: ${diagnosis.missingEnabled.join(', ')}`);
    }
    if (diagnosis?.managedButDisabled?.length) {
      warnings.push(`应关闭但仍存在: ${diagnosis.managedButDisabled.join(', ')}`);
    }
    if (diagnosis?.parseError) {
      warnings.push(`解析错误: ${diagnosis.parseError}`);
    }

    summary.textContent = warnings.length > 0 ? warnings.join(' | ') : diagnosis?.summary || '等待检测';

    card.appendChild(head);
    card.appendChild(meta);
    card.appendChild(summary);
    elToolStatusList.appendChild(card);
  }
}

function renderServers() {
  elServerList.innerHTML = '';

  if (state.servers.length === 0) {
    elServerList.innerHTML = '<p class="empty-state">暂无 MCP 服务，点击“新增服务”开始。</p>';
    return;
  }

  for (const server of state.servers) {
    const node = serverTemplate.content.firstElementChild.cloneNode(true);
    const fields = node.querySelectorAll('[data-key]');

    fields.forEach((field) => {
      const key = field.dataset.key;
      if (key === 'args') {
        field.value = (server.args || []).join(' ');
      } else if (key === 'env') {
        field.value = server.env && Object.keys(server.env).length ? JSON.stringify(server.env) : '';
      } else {
        field.value = server[key] || '';
      }
    });

    node.querySelector('[data-action="save"]').addEventListener('click', async () => {
      try {
        const next = {
          id: server.id,
          name: node.querySelector('[data-key="name"]').value.trim(),
          command: node.querySelector('[data-key="command"]').value.trim(),
          args: parseArgs(node.querySelector('[data-key="args"]').value),
          cwd: node.querySelector('[data-key="cwd"]').value.trim(),
          env: parseEnv(node.querySelector('[data-key="env"]').value),
          description: node.querySelector('[data-key="description"]').value.trim(),
        };

        if (!next.name) throw new Error('名称不能为空');
        if (!next.command) throw new Error('命令不能为空');

        await window.mcpManager.updateServer(next);
        await reload({ scan: false });
        log(`已保存 MCP：${next.name}`);
      } catch (error) {
        log(`保存 MCP 失败：${error.message}`);
      }
    });

    node.querySelector('[data-action="delete"]').addEventListener('click', async () => {
      await window.mcpManager.removeServer(server.id);
      await reload({ scan: false });
      log(`已删除 MCP：${server.name}`);
    });

    elServerList.appendChild(node);
  }
}

function renderMatrix() {
  if (state.servers.length === 0 || state.tools.length === 0) {
    elMatrixWrap.innerHTML = '<p class="empty-state">请先添加 MCP 服务。</p>';
    return;
  }

  const table = document.createElement('table');
  table.className = 'matrix-table';

  const thead = document.createElement('thead');
  const headRow = document.createElement('tr');
  headRow.innerHTML = `<th>MCP / CLI</th>${state.tools.map((tool) => `<th>${tool.name}</th>`).join('')}`;
  thead.appendChild(headRow);
  table.appendChild(thead);

  const tbody = document.createElement('tbody');

  for (const server of state.servers) {
    const row = document.createElement('tr');

    const nameCell = document.createElement('td');
    nameCell.textContent = server.name;
    row.appendChild(nameCell);

    for (const tool of state.tools) {
      const cell = document.createElement('td');
      const wrapper = document.createElement('label');
      wrapper.className = 'switch';

      const input = document.createElement('input');
      input.type = 'checkbox';
      input.checked = Boolean((state.matrix[server.id] || {})[tool.id]);

      const track = document.createElement('span');
      track.className = 'switch-track';

      input.addEventListener('change', async () => {
        await window.mcpManager.setMatrixEnabled(server.id, tool.id, input.checked);
        state.matrix[server.id] = state.matrix[server.id] || {};
        state.matrix[server.id][tool.id] = input.checked;

        log(`${tool.name}: ${server.name} ${input.checked ? '启用' : '禁用'}`);
      });

      wrapper.appendChild(input);
      wrapper.appendChild(track);
      cell.appendChild(wrapper);
      row.appendChild(cell);
    }

    tbody.appendChild(row);
  }

  table.appendChild(tbody);
  elMatrixWrap.innerHTML = '';
  elMatrixWrap.appendChild(table);
}

async function scan() {
  const result = await window.mcpManager.scanDiagnostics();
  diagnostics = result.diagnostics || [];
  renderToolStatus();
  renderHealthSummary();
  return result;
}

async function reload(options = { scan: true }) {
  state = await window.mcpManager.loadState();

  if (options.scan) {
    await scan();
  } else {
    renderToolStatus();
    renderHealthSummary();
  }

  renderServers();
  renderMatrix();

  const projectPath = state.tools.find((tool) => tool.scope === 'project')?.officialPath || '';
  const workspaceRoot = projectPath.includes('/.mcp.json')
    ? projectPath.replace('/.mcp.json', '')
    : projectPath.replace('/.gemini/settings.json', '');
  elWorkspaceLabel.textContent = workspaceRoot ? `工作区: ${workspaceRoot}` : '';
}

document.getElementById('btn-add-server').addEventListener('click', async () => {
  await window.mcpManager.addServer({
    name: 'new-mcp',
    command: '',
    args: [],
    env: {},
    cwd: '',
    description: '',
  });

  await reload({ scan: false });
  log('已新增 MCP 服务');
});

document.getElementById('btn-refresh').addEventListener('click', async () => {
  await reload({ scan: true });
  log('已刷新并重新检测');
});

document.getElementById('btn-scan').addEventListener('click', async () => {
  const result = await scan();
  log('检测完成', result);
});

document.getElementById('btn-sync').addEventListener('click', async () => {
  const result = await window.mcpManager.sync();
  diagnostics = result.diagnostics || [];
  renderToolStatus();
  renderHealthSummary();
  log('同步并检测完成', result);
});

reload({ scan: true }).catch((error) => {
  log(`初始化失败：${error.message}`);
});
