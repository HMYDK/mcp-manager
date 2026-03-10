const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('mcpManager', {
  loadState: () => ipcRenderer.invoke('state:load'),
  saveState: (state) => ipcRenderer.invoke('state:save', state),

  addServer: (server) => ipcRenderer.invoke('server:add', server),
  updateServer: (server) => ipcRenderer.invoke('server:update', server),
  removeServer: (serverId) => ipcRenderer.invoke('server:remove', serverId),
  setMatrixEnabled: (serverId, toolId, enabled) =>
    ipcRenderer.invoke('matrix:set-enabled', { serverId, toolId, enabled }),

  sync: () => ipcRenderer.invoke('sync:run'),
  scanDiagnostics: () => ipcRenderer.invoke('diagnostics:scan'),
});
