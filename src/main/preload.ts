import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('electronAPI', {
  // Server management
  scanServers: () => ipcRenderer.invoke('server:scan'),
  installServer: (pkg: string, type: 'npm' | 'pip') => ipcRenderer.invoke('server:install', pkg, type),
  removeServer: (id: string, uninstallPackage: boolean) => ipcRenderer.invoke('server:remove', id, uninstallPackage),
  updateServer: (server: any) => ipcRenderer.invoke('server:update', server),
  checkStatus: (id: string) => ipcRenderer.invoke('server:checkStatus', id),
  checkAllStatus: () => ipcRenderer.invoke('server:checkAllStatus'),
  startServer: (id: string) => ipcRenderer.invoke('server:start', id),
  stopServer: (id: string) => ipcRenderer.invoke('server:stop', id),
  
  // CLI configuration
  updateForCLI: (serverId: string, cli: string, enabled: boolean) => ipcRenderer.invoke('adapter:updateForCLI', serverId, cli, enabled),
  updateForAllCLIs: (serverId: string, enabledFor: any) => ipcRenderer.invoke('adapter:updateForAllCLIs', serverId, enabledFor),
  
  // Preferences
  getPreferences: () => ipcRenderer.invoke('preferences:get'),
  setPreferences: (prefs: any) => ipcRenderer.invoke('preferences:set', prefs),
});
