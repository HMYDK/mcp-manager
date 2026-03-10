const crypto = require('crypto');
const { readState, writeState } = require('./store');
const { syncAllToolConfigs, scanToolDiagnostics } = require('./toolAdapters');

function uid(prefix) {
  return `${prefix}-${crypto.randomUUID()}`;
}

function normalizeServer(server) {
  return {
    id: server.id || uid('srv'),
    name: server.name || 'New MCP',
    description: server.description || '',
    command: server.command || '',
    args: Array.isArray(server.args) ? server.args : [],
    env: server.env && typeof server.env === 'object' ? server.env : {},
    cwd: server.cwd || '',
  };
}

function loadState() {
  return readState();
}

function saveState(state) {
  return writeState(state);
}

function addServer(server) {
  const state = readState();
  const normalized = normalizeServer(server);

  state.servers.push(normalized);
  state.matrix[normalized.id] = state.matrix[normalized.id] || {};

  for (const tool of state.tools) {
    if (typeof state.matrix[normalized.id][tool.id] !== 'boolean') {
      state.matrix[normalized.id][tool.id] = false;
    }
  }

  return writeState(state);
}

function updateServer(server) {
  const state = readState();
  const index = state.servers.findIndex((item) => item.id === server.id);

  if (index < 0) {
    throw new Error(`Server not found: ${server.id}`);
  }

  const next = normalizeServer(server);
  next.id = server.id;

  state.servers[index] = next;
  return writeState(state);
}

function removeServer(serverId) {
  const state = readState();
  state.servers = state.servers.filter((server) => server.id !== serverId);
  delete state.matrix[serverId];

  return writeState(state);
}

function setServerToolEnabled(serverId, toolId, enabled) {
  const state = readState();

  if (!state.servers.find((server) => server.id === serverId)) {
    throw new Error(`Server not found: ${serverId}`);
  }

  if (!state.tools.find((tool) => tool.id === toolId)) {
    throw new Error(`Tool not found: ${toolId}`);
  }

  state.matrix[serverId] = state.matrix[serverId] || {};
  state.matrix[serverId][toolId] = Boolean(enabled);

  return writeState(state);
}

function syncToolConfigs() {
  const state = readState();
  return syncAllToolConfigs(state);
}

function scanDiagnostics() {
  const state = readState();
  return scanToolDiagnostics(state);
}

module.exports = {
  loadState,
  saveState,
  addServer,
  updateServer,
  removeServer,
  setServerToolEnabled,
  syncToolConfigs,
  scanDiagnostics,
};
