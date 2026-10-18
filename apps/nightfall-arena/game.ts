export const WIDTH = 400, HEIGHT = 560, STEP = 1 / 60, DURATION = 300, ENEMY_CAP = 120;
export type Vec = { x: number; y: number };
export type Rect = Vec & { w: number; h: number };
export const WALLS: Rect[] = [{ x: 65, y: 150, w: 82, h: 28 }, { x: 253, y: 150, w: 82, h: 28 }, { x: 153, y: 344, w: 94, h: 30 }];
export const ZONES: Vec[] = [{ x: 85, y: 430 }, { x: 315, y: 255 }, { x: 85, y: 75 }, { x: 310, y: 465 }, { x: 195, y: 230 }];
export const UPGRADES = [
  { id: 'damage', name: 'Hot rounds', detail: '+35% shot damage', icon: '↗' },
  { id: 'rate', name: 'Quick chamber', detail: 'Fire 20% faster', icon: '»' },
  { id: 'speed', name: 'Light boots', detail: '+15% movement speed', icon: '⌁' },
  { id: 'health', name: 'Field medic', detail: '+25 max health and heal 40', icon: '+' },
  { id: 'pierce', name: 'Throughshot', detail: 'Shots pass through another enemy', icon: '➜' },
  { id: 'magnet', name: 'Scrap magnet', detail: '+45 pickup reach', icon: '◎' },
  { id: 'armor', name: 'Reinforced coat', detail: 'Take 25% less damage', icon: '◇' },
  { id: 'recovery', name: 'Shelter kit', detail: 'Double safe-zone healing', icon: '✚' },
] as const;
export type Upgrade = typeof UPGRADES[number]['id'];
export type Enemy = Vec & { active: boolean; kind: 'walker' | 'runner'; hp: number; maxHp: number; id: number; flash: number };
export type Shot = Vec & { active: boolean; vx: number; vy: number; life: number; damage: number; pierce: number; hits: number[] };
export type Pickup = Vec & { active: boolean };
export type State = {
  version: 1; seed: number; time: number; phase: 'playing' | 'upgrade' | 'lost' | 'won';
  player: Vec & { hp: number; maxHp: number; invincible: number; angle: number };
  enemies: Enemy[]; shots: Shot[]; pickups: Pickup[]; kills: number; scrap: number; score: number;
  spawnIn: number; fireIn: number; nextId: number; upgradeCount: number; choices: Upgrade[]; upgrades: Upgrade[];
  damage: number; rate: number; speed: number; armor: number; magnet: number; pierce: number; recovery: number;
  pulseUsed: boolean; pulse: number;
};
export function createGame(seed = 1): State {
  return { version: 1, seed: seed >>> 0 || 1, time: 0, phase: 'playing', player: { x: 200, y: 270, hp: 100, maxHp: 100, invincible: 0, angle: -Math.PI / 2 }, enemies: [], shots: [], pickups: [], kills: 0, scrap: 0, score: 0, spawnIn: 1, fireIn: 0, nextId: 1, upgradeCount: 0, choices: [], upgrades: [], damage: 28, rate: .35, speed: 112, armor: 1, magnet: 23, pierce: 0, recovery: .8, pulseUsed: false, pulse: 0 };
}
export function random(s: State) { s.seed = (Math.imul(s.seed, 1664525) + 1013904223) >>> 0; return s.seed / 4294967296; }
export const wave = (s: State) => Math.min(5, 1 + Math.floor(s.time / 60));
export function circleRect(p: Vec, r: number, box: Rect) {
  return Math.hypot(p.x - Math.max(box.x, Math.min(p.x, box.x + box.w)), p.y - Math.max(box.y, Math.min(p.y, box.y + box.h))) < r;
}
export function move(p: Vec, dx: number, dy: number, radius: number) {
  const x = Math.max(16 + radius, Math.min(WIDTH - 16 - radius, p.x + dx));
  if (!WALLS.some(b => circleRect({ x, y: p.y }, radius, b))) p.x = x;
  const y = Math.max(16 + radius, Math.min(HEIGHT - 16 - radius, p.y + dy));
  if (!WALLS.some(b => circleRect({ x: p.x, y }, radius, b))) p.y = y;
}
function pooled<T extends { active: boolean }>(items: T[], value: T, cap: number) {
  const index = items.findIndex(item => !item.active);
  if (index >= 0) items[index] = value;
  else if (items.length < cap) items.push(value);
}
export function spawn(s: State, kind: Enemy['kind'] = random(s) < .27 ? 'runner' : 'walker') {
  if (s.enemies.filter(e => e.active).length >= ENEMY_CAP) return false;
  const side = Math.floor(random(s) * 4), along = random(s);
  const x = side === 0 ? 29 : side === 1 ? WIDTH - 29 : 30 + along * (WIDTH - 60);
  const y = side === 2 ? 29 : side === 3 ? HEIGHT - 29 : 30 + along * (HEIGHT - 60);
  const hp = (kind === 'runner' ? 24 : 38) + (wave(s) - 1) * 6;
  pooled(s.enemies, { active: true, kind, x, y, hp, maxHp: hp, id: s.nextId++, flash: 0 }, ENEMY_CAP);
  return true;
}
function kill(s: State, e: Enemy) {
  e.active = false; s.kills++; s.score += e.kind === 'runner' ? 25 : 15;
  if (s.kills % 3 === 0) pooled(s.pickups, { active: true, x: e.x, y: e.y }, 40);
}
export function defend(s: State) {
  if (s.phase !== 'playing' || s.pulseUsed || s.scrap < 8) return false;
  s.scrap -= 8; s.pulseUsed = true; s.pulse = .7; s.player.invincible = 3;
  for (const e of s.enemies) if (e.active && Math.hypot(e.x - s.player.x, e.y - s.player.y) < 155) kill(s, e);
  return true;
}
export function chooseUpgrade(s: State, id: Upgrade) {
  if (s.phase !== 'upgrade' || !s.choices.includes(id)) return false;
  if (id === 'damage') s.damage *= 1.35;
  if (id === 'rate') s.rate *= .8;
  if (id === 'speed') s.speed *= 1.15;
  if (id === 'health') { s.player.maxHp += 25; s.player.hp = Math.min(s.player.maxHp, s.player.hp + 40); }
  if (id === 'pierce') s.pierce++;
  if (id === 'magnet') s.magnet += 45;
  if (id === 'armor') s.armor *= .75;
  if (id === 'recovery') s.recovery *= 2;
  s.upgrades.push(id); s.upgradeCount++; s.choices = []; s.phase = 'playing'; return true;
}
/** Mutates one owned simulation state. Rendering and persistence never drive the clock. */
export function tick(s: State, input: Vec, dt = STEP) {
  if (s.phase !== 'playing') return;
  dt = Number.isFinite(dt) ? Math.max(0, Math.min(dt, STEP)) : 0;
  if (!dt) return;
  s.time += dt; s.pulse = Math.max(0, s.pulse - dt); s.player.invincible = Math.max(0, s.player.invincible - dt);
  const length = Math.hypot(input.x, input.y), scale = length > 1 ? 1 / length : 1;
  if (Number.isFinite(length)) move(s.player, input.x * scale * s.speed * dt, input.y * scale * s.speed * dt, 11);
  const zone = ZONES[wave(s) - 1];
  if (Math.hypot(s.player.x - zone.x, s.player.y - zone.y) < 43) s.player.hp = Math.min(s.player.maxHp, s.player.hp + dt * s.recovery);
  s.spawnIn -= dt;
  if (s.spawnIn <= 0) { spawn(s); s.spawnIn = Math.max(.42, 1.7 - s.time / 240); }
  s.fireIn = Math.max(0, s.fireIn - dt);
  let nearest: Enemy | undefined, distance = Infinity;
  const bins = new Map<number, Enemy[]>();
  for (const e of s.enemies) if (e.active) {
    e.flash = Math.max(0, e.flash - dt);
    const dx = s.player.x - e.x, dy = s.player.y - e.y, d = Math.hypot(dx, dy) || 1;
    const speed = e.kind === 'runner' ? 76 : 40;
    const before = { x: e.x, y: e.y };
    move(e, dx / d * speed * dt, dy / d * speed * dt, 10);
    if (Math.hypot(e.x - before.x, e.y - before.y) < speed * dt * .25) move(e, (e.id % 2 ? -dy : dy) / d * speed * dt, (e.id % 2 ? dx : -dx) / d * speed * dt, 10);
    const key = Math.floor(e.x / 40) + 16 * Math.floor(e.y / 40);
    const bucket = bins.get(key); if (bucket) bucket.push(e); else bins.set(key, [e]);
    if (d < distance) { nearest = e; distance = d; }
    if (d < 22 && s.player.invincible <= 0) { s.player.hp = Math.max(0, s.player.hp - 10 * s.armor); s.player.invincible = 1.1; }
  }
  if (nearest && s.fireIn <= 0) {
    const angle = Math.atan2(nearest.y - s.player.y, nearest.x - s.player.x); s.player.angle = angle;
    pooled(s.shots, { active: true, x: s.player.x, y: s.player.y, vx: Math.cos(angle) * 390, vy: Math.sin(angle) * 390, life: 1.7, damage: s.damage, pierce: s.pierce, hits: [] }, 64);
    s.fireIn = s.rate;
  }
  for (const shot of s.shots) if (shot.active) {
    shot.x += shot.vx * dt; shot.y += shot.vy * dt; shot.life -= dt;
    if (shot.life <= 0 || shot.x < 16 || shot.x > WIDTH - 16 || shot.y < 16 || shot.y > HEIGHT - 16 || WALLS.some(b => circleRect(shot, 2, b))) { shot.active = false; continue; }
    const bx = Math.floor(shot.x / 40), by = Math.floor(shot.y / 40);
    for (let y = by - 1; y <= by + 1 && shot.active; y++) for (let x = bx - 1; x <= bx + 1 && shot.active; x++) {
      for (const e of bins.get(x + 16 * y) ?? []) if (shot.active && e.active && !shot.hits.includes(e.id) && Math.hypot(shot.x - e.x, shot.y - e.y) < 13) {
        e.hp -= shot.damage; e.flash = .12; shot.hits.push(e.id);
        if (e.hp <= 0) kill(s, e);
        if (shot.pierce-- <= 0) shot.active = false;
      }
    }
  }
  for (const p of s.pickups) if (p.active) {
    const d = Math.hypot(p.x - s.player.x, p.y - s.player.y);
    if (d < s.magnet) { p.active = false; s.scrap++; s.score += 5; }
  }
  if (s.player.hp <= 0) { s.phase = 'lost'; return; }
  if (s.time >= DURATION) { s.time = DURATION; s.score += 500; s.phase = 'won'; return; }
  if (s.upgradeCount < 3 && s.time >= (s.upgradeCount + 1) * 75) {
    const options: Upgrade[] = UPGRADES.map(u => u.id); s.choices = [];
    while (s.choices.length < 3) s.choices.push(options.splice(Math.floor(random(s) * options.length), 1)[0]);
    s.phase = 'upgrade';
  }
}
export function restoreGame(value: unknown): State | null {
  if (!value || typeof value !== 'object') return null;
  const s = value as State, base = createGame();
  const finite = (n: unknown) => typeof n === 'number' && Number.isFinite(n) && n >= 0 && n < 1e10;
  if (s.version !== 1 || !['playing', 'upgrade', 'lost', 'won'].includes(s.phase)) return null;
  for (const key of Object.keys(base) as (keyof State)[]) if (typeof base[key] === 'number' && !finite(s[key])) return null;
  if (!s.player || ![s.player.x, s.player.y, s.player.hp, s.player.maxHp, s.player.invincible].every(finite) || !Number.isFinite(s.player.angle) || s.player.x > WIDTH || s.player.y > HEIGHT || s.player.hp > s.player.maxHp || s.player.maxHp > 500 || s.time > DURATION || s.upgradeCount > 3 || s.rate < .05 || s.speed > 300) return null;
  if (!Array.isArray(s.upgrades) || s.upgrades.length !== s.upgradeCount || !Array.isArray(s.choices) || s.choices.length > 3 || [...s.upgrades, ...s.choices].some(id => !UPGRADES.some(u => u.id === id)) || (s.phase === 'upgrade' && s.choices.length !== 3)) return null;
  if (typeof s.pulseUsed !== 'boolean') return null;
  for (const [items, cap] of [[s.enemies, 120], [s.shots, 64], [s.pickups, 40]] as const) if (!Array.isArray(items) || items.length > cap || items.some(e => !e || typeof e.active !== 'boolean' || !Number.isFinite(e.x) || !Number.isFinite(e.y) || Math.abs(e.x) > 1000 || Math.abs(e.y) > 1000)) return null;
  if (s.enemies.some(e => !['walker', 'runner'].includes(e.kind) || ![e.maxHp, e.id, e.flash].every(finite) || !Number.isFinite(e.hp))) return null;
  if (s.shots.some(b => ![b.vx, b.vy, b.life, b.pierce].every(Number.isFinite) || !finite(b.damage) || !Array.isArray(b.hits) || b.hits.length > 4 || b.hits.some(id => !finite(id)))) return null;
  return JSON.parse(JSON.stringify(s)) as State;
}
