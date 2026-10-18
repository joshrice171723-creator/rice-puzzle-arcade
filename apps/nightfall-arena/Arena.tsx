'use dom';

import React, { useEffect, useRef, useState } from 'react';
import type { DOMProps } from 'expo/dom';
import { chooseUpgrade, createGame, defend, DURATION, HEIGHT, restoreGame, State, STEP, tick, UPGRADES, WIDTH, wave } from './game';
import { draw, makeFloor } from './render';
import { createRunObserver } from './telemetry';
import type { Fields } from '../../packages/analytics/client';

type Props = { emit: (name: string, fields: Fields) => Promise<void>; getTracking: () => Promise<boolean>; setTracking: (enabled: boolean) => Promise<void>; foreground: boolean; load: () => Promise<string | null>; save: (value: string) => Promise<void>; dom?: DOMProps };
type Menu = 'home' | 'play' | 'pause' | 'help' | 'privacy';
type RecordBook = { best: number; survived: number; tutorial: boolean; buttons: boolean };
const timeLabel = (seconds: number) => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;
const css = `
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}html,body,#root{margin:0;width:100%;height:100%;overflow:hidden;background:#101b20;color:#e9e5d5;font-family:system-ui,-apple-system,sans-serif;overscroll-behavior:none}button{font:inherit;cursor:pointer;touch-action:manipulation}button:focus-visible{outline:3px solid #9ce4d0;outline-offset:3px}button:disabled{opacity:.45;cursor:default}.shell{height:100vh;height:100dvh;max-height:100%;width:100%;max-width:540px;margin:auto;display:flex;flex-direction:column;padding:10px 14px 8px;gap:8px;user-select:none;background:radial-gradient(ellipse at 50% 0,#253a3c,#101b20 75%)}.top{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-shrink:0}.eyebrow{font-size:10px;letter-spacing:2px;font-weight:800;color:#b1b6a6}.brand{font-size:19px;line-height:1.1;letter-spacing:-.5px;font-weight:900}.icon{border:1px solid #62726a;background:#24373b;color:#e9e5d5;border-radius:12px;min-width:44px;height:44px;font-size:17px}.stats{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;flex-shrink:0}.stat{text-align:center}.label{display:block;font-size:9px;font-weight:800;letter-spacing:1.4px;color:#a6b8ad}.value{font-size:21px;line-height:1.2;font-weight:850;font-variant-numeric:tabular-nums}.stat.best .value{color:#edc476}.health-row{display:flex;align-items:center;gap:8px;flex-shrink:0}.health{height:5px;flex:1;background:#364447;border-radius:4px;overflow:hidden}.health>i{display:block;height:100%;background:#8bd0ac}.health-row span{font-size:10px;color:#b1c4b8;min-width:43px;text-align:right;font-variant-numeric:tabular-nums}.field{flex:1;min-height:0;display:flex;align-items:center;justify-content:center;position:relative}.field canvas{display:block;max-width:100%;max-height:100%;width:auto;height:100%;aspect-ratio:400/560;border-radius:8px;box-shadow:0 12px 30px #0005;touch-action:none}.controls{height:111px;display:flex;align-items:center;justify-content:space-around;gap:14px;flex-shrink:0}.stick{width:108px;height:108px;position:relative;border:1px solid #657c704d;background:radial-gradient(circle,#314e4d99,#1a303166);border-radius:50%;touch-action:none;display:grid;place-items:center}.stick:before,.stick:after{content:'';position:absolute;background:#82968b22}.stick:before{height:1px;width:80px}.stick:after{width:1px;height:80px}.knob{width:46px;height:46px;border:1px solid #a3bca0;border-radius:50%;background:radial-gradient(circle at 35% 25%,#657d6c,#344b46);box-shadow:0 4px 12px #0006;z-index:1;pointer-events:none}.defense{width:144px;height:67px;border:1px solid #d5b66f88;border-radius:14px;color:#f7dfac;background:linear-gradient(140deg,#4c4530,#283b3c);font-weight:850;font-size:14px}.defense small{display:block;font-size:10px;font-weight:600;color:#c8c5a9;margin-top:5px}.hint{text-align:center;font-size:10px;color:#98ada0;margin:0;flex-shrink:0}.curtain{position:absolute;top:0;right:0;bottom:0;left:0;inset:0;background:#071014b8;backdrop-filter:blur(5px);display:flex;align-items:center;justify-content:center;padding:16px;z-index:5}.panel{width:100%;max-width:390px;max-height:100%;overflow:auto;background:linear-gradient(160deg,#2a3d3f,#14262c);border:1px solid #71857666;box-shadow:0 24px 90px #000b;padding:25px;border-radius:23px}.panel h1{font-size:43px;line-height:.97;letter-spacing:-2px;margin:14px 0 18px;font-weight:950}.panel h2{font-size:27px;line-height:1.06;letter-spacing:-1px;margin:12px 0}.panel p{font-size:13px;line-height:1.55;color:#bac8bd}.panel .sub{color:#e6c684}.primary,.secondary{width:100%;min-height:47px;border-radius:12px;font-weight:800;font-size:14px;margin-top:9px;padding:10px 14px}.primary{background:#e9bd6c;border:1px solid #f4d595;color:#24302c;box-shadow:0 3px 0 #9b7843}.secondary{background:#22383b;border:1px solid #698172;color:#d6e2d4}.high-score{padding:15px 0;text-align:center;border-top:1px solid #78908030;border-bottom:1px solid #78908030}.high-score strong{display:block;font-size:36px;color:#f2cb7d;line-height:1.2}.choice{display:flex;align-items:center;gap:12px;text-align:left}.choice i{font-style:normal;display:grid;place-items:center;background:#dfc27b20;color:#f2cb7d;border:1px solid #dfc27b50;border-radius:10px;width:40px;height:40px;flex-shrink:0;font-size:22px}.choice b{font-size:14px;display:block}.choice small{font-size:11px;color:#becbbd;display:block;font-weight:500;margin-top:4px}.chips{display:flex;justify-content:space-between;gap:6px;color:#bfc9b7;font-size:10px;letter-spacing:.5px;margin:18px 0}.notice{font-size:11px;color:#ffd69c;padding:6px 10px;background:#352f26;flex-shrink:0}.dpad{height:108px;width:138px;position:relative;touch-action:none}.dpad button{position:absolute;width:44px;height:44px;border:1px solid #779184;background:#2c4846;color:#e3e8d6;border-radius:10px;touch-action:none}.dpad .up{left:47px;top:0}.dpad .left{left:0;top:48px}.dpad .down{left:47px;top:48px}.dpad .right{left:94px;top:48px}.performance{position:absolute;bottom:5px;left:8px;background:#081519db;font:10px monospace;color:#caf2cf;padding:5px;pointer-events:none}.build-label{font-size:9px;letter-spacing:2px;text-align:center;color:#7f968b;margin-top:18px}.panel .toggle{display:flex;align-items:center;justify-content:space-between;text-align:left}.small-note{font-size:11px!important;margin:8px 0!important}.hero-mark{font-size:28px;line-height:1;color:#edc476}.loading{height:100vh;height:100dvh;display:grid;place-content:center;color:#e9bd6c;font:700 16px system-ui}@media(max-height:650px){.shell{padding:6px 10px;gap:5px}.controls{height:86px}.stick{width:82px;height:82px}.knob{width:39px;height:39px}.stick:before{width:62px}.stick:after{height:62px}.brand{font-size:16px}.icon{height:40px;min-width:44px}.value{font-size:18px}.panel{padding:18px}.panel h1{font-size:34px;margin:9px 0 12px}.panel h2{font-size:24px}.panel p{font-size:12px;margin:8px 0}.chips{margin:12px 0}.high-score{padding:9px 0}.high-score strong{font-size:29px}.build-label{margin-top:12px}.dpad{height:86px;width:132px}.dpad button{height:40px}.dpad .up{left:44px}.dpad .down{left:44px;top:43px}.dpad .left{top:43px}.dpad .right{left:88px;top:43px}}
`;

