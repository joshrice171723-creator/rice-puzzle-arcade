import { describe, expect, it } from 'vitest';
import { journey, levelGoal } from './challenges';
import { emptySave, parseSave, Run, updateRun } from './storage';

describe('level journeys', () => {
  it('gives every level a short strategy matched to its objective', () => {
    for (const slug of ['grid-foundry', 'merge-drift', 'color-cascade']) {
      journey(slug).targets.forEach((_, index) => {
        const hint = levelGoal(slug, index + 1).hint!;
        expect(hint.length).toBeGreaterThan(20);
        expect(hint.length).toBeLessThan(65);
      });
    }
    expect(levelGoal('grid-foundry', 3).hint).toContain('shared empty square');
    expect(levelGoal('merge-drift', 8).hint).toContain('corner');
    expect(levelGoal('color-cascade', 3).hint).toContain('groups of three');
  });
  it('sets increasing goals that use each game’s actual metric', () => {
    for (const slug of ['grid-foundry', 'merge-drift', 'color-cascade']) {
      const targets = journey(slug).targets;
      const { metrics } = journey(slug);
      expect(metrics).toHaveLength(targets.length);
      for (const metric of new Set(metrics)) {
        const series = targets.filter((_, index) => metrics[index] === metric);
        expect(series.every((target, index) => index === 0 || target > series[index - 1])).toBe(true);
      }
      const metric = slug === 'merge-drift' ? 'highestTile' : 'score';
      expect(levelGoal(slug, 1, { [metric]: targets[0] - 1 }).complete).toBe(false);
      expect(levelGoal(slug, 1, { [metric]: targets[0] }).complete).toBe(true);
      expect(levelGoal(slug, 1, { [metric]: targets[0] * 2 }).fraction).toBe(1);
    }
    expect(levelGoal('merge-drift', 1, { score: 1000, highestTile: 8 }).complete).toBe(false);
    expect(levelGoal('grid-foundry', 2, { score: 4000, linesCleared: 3 }).complete).toBe(false);
    expect(levelGoal('grid-foundry', 3, { linesCleared: 10, multiClears: 0 }).complete).toBe(false);
    expect(levelGoal('grid-foundry', 3, { multiClears: 1 }).complete).toBe(true);
    expect(levelGoal('color-cascade', 2, { score: 2000, largestGroup: 4 }).complete).toBe(false);
    expect(levelGoal('color-cascade', 2, { score: 2000, largestGroup: 5 }).complete).toBe(true);
  });

  it('unlocks only a completed level and never advances twice for the same result', () => {
    const run: Run = { id: 'level1', mode: 'journey', level: 1, completed: false, seed: 123, date: '2026-10-18', ended: true, counted: false, rewardUsed: false, saved: { score: 300 } };
    let save = updateRun(emptySave(), run);
    expect(save.stats.unlockedLevel).toBe(1);
    save = updateRun(save, { ...save.runs.journey!, completed: true, saved: { score: 400 } });
    expect(save.stats.unlockedLevel).toBe(2);
    save = updateRun(save, save.runs.journey!);
    expect(save.stats.unlockedLevel).toBe(2);
    expect(save.stats.games).toBe(1);
    expect(parseSave(JSON.stringify(save))).toEqual(save);
  });

  it('migrates existing saves without losing normal or daily progress', () => {
    const save = emptySave();
    const old = JSON.parse(JSON.stringify(save));
    delete old.stats.unlockedLevel;
    expect(parseSave(JSON.stringify(old))).toEqual(save);
    expect(levelGoal('grid-foundry', 1, null).value).toBe(0);
  });
});
