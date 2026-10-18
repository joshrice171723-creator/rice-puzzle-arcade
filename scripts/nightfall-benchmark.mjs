import { performance } from 'node:perf_hooks';
import { mkdir, writeFile } from 'node:fs/promises';
import { chooseUpgrade, createGame, defend, ENEMY_CAP, spawn, tick } from '../apps/nightfall-arena/game.ts';

// Synthetic load, not a physical-device frame-rate measurement.
const stress = createGame(812); stress.player.invincible = 1000;
for (let i = 0; i < ENEMY_CAP; i++) spawn(stress);
const timings = [];
for (let i = 0; i < 18000; i++) {
  if (stress.phase === 'upgrade') chooseUpgrade(stress, stress.choices[0]);
  while (stress.enemies.filter(e => e.active).length < ENEMY_CAP) spawn(stress);
  const start = performance.now(); tick(stress, { x: Math.cos(i / 300), y: Math.sin(i / 300) }); timings.push(performance.now() - start);
}
timings.sort((a, b) => a - b);
const runs = [];
for (let seed = 1; seed <= 20; seed++) {
  const s = createGame(seed);
  const points = [{ x: 38, y: 215 }, { x: 38, y: 500 }, { x: 362, y: 500 }, { x: 362, y: 215 }]; let target = 0;
  for (let frame = 0; frame < 18010 && !['lost', 'won'].includes(s.phase); frame++) {
    if (s.phase === 'upgrade') {
      const preference = ['rate', 'damage', 'health', 'armor', 'speed', 'pierce', 'magnet', 'recovery'];
      chooseUpgrade(s, preference.find(id => s.choices.includes(id))); 
    }
    if (s.player.hp < 40) defend(s);
    const p = points[target]; if (Math.hypot(p.x - s.player.x, p.y - s.player.y) < 5) target = (target + 1) % points.length;
    const next = points[target], dx = next.x - s.player.x, dy = next.y - s.player.y, d = Math.hypot(dx, dy) || 1;
    tick(s, { x: dx / d, y: dy / d });
  }
  runs.push({ seed, result: s.phase, seconds: Math.round(s.time), score: s.score, upgrades: s.upgrades });
}
const result = { kind: 'Node simulation benchmark; scripted route, not human playtest or device FPS', frames: timings.length, enemyLoad: ENEMY_CAP, p50StepMs: timings[Math.floor(timings.length * .5)], p95StepMs: timings[Math.floor(timings.length * .95)], p99StepMs: timings[Math.floor(timings.length * .99)], poolSizes: { enemies: stress.enemies.length, shots: stress.shots.length, pickups: stress.pickups.length }, runs };
await mkdir('artifacts/nightfall', { recursive: true }); await writeFile('artifacts/nightfall/simulation-benchmark.json', JSON.stringify(result, null, 2));
console.log(JSON.stringify(result, null, 2));
