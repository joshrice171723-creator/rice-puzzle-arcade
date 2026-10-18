const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('studioDesktop', {
  catalog: () => ipcRenderer.invoke('catalog'),
  report: (environment, days) => ipcRenderer.invoke('report', environment, days),
  login: (username, password) => ipcRenderer.invoke('login', username, password),
  logout: () => ipcRenderer.invoke('logout'),
});
