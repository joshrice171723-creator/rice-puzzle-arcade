export type Mode = 'normal' | 'daily' | 'journey';
export type Run = { id: string; seed: number; mode: Mode; date: string; saved?: unknown; ended: boolean; rewardUsed: boolean; counted: boolean; level?: number; completed?: boolean };
export type ArcadeSave = {
  version: 1;
  levelFailures: Record<string, number>;
  settings: { music: boolean; sound: boolean; haptics: boolean; tutorialSeen: boolean; theme: 'day' | 'bloom' | 'night'; softTiles: boolean };
  stats: { best: number; highestTile: number; games: number; dailyDate: string; dailyBest: number; unlockedLevel: number };
  runs: Partial<Record<Mode, Run>>;
};
export interface StorageAdapter { getItem(key: string): Promise<string | null>; setItem(key: string, value: string): Promise<unknown> }
export const emptySave = (): ArcadeSave => ({ version: 1, levelFailures: {}, settings: { music: true, sound: false, haptics: true, tutorialSeen: false, theme: 'day', softTiles: true }, stats: { best: 0, highestTile: 0, games: 0, dailyDate: '', dailyBest: 0, unlockedLevel: 1 }, runs: {} });
const count = (value: unknown): value is number => typeof value === 'number' && Number.isSafeInteger(value) && value >= 0;
const record = (value: unknown): value is Record<string, unknown> => !!value && typeof value === 'object' && !Array.isArray(value);
export const localDate = (date = new Date()): string => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
export function dailySeed(slug: string, date: string): number {
  let seed = 2166136261;
  for (const character of `${slug}:${date}`) seed = Math.imul(seed ^ character.charCodeAt(0), 16777619);
  return seed >>> 0 || 1;
}

export function parseSave(text: string | null): ArcadeSave | null {
  if (text === null) return emptySave();
  try {
    const value: unknown = JSON.parse(text);
    if (!record(value) || value.version !== 1 || !record(value.settings) || !record(value.stats) || !record(value.runs)) return null;
    const { settings, stats, runs } = value;
    if (![settings.sound, settings.haptics, settings.tutorialSeen].every(flag => typeof flag === 'boolean') ||
      ![stats.best, stats.highestTile, stats.games, stats.dailyBest].every(count) || typeof stats.dailyDate !== 'string') return null;
    const result = emptySave();
    if (value.levelFailures !== undefined) {
      if (!record(value.levelFailures) || Object.entries(value.levelFailures).some(([level, failures]) => !/^[1-9]\d?$|^100$/.test(level) || !count(failures))) return null;
      result.levelFailures = { ...value.levelFailures } as Record<string, number>;
    }
    result.settings = { music: typeof settings.music === 'boolean' ? settings.music : true, sound: settings.sound as boolean, haptics: settings.haptics as boolean, tutorialSeen: settings.tutorialSeen as boolean, theme: settings.theme === 'bloom' || settings.theme === 'night' ? settings.theme : 'day', softTiles: typeof settings.softTiles === 'boolean' ? settings.softTiles : true };
    result.stats = { best: stats.best as number, highestTile: stats.highestTile as number, games: stats.games as number, dailyDate: stats.dailyDate, dailyBest: stats.dailyBest as number, unlockedLevel: count(stats.unlockedLevel) && stats.unlockedLevel > 0 ? stats.unlockedLevel : 1 };
    for (const mode of ['normal', 'daily', 'journey'] as const) {
      const run = runs[mode];
      if (run === undefined) continue;
      if (!record(run) || run.mode !== mode || typeof run.id !== 'string' || run.id.length > 100 || !count(run.seed) || run.seed > 0xffffffff ||
        typeof run.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(run.date) ||
        ![run.ended, run.rewardUsed, run.counted].every(flag => typeof flag === 'boolean') ||
        (run.saved !== undefined && (!record(run.saved) || !count(run.saved.score)))) return null;
      if (mode === 'journey' && (!count(run.level) || run.level < 1 || typeof run.completed !== 'boolean')) return null;
      result.runs[mode] = { id: run.id, seed: run.seed, mode, date: run.date, ended: run.ended as boolean, rewardUsed: run.rewardUsed as boolean, counted: run.counted as boolean, saved: run.saved, ...(mode === 'journey' ? { level: run.level as number, completed: run.completed as boolean } : {}) };
    }
    return result;
  } catch { return null; }
}

export function updateRun(save: ArcadeSave, run: Run): ArcadeSave {
  const score = record(run.saved) && count(run.saved.score) ? run.saved.score : 0;
  const highest = record(run.saved) && count(run.saved.highestTile) ? run.saved.highestTile : 0;
  const firstEnd = run.ended && !run.counted;
  const daily = run.mode === 'daily';
  return {
    ...save,
    levelFailures: firstEnd && run.mode === 'journey' && !run.completed && run.level
      ? { ...save.levelFailures, [run.level]: (save.levelFailures[run.level] ?? 0) + 1 } : save.levelFailures,
    stats: {
      best: Math.max(save.stats.best, score), highestTile: Math.max(save.stats.highestTile, highest),
      games: save.stats.games + Number(firstEnd),
      dailyDate: daily ? run.date : save.stats.dailyDate,
      dailyBest: daily ? Math.max(save.stats.dailyDate === run.date ? save.stats.dailyBest : 0, score) : save.stats.dailyBest,
      unlockedLevel: run.mode === 'journey' && run.ended && run.completed && run.level ? Math.max(save.stats.unlockedLevel, run.level + 1) : save.stats.unlockedLevel,
    },
    runs: { ...save.runs, [run.mode]: { ...run, counted: run.counted || firstEnd } },
  };
}

/** Snapshot before enqueueing; one failed write must not block later progress. */
export function createSaveWriter(adapter: StorageAdapter, key: string, onError: (error: unknown) => void) {
  let queue = Promise.resolve();
  return (save: ArcadeSave): Promise<void> => {
    const snapshot = JSON.stringify(save);
    queue = queue.then(async () => { try { await adapter.setItem(key, snapshot); } catch (error) { onError(error); } });
    return queue;
  };
}
