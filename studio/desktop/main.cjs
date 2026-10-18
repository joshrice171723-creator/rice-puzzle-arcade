const { app, BrowserWindow, ipcMain, safeStorage } = require('electron');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const ORIGIN = 'https://aimetaclinic.com';
let credentials, window;
app.setName('Game Studio');
app.setAppUserModelId('com.joshuarice.gamestudio');
const ui = path.join(__dirname, 'ui', 'index.html');
const entry = pathToFileURL(ui).href;
const vault = () => path.join(app.getPath('userData'), 'login.bin');
function trusted(event) {
  if (event.senderFrame !== window.webContents.mainFrame || event.senderFrame.url.split('#')[0] !== entry) throw Error('Untrusted sender');
}
async function report(environment, days, auth = credentials) {
  if (!['test', 'production'].includes(environment) || ![1,7,30,90].includes(Number(days))) throw Error('Invalid report selection');
  if (!auth) throw Error('SIGN_IN');
  const response = await fetch(`${ORIGIN}/games/api/report?environment=${environment}&days=${Number(days)}`, {
    headers: { Authorization: `Basic ${Buffer.from(`${auth.username}:${auth.password}`).toString('base64')}` },
    redirect: 'error', signal: AbortSignal.timeout(15000),
  });
  if (response.status === 401) throw Error('SIGN_IN');
  if (!response.ok) throw Error('Report service unavailable');
  return response.json();
}
if (!app.requestSingleInstanceLock()) app.quit();
else {
  app.on('second-instance', () => { if (window) { if (window.isMinimized()) window.restore(); window.focus(); } });
  app.whenReady().then(async () => {
    try { credentials = JSON.parse(safeStorage.decryptString(fs.readFileSync(vault()))); } catch {}
    // One-time owner migration; the password never enters the renderer or package.
    const imported = process.argv.find(arg => arg.startsWith('--import-login='));
    if (imported) {
      const text = fs.readFileSync(imported.slice('--import-login='.length), 'utf8');
      const username = text.match(/^Username:\s*(.+)$/mi)?.[1].trim();
      const password = text.match(/^Password:\s*(.+)$/mi)?.[1].trim();
      if (username && password) {
        const candidate = { username, password };
        await report('test', 1, candidate);
        if (!safeStorage.isEncryptionAvailable()) throw Error('Windows credential encryption unavailable');
        fs.mkdirSync(app.getPath('userData'), { recursive: true });
        fs.writeFileSync(vault(), safeStorage.encryptString(JSON.stringify(candidate)));
        credentials = candidate;
      }
    }
    ipcMain.handle('catalog', event => { trusted(event); return JSON.parse(fs.readFileSync(path.join(__dirname,'ui','catalog.json'),'utf8')); });
    ipcMain.handle('report', async (event, environment, days) => { trusted(event); return report(environment, days); });
    ipcMain.handle('login', async (event, username, password) => {
      trusted(event);
      if (typeof username !== 'string' || typeof password !== 'string' || !username || username.includes(':') || username.length > 200 || password.length > 500) throw Error('Enter your studio login');
      const candidate = { username, password };
      await report('test', 1, candidate);
      if (!safeStorage.isEncryptionAvailable()) throw Error('Windows credential encryption unavailable');
      fs.writeFileSync(vault(), safeStorage.encryptString(JSON.stringify(candidate)));
      credentials = candidate;
    });
    ipcMain.handle('logout', event => { trusted(event); credentials = undefined; fs.rmSync(vault(), { force: true }); });
    window = new BrowserWindow({ width:1440, height:940, minWidth:760, minHeight:600, title:'Game Studio', icon:path.join(__dirname,'ui','icon.png'), backgroundColor:'#101918', autoHideMenuBar:true,
      webPreferences:{ preload:path.join(__dirname,'preload.cjs'), contextIsolation:true, sandbox:true, nodeIntegration:false, webSecurity:true } });
    window.webContents.setWindowOpenHandler(() => ({ action:'deny' }));
    window.webContents.on('will-navigate', (event, url) => { if (url.split('#')[0] !== entry) event.preventDefault(); });
    window.webContents.session.setPermissionRequestHandler((_contents, _permission, callback) => callback(false));
    await window.loadFile(ui);
  }).catch(() => { require('electron').dialog.showErrorBox('Game Studio', 'Could not open the studio. Try launching without the login import option.'); app.quit(); });
  app.on('window-all-closed', () => app.quit());
}
