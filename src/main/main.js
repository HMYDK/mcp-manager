const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const {
  loadState,
  saveState,
  addServer,
  updateServer,
  removeServer,
  setServerToolEnabled,
  syncToolConfigs,
  scanDiagnostics,
} = require('./services/mcpService');

function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 1080,
    minHeight: 720,
    title: 'MCP Manager',
    backgroundColor: '#eff1f5',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  win.loadFile(path.join(__dirname, '../renderer/index.html'));
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

ipcMain.handle('state:load', () => loadState());
ipcMain.handle('state:save', (_, state) => saveState(state));

ipcMain.handle('server:add', (_, server) => addServer(server));
ipcMain.handle('server:update', (_, server) => updateServer(server));
ipcMain.handle('server:remove', (_, serverId) => removeServer(serverId));
ipcMain.handle('matrix:set-enabled', (_, payload) =>
  setServerToolEnabled(payload.serverId, payload.toolId, payload.enabled)
);

ipcMain.handle('sync:run', () => syncToolConfigs());
ipcMain.handle('diagnostics:scan', () => scanDiagnostics());
