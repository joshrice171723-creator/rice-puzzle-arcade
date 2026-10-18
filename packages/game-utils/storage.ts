export type Mode = 'normal' | 'daily';
export type Run = { id: string; seed: number; mode: Mode; date: string; saved?: unknown; ended: boolean; rewardUsed: boolean; counted: boolean };
export type ArcadeSave = {
  version: 1;
  settings: { sound: boolean; haptics: boolean; tutorialSeen: boolean };
  stats: { best: number; highestTile: number; games: number; dailyDate: string; dailyBest: number };
  runs: Partial<Record<Mode, Run>>;
};
export interface StorageAdapter { getItem(key: string): Promise<string | null>; setItem(key: string, value: string): Promise<unknown> }
export const emptySave = (): ArcadeSave => ({ version: 1, settings: { sound: false, haptics: true, tutorialSeen: false }, stats: { best: 0, highestTile: 0, games: 0, dailyDate: '', dailyBest: 0 }, runs: {} });
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
    result.settings = { sound: settings.sound as boolean, haptics: settings.haptics as boolean, tutorialSeen: settings.tutorialSeen as boolean };
    result.stats = { best: stats.best as number, highestTile: stats.highestTile as number, games: stats.games as number, dailyDate: stats.dailyDate, dailyBest: stats.dailyBest as number };
    for (const mode of ['normal', 'daily'] as const) {
      const run = runs[mode];
      if (run === undefined) continue;
      if (!record(run) || run.mode !== mode || typeof run.id !== 'string' || run.id.length > 100 || !count(run.seed) || run.seed > 0xffffffff ||
        typeof run.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(run.date) ||
        ![run.ended, run.rewardUsed, run.counted].every(flag => typeof flag === 'boolean') ||
        (run.saved !== undefined && (!record(run.saved) || !count(run.saved.score)))) return null;
      result.runs[mode] = { id: run.id, seed: run.seed, mode, date: run.date, ended: run.ended as boolean, rewardUsed: run.rewardUsed as boolean, counted: run.counted as boolean, saved: run.saved };
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
    stats: {
      best: Math.max(save.stats.best, score), highestTile: Math.max(save.stats.highestTile, highest),
      games: save.stats.games + Number(firstEnd),
      dailyDate: daily ? run.date : save.stats.dailyDate,
      dailyBest: daily ? Math.max(save.stats.dailyDate === run.date ? save.stats.dailyBest : 0, score) : save.stats.dailyBest,
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