export default function Arena(props: Props) {
  const bridge = useRef(props); bridge.current = props;
  const runId = useRef('');
  const [tracking, setTracking] = useState(false);
  const [observer] = useState(() => createRunObserver((name, fields) => { void bridge.current.emit(name, fields); }));
  const game = useRef<State>(createGame(1)), record = useRef<RecordBook>({ best: 0, survived: 0, tutorial: false, buttons: false });
  const canvas = useRef<HTMLCanvasElement>(null), knob = useRef<HTMLDivElement>(null), input = useRef({ x: 0, y: 0 });
  const keys = useRef(new Set<string>()), menuRef = useRef<Menu>('home'), pointer = useRef<number | null>(null);
  const [menu, setMenu] = useState<Menu>('home'), [ready, setReady] = useState(false), [notice, setNotice] = useState('');
  const [hud, setHud] = useState({ score: 0, hp: 100, maxHp: 100, time: 0, wave: 1, scrap: 0, used: false, phase: 'playing' as State['phase'], choices: [] as State['choices'] });
  const [stats, setStats] = useState({ fps: 0, p95: 0, enemies: 0, step: 0 }), [diagnostics, setDiagnostics] = useState(false);
  const [buttons, setButtons] = useState(false), [best, setBest] = useState(0), [resumable, setResumable] = useState(false);
  const resetInput = () => { input.current = { x: 0, y: 0 }; keys.current.clear(); pointer.current = null; if (knob.current) knob.current.style.transform = ''; };
  function changeMenu(value: Menu) { resetInput(); menuRef.current = value; setMenu(value); }
  function refresh() {
    const s = game.current;
    observer.observe(s);
    setHud({ score: s.score, hp: s.player.hp, maxHp: s.player.maxHp, time: s.time, wave: wave(s), scrap: s.scrap, used: s.pulseUsed, phase: s.phase, choices: [...s.choices] });
  }
  function persist() {
    const s = game.current;
    record.current.best = Math.max(record.current.best, s.score);
    record.current.survived = Math.max(record.current.survived, s.time);
    setBest(record.current.best);
    const current = s.time > 0 && (s.phase === 'playing' || s.phase === 'upgrade') ? s : null;
    setResumable(!!current);
    void bridge.current.save(JSON.stringify({ version: 1, record: record.current, current, runId: runId.current })).catch(() => setNotice('Could not save this run. Keep the app open and try again.'));
  }
  useEffect(() => {
    let cancelled = false;
    void bridge.current.getTracking().then(value => { if (!cancelled) setTracking(value); });
    bridge.current.load().then(raw => {
      if (cancelled || !raw) return;
      try {
        const data = JSON.parse(raw);
        if (data.version !== 1 || !data.record || !Number.isFinite(data.record.best) || data.record.best < 0 || !Number.isFinite(data.record.survived) || data.record.survived < 0) throw new Error('save');
        record.current = { best: data.record.best, survived: Math.min(DURATION, data.record.survived), tutorial: data.record.tutorial === true, buttons: data.record.buttons === true };
        setBest(record.current.best); setButtons(record.current.buttons);
        if (data.current) { const restored = restoreGame(data.current); if (!restored) throw new Error('run'); game.current = restored; runId.current = typeof data.runId === 'string' && /^[A-Za-z0-9_-]{8,100}$/.test(data.runId) ? data.runId : `restored-${Date.now()}`; setResumable(restored.phase === 'playing' || restored.phase === 'upgrade'); }
      } catch { setNotice('The unfinished run could not be restored. You can start a new one.'); }
    }).catch(() => { if (!cancelled) setNotice('Saved progress is unavailable. You can still play.'); }).finally(() => { if (!cancelled) { refresh(); setReady(true); } });
    return () => { cancelled = true; };
  }, []);
  useEffect(() => {
    if (!props.foreground && ready) { if (menuRef.current === 'play') changeMenu('pause'); persist(); }
  }, [props.foreground, ready]);
  useEffect(() => {
    if (!ready || !canvas.current) return;
    const c = canvas.current.getContext('2d')!, floor = makeFloor();
    const ratio = Math.min(window.devicePixelRatio || 1, 2); canvas.current.width = WIDTH * ratio; canvas.current.height = HEIGHT * ratio; c.scale(ratio, ratio);
    const surface = canvas.current, field = surface.parentElement!;
    const fit = () => { const size = Math.min(field.clientWidth / WIDTH, field.clientHeight / HEIGHT); surface.style.width = `${WIDTH * size}px`; surface.style.height = `${HEIGHT * size}px`; draw(c, game.current, floor); };
    const resize = new ResizeObserver(fit); resize.observe(field); fit();
    let frame = 0, last = 0, accumulator = 0, hudAt = 0, saveAt = 0, active = true, simCost = 0, drawnTime = -1;
    let drawnState: State | null = null;
    const times: number[] = [];
    let activeSeconds = 0;
    const pause = () => { if (menuRef.current === 'play') { changeMenu('pause'); persist(); } resetInput(); accumulator = 0; last = 0; };
    const visibility = () => { if (document.hidden) pause(); };
    const keydown = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', 'w', 'a', 's', 'd', ' '].includes(key)) { e.preventDefault(); if (menuRef.current === 'play') keys.current.add(key); }
      if ((key === 'escape' || key === 'p') && menuRef.current === 'play') pause();
      if (key === ' ' && menuRef.current === 'play' && defend(game.current)) { refresh(); persist(); }
    };
    const keyup = (e: KeyboardEvent) => keys.current.delete(e.key.toLowerCase());
    function loop(now: number) {
      if (!active) return;
      const elapsed = last ? now - last : 0; last = now;
      const s = game.current;
      if (menuRef.current === 'play' && bridge.current.foreground && !document.hidden && s.phase === 'playing') {
        if (elapsed > 0) { times.push(elapsed); if (times.length > 600) times.shift(); }
        activeSeconds += Math.min(elapsed / 1000, 1);
        if (activeSeconds >= 15) { void bridge.current.emit('session_active', { seconds: 15 }); activeSeconds -= 15; }
        accumulator += Math.min(elapsed / 1000, .1);
        const start = performance.now();
        const k = keys.current, direction = k.size ? { x: Number(k.has('d') || k.has('arrowright')) - Number(k.has('a') || k.has('arrowleft')), y: Number(k.has('s') || k.has('arrowdown')) - Number(k.has('w') || k.has('arrowup')) } : input.current;
        let steps = 0;
        while (accumulator >= STEP && steps++ < 6) { tick(s, direction); accumulator -= STEP; if (s.phase !== 'playing') { resetInput(); refresh(); persist(); accumulator = 0; break; } }
        simCost = Math.max(simCost, performance.now() - start);
      } else accumulator = 0;
      if (drawnState !== s || drawnTime !== s.time) { draw(c, s, floor); drawnState = s; drawnTime = s.time; }
      if (now - hudAt > 250 && menuRef.current === 'play' && s.phase === 'playing') {
        refresh(); hudAt = now;
        const sorted = [...times].sort((a, b) => a - b), mean = times.reduce((sum, t) => sum + t, 0) / (times.length || 1);
        setStats({ fps: mean ? Math.round(1000 / mean) : 0, p95: Math.round(sorted[Math.floor(sorted.length * .95)] || 0), enemies: s.enemies.filter(e => e.active).length, step: Math.round(simCost * 100) / 100 }); simCost = 0;
      }
      if (now - saveAt > 5000) { if (menuRef.current === 'play') persist(); saveAt = now; }
      frame = requestAnimationFrame(loop);
    }
    frame = requestAnimationFrame(loop);
    window.addEventListener('blur', pause); document.addEventListener('visibilitychange', visibility); window.addEventListener('keydown', keydown); window.addEventListener('keyup', keyup);
    return () => { active = false; cancelAnimationFrame(frame); resize.disconnect(); window.removeEventListener('blur', pause); document.removeEventListener('visibilitychange', visibility); window.removeEventListener('keydown', keydown); window.removeEventListener('keyup', keyup); };
  }, [ready]);
  function start() { observer.exit(game.current); game.current = createGame(Date.now() >>> 0); runId.current = `run-${Date.now()}-${Math.random().toString(36).slice(2)}`; observer.begin(runId.current, game.current); refresh(); changeMenu(record.current.tutorial ? 'play' : 'help'); setResumable(false); }
  function stick(e: React.PointerEvent<HTMLDivElement>) {
    if (pointer.current !== e.pointerId) return;
    const box = e.currentTarget.getBoundingClientRect(), dx = e.clientX - box.left - box.width / 2, dy = e.clientY - box.top - box.height / 2, length = Math.hypot(dx, dy), reach = box.width * .29;
    const scale = length > reach ? reach / length : 1; input.current = { x: dx * scale / reach, y: dy * scale / reach };
    if (knob.current) knob.current.style.transform = `translate(${dx * scale}px,${dy * scale}px)`;
  }
  const ended = hud.phase === 'lost' || hud.phase === 'won';
  if (!ready) return <><style>{css}</style><div className="loading">Opening the courtyard…</div></>;
  return <><style>{css}</style><main className="shell">
    <header className="top"><div><div className="eyebrow">NIGHTFALL</div><div className="brand">The courtyard</div></div><button className="icon" aria-label="Pause game" onClick={() => { changeMenu('pause'); persist(); }}>Ⅱ</button></header>
    <section className="stats" aria-label="Run statistics"><div className="stat"><span className="label">SCORE</span><span className="value">{hud.score.toLocaleString()}</span></div><div className="stat best"><span className="label">BEST TO BEAT</span><span className="value">{Math.max(best, hud.score).toLocaleString()}</span></div><div className="stat"><span className="label">HOLD OUT</span><span className="value">{timeLabel(Math.max(0, DURATION - hud.time))}</span></div></section>
    <div className="health-row"><div className="health" role="progressbar" aria-label="Health" aria-valuenow={Math.ceil(hud.hp)} aria-valuemax={hud.maxHp} aria-valuemin={0}><i style={{ width: `${hud.hp / hud.maxHp * 100}%`, background: hud.hp < hud.maxHp * .3 ? '#df8669' : undefined }} /></div><span>{Math.ceil(hud.hp)} / {hud.maxHp}</span></div>
    <div className="field"><canvas ref={canvas} aria-label="Nightfall arena. Move with the joystick or arrow keys; your weapon fires automatically." />{diagnostics && <output className="performance">{stats.fps} fps · p95 {stats.p95} ms · {stats.enemies} enemies · step {stats.step} ms</output>}</div>
    <p className="hint">WAVE {hud.wave} / 5 · {hud.time < 12 ? 'Keep moving. Your weapon fires automatically.' : 'Green shelter restores health. Collect gold scrap.'}</p>
    <div className="controls">{buttons ? <div className="dpad" aria-label="Movement controls">{([['up', '↑', 0, -1], ['left', '←', -1, 0], ['down', '↓', 0, 1], ['right', '→', 1, 0]] as const).map(([name, label, x, y]) => <button key={name} className={name} aria-label={`Move ${name}`} onPointerDown={e => { e.currentTarget.setPointerCapture(e.pointerId); input.current = { x, y }; }} onPointerUp={resetInput} onPointerCancel={resetInput} onLostPointerCapture={resetInput}>{label}</button>)}</div> : <div className="stick" role="group" aria-label="Movement joystick" onPointerDown={e => { if (pointer.current !== null) return; pointer.current = e.pointerId; e.currentTarget.setPointerCapture(e.pointerId); stick(e); }} onPointerMove={stick} onPointerUp={resetInput} onPointerCancel={resetInput} onLostPointerCapture={resetInput}><div className="knob" ref={knob} /></div>}
      <button className="defense" disabled={hud.used || hud.scrap < 8 || menu !== 'play' || hud.phase !== 'playing'} onClick={() => { if (defend(game.current)) { refresh(); persist(); } }}>◈ {hud.used ? 'Pulse deployed' : 'Defense pulse'}<small>{hud.used ? 'Used this run' : `${hud.scrap} / 8 scrap · one use`}</small></button></div>
    {notice && <div className="notice" role="status">{notice}</div>}
    {menu !== 'play' || ended || hud.phase === 'upgrade' ? <div className="curtain"><section className="panel" role="dialog" aria-modal="true" aria-label={menu === 'privacy' ? 'Privacy' : menu === 'home' ? 'Nightfall Arena' : menu === 'help' ? 'How to play' : menu === 'pause' ? 'Paused' : ended ? 'Run complete' : 'Choose an upgrade'}>
      {menu === 'privacy' ? <><h2>Privacy</h2><label className="small-note"><input type="checkbox" checked={tracking} onChange={e => { const enabled = e.target.checked; setTracking(enabled); void bridge.current.setTracking(enabled); }} /> Share gameplay analytics</label><p className="small-note">Optional anonymous activity and results help improve the game. No name or email. Events expire after 90 days.</p><button className="primary" onClick={() => changeMenu('home')}>Back</button></> : menu === 'home' ? <><div className="hero-mark">✦</div><div className="eyebrow" style={{ marginTop: 13 }}>FIVE MINUTES UNTIL DAWN</div><h1>NIGHTFALL<br /><span style={{ color: '#edc476' }}>ARENA</span></h1><p>The courtyard is closing in.<br />Keep moving. Build your way out.</p><div className="high-score"><span className="label">YOUR BEST TO BEAT</span><strong>{best.toLocaleString()}</strong></div><div className="chips"><span>5 WAVES</span><span>3 UPGRADES</span><span>ONE WAY OUT</span></div>{resumable && <button className="primary" onClick={() => { observer.begin(runId.current, game.current, true); changeMenu('play'); }}>Continue · {timeLabel(hud.time)}</button>}<button className={resumable ? 'secondary' : 'primary'} onClick={start}>{resumable ? 'Start a new run' : 'Enter the courtyard'}</button><button className="secondary" onClick={() => changeMenu('privacy')}>Privacy</button><div className="build-label">PLAYABLE PROTOTYPE · NO ADS</div></> :
      menu === 'help' ? <><div className="eyebrow">YOUR FIRST NIGHT</div><h2>Move to survive.</h2><p>Drag the thumb stick to move. Your weapon aims and fires for you. On a keyboard, use WASD or the arrow keys.</p><p><b className="sub">Follow the green shelter.</b> Stand inside to recover health. It moves with each wave.</p><p><b className="sub">Collect gold scrap.</b> Eight pieces power one defense pulse that clears nearby enemies and shields you for three seconds.</p><p>Survive five minutes. Pick an upgrade when supplies arrive.</p><button className="primary" onClick={() => { record.current.tutorial = true; changeMenu('play'); persist(); }}>Let’s go</button></> :
      menu === 'pause' ? <><div className="eyebrow">TAKE A BREATHER</div><h2>Paused.</h2><p>Your run is saved. The courtyard can wait.</p><button className="primary" onClick={() => changeMenu('play')}>Resume</button><button className="secondary toggle" onClick={() => { const value = !buttons; setButtons(value); record.current.buttons = value; persist(); }}>Movement controls <span>{buttons ? 'Buttons' : 'Joystick'}</span></button><button className="secondary toggle" onClick={() => setDiagnostics(!diagnostics)}>Performance display <span>{diagnostics ? 'On' : 'Off'}</span></button><button className="secondary" onClick={() => { observer.exit(game.current); persist(); changeMenu('home'); }}>Save & exit</button></> :
      ended ? <><div className="eyebrow">{hud.phase === 'won' ? 'EXTRACTION COMPLETE' : 'THE NIGHT GOT YOU'}</div><h2>{hud.phase === 'won' ? 'You made it to dawn.' : 'One more night?'}</h2><p>{timeLabel(hud.time)} survived · {game.current.kills} enemies stopped</p><div className="high-score"><span className="label">RUN SCORE</span><strong>{hud.score.toLocaleString()}</strong><span className="label">BEST {Math.max(best, hud.score).toLocaleString()}</span></div><p className="small-note">{hud.phase === 'lost' ? 'Keep room to move. Use cover to separate the faster enemies.' : 'Try a different upgrade combination on your next run.'}</p><button className="primary" onClick={start}>New run</button><button className="secondary" onClick={() => changeMenu('home')}>Back to courtyard</button></> :
      <><div className="eyebrow">SUPPLY DROP {game.current.upgradeCount + 1} / 3</div><h2>Make your next move.</h2><p>Choose one upgrade for the rest of this run. The fight is paused.</p>{hud.choices.map(id => { const u = UPGRADES.find(item => item.id === id)!; return <button className="secondary choice" key={id} onClick={() => { if (chooseUpgrade(game.current, id)) { observer.upgrade(game.current, id); resetInput(); refresh(); persist(); } }}><i>{u.icon}</i><span><b>{u.name}</b><small>{u.detail}</small></span></button>; })}</>}
    </section></div> : null}
  </main></>;
}
