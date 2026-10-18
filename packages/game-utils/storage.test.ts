import { describe, expect, it } from 'vitest';
import { createSaveWriter, dailySeed, emptySave, localDate, parseSave, Run, updateRun } from './storage';

const run = (extra: Partial<Run> = {}): Run => ({ id: 'test', mode: 'normal', seed: 42, date: '2026-10-17', ended: false, rewardUsed: false, counted: false, saved: { score: 40, highestTile: 16 }, ...extra });

describe('arcade persistence', () => {
  it('defaults to muted sound and handles absent or corrupt storage', () => {
    expect(parseSave(null)).toEqual(emptySave());
    expect(emptySave().settings.sound).toBe(false);
    for (const text of ['broken', '{}', 'null', '[]', JSON.stringify({ ...emptySave(), version: 2 }), JSON.stringify({ ...emptySave(), settings: { sound: 'yes' } }), JSON.stringify({ ...emptySave(), stats: { ...emptySave().stats, best: -1 } })]) expect(parseSave(text)).toBeNull();
  });
  it('saves independent daily and normal runs and round-trips settings', () => {
    let save = updateRun(emptySave(), run());
    save = updateRun(save, run({ mode: 'daily', id: 'daily', seed: 12, saved: { score: 80 } }));
    save.settings = { ...save.settings, sound: true, haptics: false, tutorialSeen: true };
    expect(parseSave(JSON.stringify(save))).toEqual(save);
    expect(save.runs.normal?.seed).toBe(42);
    expect(save.runs.daily?.seed).toBe(12);
    expect(save.stats).toEqual({ best: 80, highestTile: 16, games: 0, dailyBest: 80, dailyDate: '2026-10-17', unlockedLevel: 1 });
  });
  it('restores older saves and persists visual preferences without changing a run', () => {
    const save = updateRun(emptySave(), run());
    const old = JSON.parse(JSON.stringify(save));
    delete old.settings.theme; delete old.settings.softTiles;
    expect(parseSave(JSON.stringify(old))).toEqual(save);
    save.settings.theme = 'night'; save.settings.softTiles = false;
    expect(parseSave(JSON.stringify(save))).toEqual(save);
    expect(parseSave(JSON.stringify({ ...save, settings: { ...save.settings, theme: 'unknown', softTiles: null } }))?.settings).toEqual({ ...save.settings, theme: 'day', softTiles: true });
  });
  it('counts a whole run only once across an earned rescue and second ending', () => {
    let save = updateRun(emptySave(), run({ ended: true }));
    expect(save.stats.games).toBe(1);
    save = updateRun(save, { ...save.runs.normal!, ended: false, rewardUsed: true });
    save = updateRun(save, { ...save.runs.normal!, ended: true, saved: { score: 80, highestTile: 32 } });
    expect(save.stats.games).toBe(1);
    expect(save.stats.best).toBe(80);
    expect(save.stats.highestTile).toBe(32);
    save = updateRun(save, run({ id: 'next', ended: true }));
    expect(save.stats.games).toBe(2);
  });
  it('rolls daily best to the new local challenge date without losing all-time best', () => {
    let save = updateRun(emptySave(), run({ mode: 'daily', saved: { score: 100 } }));
    save = updateRun(save, run({ mode: 'daily', saved: { score: 50 } }));
    expect(save.stats.dailyBest).toBe(100);
    save = updateRun(save, run({ mode: 'daily', date: '2026-10-18', saved: { score: 20 } }));
    expect(save.stats.dailyBest).toBe(20);
    expect(save.stats.best).toBe(100);
  });
  it('rejects damaged run envelopes and leaves engine-level checks to games', () => {
    for (const extra of [{ mode: 'wrong' }, { seed: -1 }, { date: '' }, { seed: 0x100000000 }, { saved: { score: -1 } }, { rewardUsed: 'yes' }, { saved: [] }]) {
      const save = { ...emptySave(), runs: { normal: { ...run(), ...extra } } };
      expect(parseSave(JSON.stringify(save))).toBeNull();
    }
  });
  it('has game-specific repeatable daily seeds and uses local date components', () => {
    expect(dailySeed('merge', '2026-10-17')).toBe(dailySeed('merge', '2026-10-17'));
    expect(dailySeed('merge', '2026-10-17')).not.toBe(dailySeed('grid', '2026-10-17'));
    expect(dailySeed('merge', '2026-10-17')).not.toBe(dailySeed('merge', '2026-10-18'));
    expect(localDate(new Date(2026, 0, 2, 1))).toBe('2026-01-02');
  });
  it('serializes writes, captures immutable snapshots, and continues after errors', async () => {
    const written: number[] = [];
    const errors: unknown[] = [];
    let active = false;
    const write = createSaveWriter({ getItem: async () => null, setItem: async (key, value) => {
      expect(key).toBe('test'); expect(active).toBe(false); active = true;
      await Promise.resolve();
      const score = JSON.parse(value).stats.best;
      written.push(score); active = false;
      if (score === 2) throw new Error('disk full');
    } }, 'test', error => errors.push(error));
    const save = emptySave(); save.stats.best = 1;
    const first = write(save); save.stats.best = 2;
    const second = write(save); save.stats.best = 3;
    const third = write(save);
    await Promise.all([first, second, third]);
    expect(written).toEqual([1, 2, 3]); expect(errors).toHaveLength(1);
  });
});
