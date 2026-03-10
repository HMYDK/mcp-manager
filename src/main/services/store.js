const fs = require('fs');
const os = require('os');
const path = require('path');
const { buildOfficialTools } = require('./toolRegistry');

function resolveAppDir() {
  const homeDir = path.join(os.homedir(), '.mcp-manager');
  try {
    fs.mkdirSync(homeDir, { recursive: true });
    return homeDir;
  } catch {
    const fallbackDir = path.join(process.cwd(), '.mcp-manager-data');
    fs.mkdirSync(fallbackDir, { recursive: true });
    return fallbackDir;
  }
}

const APP_DIR = resolveAppDir();
const STATE_PATH = path.join(APP_DIR, 'state.json');

function buildDefaultState() {
  return {
    version: 2,
    servers: [],
    tools: buildOfficialTools(process.cwd()),
    matrix: {},
    updatedAt: new Date().toISOString(),
  };
}

function ensureStateFile() {
  if (!fs.existsSync(APP_DIR)) {
    fs.mkdirSync(APP_DIR, { recursive: true });
  }

  if (!fs.existsSync(STATE_PATH)) {
    fs.writeFileSync(STATE_PATH, JSON.stringify(buildDefaultState(), null, 2), 'utf-8');
  }
}

function normalizeServers(rawServers) {
  if (!Array.isArray(rawServers)) {
    return [];
  }

  return rawServers
    .filter((item) => item && typeof item === 'object')
    .map((item) => ({
      id: String(item.id || ''),
      name: String(item.name || 'New MCP'),
      description: String(item.description || ''),
      command: String(item.command || ''),
      args: Array.isArray(item.args) ? item.args.map((v) => String(v)) : [],
      env: item.env && typeof item.env === 'object' ? item.env : {},
      cwd: String(item.cwd || ''),
    }))
    .filter((item) => item.id);
}

function normalizeMatrix(rawMatrix, servers, tools) {
  const matrix = {};

  for (const server of servers) {
    const sourceRow = rawMatrix && typeof rawMatrix === 'object' ? rawMatrix[server.id] : null;
    const row = {};

    for (const tool of tools) {
      row[tool.id] = Boolean(sourceRow && sourceRow[tool.id]);
    }

    matrix[server.id] = row;
  }

  return matrix;
}

function mergeTools(rawTools) {
  const officialTools = buildOfficialTools(process.cwd());
  const rawMap = new Map();

  if (Array.isArray(rawTools)) {
    for (const tool of rawTools) {
      if (tool && typeof tool === 'object' && tool.id) {
        rawMap.set(tool.id, tool);
      }
    }
  }

  return officialTools.map((tool) => {
    const raw = rawMap.get(tool.id);
    return {
      ...tool,
      name: raw && raw.name ? String(raw.name) : tool.name,
      configPath: tool.officialPath,
      officialPath: tool.officialPath,
      pathLocked: true,
    };
  });
}

function readState() {
  ensureStateFile();

  const raw = fs.readFileSync(STATE_PATH, 'utf-8');
  let parsed = {};

  try {
    parsed = JSON.parse(raw);
  } catch {
    parsed = {};
  }

  const tools = mergeTools(parsed.tools);
  const servers = normalizeServers(parsed.servers);
  const matrix = normalizeMatrix(parsed.matrix, servers, tools);

  return {
    version: 2,
    servers,
    tools,
    matrix,
    updatedAt: parsed.updatedAt || new Date().toISOString(),
  };
}

function writeState(state) {
  ensureStateFile();

  const tools = mergeTools(state.tools);
  const servers = normalizeServers(state.servers);
  const matrix = normalizeMatrix(state.matrix, servers, tools);

  const output = {
    version: 2,
    servers,
    tools,
    matrix,
    updatedAt: new Date().toISOString(),
  };

  fs.writeFileSync(STATE_PATH, JSON.stringify(output, null, 2), 'utf-8');
  return output;
}

module.exports = {
  readState,
  writeState,
};
