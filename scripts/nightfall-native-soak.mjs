// Android developer QA only. Reads the embedded app's DOM over ADB's local
// debugging bridge and sends real Android input. Never changes game state.
import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const directory = 'artifacts/nightfall'; mkdirSync(directory, { recursive: true });
const adbPath = join(process.env.LOCALAPPDATA, 'Android/Sdk/platform-tools/adb.exe');
const adb = (...args) => execFileSync(adbPath, ['-s', 'emulator-5554', ...args], { timeout: 20000 });
const pid = adb('shell', 'pidof', 'com.joshuarice.nightfallarena').toString().trim();
if (!/^\d+$/.test(pid)) throw new Error('Start Nightfall in the Android emulator first');
adb('forward', 'tcp:9223', `localabstract:webview_devtools_remote_${pid}`);
const tabs = await (await fetch('http://127.0.0.1:9223/json')).json();
const target = tabs.find(t => t.url.startsWith('file:///android_asset/www.bundle/'));
if (!target) throw new Error('Offline Nightfall WebView not found');
const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
let id = 0; const pending = new Map(), errors = [];
socket.onmessage = e => {
  const m = JSON.parse(e.data);
  if (m.id) { pending.get(m.id)?.(m); pending.delete(m.id); }
  else if (m.method === 'Runtime.exceptionThrown') errors.push(m.params);
};
const call = (method, params = {}) => new Promise((resolve, reject) => {
  const key = ++id, timer = setTimeout(() => { pending.delete(key); reject(new Error(`Timed out: ${method}`)); }, 10000);
  pending.set(key, result => { clearTimeout(timer); resolve(result); }); socket.send(JSON.stringify({ id: key, method, params }));
});
await call('Runtime.enable');
adb('shell', 'uiautomator', 'dump', '/sdcard/nightfall-soak.xml');
const xml = adb('shell', 'cat', '/sdcard/nightfall-soak.xml').toString();
const webviewNode = xml.match(/<node[^>]*class="android\.webkit\.WebView"[^>]*>/)?.[0];
const bounds = webviewNode?.match(/bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/);
if (!bounds) throw new Error('Cannot locate native WebView bounds');
const [, left, top, right] = bounds.map(Number);
const expression = `JSON.stringify((()=>{const panel=document.querySelector('[role="dialog"]'); const box=e=>{const b=e.getBoundingClientRect();return {x:b.x,y:b.y,w:b.width,h:b.height}};return {width:innerWidth,height:innerHeight,scroll:document.documentElement.scrollHeight,dialog:panel?.getAttribute('aria-label')||null,buttons:[...(panel||document).querySelectorAll('button')].map(e=>({label:e.getAttribute('aria-label')||e.textContent,disabled:e.disabled,...box(e)})),stick:document.querySelector('.stick')?box(document.querySelector('.stick')):null,stats:document.querySelector('.stats')?.innerText,health:document.querySelector('.health-row')?.innerText,performance:document.querySelector('.performance')?.textContent}})())`;
const observe = async () => { const result = await call('Runtime.evaluate', { expression, returnByValue: true }); if (result.result?.exceptionDetails) throw new Error(JSON.stringify(result)); return JSON.parse(result.result.result.value); };
const tap = (button, view) => { if (!button || button.disabled) throw new Error('Invalid Android input target'); const scale = (right - left) / view.width; adb('shell', 'input', 'tap', String(Math.round(left + (button.x + button.w / 2) * scale)), String(Math.round(top + (button.y + button.h / 2) * scale))); };
const started = Date.now(), duration = Number(process.argv[2] || 900) * 1000, samples = []; let cycles = 0, restarts = 0, upgrades = 0, minute = -1, perfEnabled = false;
try {
  while (Date.now() - started < duration) {
    const view = await observe(); samples.push({ seconds: Math.round((Date.now() - started) / 1000), ...view });
    const find = text => view.buttons.find(b => b.label === text);
    if (view.dialog === 'Nightfall Arena') tap(view.buttons.find(b => b.label.startsWith('Continue')) || find('Enter the courtyard'), view);
    else if (view.dialog === 'How to play') tap(find('Let’s go'), view);
    else if (view.dialog === 'Paused') {
      if (!perfEnabled && find('Performance display Off')) { tap(find('Performance display Off'), view); perfEnabled = true; }
      else tap(find('Resume'), view);
    } else if (view.dialog === 'Choose an upgrade') {
      const choice = view.buttons.find(b => /Hot rounds|Quick chamber|Field medic/.test(b.label)) || view.buttons[0]; tap(choice, view); upgrades++;
    } else if (view.dialog === 'Run complete') { tap(find('New run'), view); restarts++; }
    else if (!perfEnabled) tap(find('Pause game'), view);
    else if (view.stick) {
      const scale = (right - left) / view.width, s = view.stick, x = left + (s.x + s.w / 2) * scale, y = top + (s.y + s.h / 2) * scale;
      const angle = Math.floor(cycles / 3) % 4 * Math.PI / 2;
      adb('shell', 'input', 'swipe', String(Math.round(x)), String(Math.round(y)), String(Math.round(x + Math.cos(angle) * s.w * .27 * scale)), String(Math.round(y + Math.sin(angle) * s.h * .27 * scale)), '800');
    }
    const currentMinute = Math.floor((Date.now() - started) / 60000);
    if (currentMinute !== minute) {
      minute = currentMinute;
      writeFileSync(`${directory}/native-soak-${minute}.png`, adb('exec-out', 'screencap', '-p'));
      writeFileSync(`${directory}/native-memory-${minute}.txt`, adb('shell', 'dumpsys', 'meminfo', 'com.joshuarice.nightfallarena'));
      writeFileSync(`${directory}/native-soak-progress.json`, JSON.stringify({ started: new Date(started).toISOString(), seconds: Math.round((Date.now() - started) / 1000), cycles, restarts, upgrades, errors, samples }, null, 2));
      console.log(JSON.stringify({ minute, restarts, upgrades, timing: view.performance, errors: errors.length }));
    }
    cycles++; await new Promise(resolve => setTimeout(resolve, 4000));
  }
  const view = await observe(); if (!view.dialog) tap(view.buttons.find(b => b.label === 'Pause game'), view);
  const result = { apk: 'nightfall-arena-internal-test.apk', started: new Date(started).toISOString(), durationSeconds: Math.round((Date.now() - started) / 1000), cycles, restarts, upgrades, errors, samples };
  writeFileSync(`${directory}/native-soak.json`, JSON.stringify(result, null, 2));
  console.log(JSON.stringify({ durationSeconds: result.durationSeconds, cycles, restarts, upgrades, errors: errors.length }));
} finally { socket.close(); adb('forward', '--remove', 'tcp:9223'); }
