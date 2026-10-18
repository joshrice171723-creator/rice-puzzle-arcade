export type Goal = { label: string; value: number; target: number; fraction: number; complete: boolean };

type Metric = 'score' | 'highestTile' | 'linesCleared' | 'multiClears' | 'largestGroup' | 'groupsCleared';
const journeys: Record<string, { name: string; targets: number[]; metrics: Metric[] }> = {
  'grid-foundry': { name: 'Workshop trail', targets: [400, 4, 1, 1400, 12, 2, 3000, 24, 3, 5500, 40, 10000], metrics: ['score', 'linesCleared', 'multiClears', 'score', 'linesCleared', 'multiClears', 'score', 'linesCleared', 'multiClears', 'score', 'linesCleared', 'score'] },
  'merge-drift': { name: 'Ocean expedition', targets: [16, 32, 64, 128, 256, 512, 1024, 2048], metrics: Array<Metric>(8).fill('highestTile') },
  'color-cascade': { name: 'Garden trail', targets: [1200, 5, 12, 3300, 6, 22, 6400, 7, 35, 11200, 8, 15500], metrics: ['score', 'largestGroup', 'groupsCleared', 'score', 'largestGroup', 'groupsCleared', 'score', 'largestGroup', 'groupsCleared', 'score', 'largestGroup', 'score'] },
};

export function journey(slug: string) {
  return journeys[slug] ?? journeys['grid-foundry'];
}

export function levelGoal(slug: string, level: number, saved?: unknown): Goal {
  const { targets, metrics } = journey(slug);
  const index = Math.max(0, Math.min(targets.length - 1, Math.floor(level) - 1));
  const target = targets[index];
  const metric = metrics[index];
  const candidate = saved && typeof saved === 'object' ? (saved as Record<string, unknown>)[metric] : 0;
  const value = typeof candidate === 'number' && Number.isFinite(candidate) ? Math.max(0, candidate) : 0;
  const labels: Record<Metric, string> = { score: `Earn ${target.toLocaleString()} points`, highestTile: `Make a ${target.toLocaleString()} tile`, linesCleared: `Clear ${target} lines`, multiClears: target === 1 ? 'Clear 2+ lines together' : `Make ${target} multi-line clears`, largestGroup: `Match a group of ${target}`, groupsCleared: `Clear ${target} groups` };
  return { label: labels[metric], value, target, fraction: Math.min(1, value / target), complete: value >= target };
}
