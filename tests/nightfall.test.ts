import { describe, expect, it } from 'vitest';
import { chooseUpgrade, circleRect, createGame, defend, ENEMY_CAP, move, restoreGame, spawn, STEP, tick, WALLS } from '../apps/nightfall-arena/game';

describe('Nightfall Arena simulation', () => {
  it('replays a seeded run exactly and resumes the same RNG stream', () => {
    const a = createGame(71), b = createGame(71);
    for (let i = 0; i < 1800; i++) { const direction = { x: Math.sin(i / 70), y: Math.cos(i / 90) }; tick(a, direction); tick(b, direction); }
    expect(a).toEqual(b);
    const resumed = restoreGame(JSON.parse(JSON.stringify(a)))!; expect(resumed).not.toBeNull();
    for (let i = 0; i < 300; i++) { tick(a, { x: 1, y: 0 }); tick(resumed, { x: 1, y: 0 }); }
    expect(resumed).toEqual(a);
  });
  it('normalizes diagonal movement and caps large/invalid elapsed times', () => {
    const a = createGame(), b = createGame();
    tick(a, { x: 1, y: 0 }); tick(b, { x: 1, y: 1 }, 10);
    expect(Math.hypot(b.player.x - 200, b.player.y - 270)).toBeCloseTo(a.player.x - 200);
    expect(b.time).toBe(STEP); tick(b, { x: NaN, y: 0 }, Infinity); expect(b.time).toBe(STEP);
  });
  it('blocks cover and arena walls without trapping a sliding player', () => {
    const p = { x: 60, y: 135 }; move(p, 10, 10, 11);
    expect(WALLS.some(wall => circleRect(p, 11, wall))).toBe(false); expect(p.x).toBe(70); expect(p.y).toBe(135);
    for (let i = 0; i < 500; i++) move(p, -4, -4, 11);
    expect(p).toEqual({ x: 27, y: 27 });
  });
  it('applies contact damage once during invulnerability and can end a run', () => {
    const s = createGame(); spawn(s); Object.assign(s.enemies[0], { x: 201, y: 270, hp: 1000 });
    tick(s, { x: 0, y: 0 }); expect(s.player.hp).toBe(90);
    for (let i = 0; i < 30; i++) tick(s, { x: 0, y: 0 }); expect(s.player.hp).toBe(90);
    s.player.invincible = 0; s.player.hp = 1; tick(s, { x: 0, y: 0 }); expect(s.phase).toBe('lost');
    const time = s.time; tick(s, { x: 1, y: 0 }); expect(s.time).toBe(time);
  });
  it('uses capped reusable enemy slots', () => {
    const s = createGame(); for (let i = 0; i < 200; i++) spawn(s);
    expect(s.enemies).toHaveLength(ENEMY_CAP); expect(spawn(s)).toBe(false);
    const oldId = s.enemies[10].id; s.enemies[10].active = false; expect(spawn(s)).toBe(true);
    expect(s.enemies).toHaveLength(ENEMY_CAP); expect(s.enemies[10].id).not.toBe(oldId);
  });
  it('hits enemies, stops projectiles at cover and never hits twice with one shot', () => {
    const s = createGame(); s.spawnIn = 100; s.fireIn = 100; spawn(s);
    Object.assign(s.enemies[0], { x: 230, y: 270, hp: 100, maxHp: 100 });
    s.shots.push({ x: 224, y: 270, vx: 0, vy: 0, life: 1, damage: 10, pierce: 2, active: true, hits: [] });
    tick(s, { x: 0, y: 0 }); tick(s, { x: 0, y: 0 }); expect(s.enemies[0].hp).toBe(90);
    s.shots.push({ x: 80, y: 149, vx: 0, vy: 100, life: 1, damage: 10, pierce: 0, active: true, hits: [] });
    tick(s, { x: 0, y: 0 }); expect(s.shots[1].active).toBe(false);
  });
  it('pauses at three unique upgrade offers, then finishes at five minutes', () => {
    const s = createGame();
    for (const milestone of [75, 150, 225]) {
      s.time = milestone - STEP / 2; tick(s, { x: 0, y: 0 });
      expect(s.phase).toBe('upgrade'); expect(new Set(s.choices).size).toBe(3);
      const time = s.time; tick(s, { x: 1, y: 0 }); expect(s.time).toBe(time);
      expect(chooseUpgrade(s, s.choices[0])).toBe(true); expect(chooseUpgrade(s, 'health')).toBe(false);
    }
    expect(s.upgradeCount).toBe(3); s.time = 300 - STEP / 2; tick(s, { x: 0, y: 0 });
    expect(s.phase).toBe('won'); expect(s.time).toBe(300); expect(s.score).toBe(500);
  });
  it('requires earned scrap and grants only one defense pulse', () => {
    const s = createGame(); expect(defend(s)).toBe(false); s.scrap = 8;
    spawn(s); Object.assign(s.enemies[0], { x: 210, y: 270 });
    expect(defend(s)).toBe(true); expect(s.scrap).toBe(0); expect(s.kills).toBe(1); expect(s.player.invincible).toBe(3);
    s.scrap = 20; expect(defend(s)).toBe(false); expect(s.scrap).toBe(20);
  });
  it('heals in the active shelter and moves the shelter each wave', () => {
    const s = createGame(); Object.assign(s.player, { x: 85, y: 430, hp: 50 });
    tick(s, { x: 0, y: 0 }); expect(s.player.hp).toBeGreaterThan(50);
    s.time = 61; const hp = s.player.hp; tick(s, { x: 0, y: 0 }); expect(s.player.hp).toBe(hp);
  });
  it('rejects damaged saves but restores a run before its first enemy appears', () => {
    const s = createGame(); for (let i = 0; i < 20; i++) tick(s, { x: 0, y: 0 });
    expect(restoreGame(s)).toEqual(s); expect(restoreGame(null)).toBeNull();
    expect(restoreGame({ ...s, time: Infinity })).toBeNull(); expect(restoreGame({ ...s, enemies: new Array(121).fill({}) })).toBeNull();
    expect(restoreGame({ ...s, phase: 'upgrade', choices: [] })).toBeNull();
    expect(restoreGame({ ...s, player: { ...s.player, hp: 1000 } })).toBeNull();
  });
});
