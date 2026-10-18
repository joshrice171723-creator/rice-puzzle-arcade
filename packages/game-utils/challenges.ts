export type Goal = { label: string; value: number; target: number; fraction: number; complete: boolean; hint?: string };

type Metric = 'score' | 'highestTile' | 'linesCleared' | 'multiClears' | 'largestGroup' | 'groupsCleared';
const introductions: Record<string, { name: string; targets: number[]; metrics: Metric[] }> = {
  'grid-foundry': { name: 'Workshop trail', targets: [400, 4, 1, 1400, 12, 2, 3000, 24, 3, 5500, 40, 10000], metrics: ['score', 'linesCleared', 'multiClears', 'score', 'linesCleared', 'multiClears', 'score', 'linesCleared', 'multiClears', 'score', 'linesCleared', 'score'] },
  'merge-drift': { name: 'Ocean expedition', targets: [16, 32, 64, 128, 128, 256, 1024, 2048], metrics: Array<Metric>(8).fill('highestTile') },
  'color-cascade': { name: 'Garden trail', targets: [1200, 5, 12, 3300, 6, 22, 6400, 7, 35, 11200, 8, 13000], metrics: ['score', 'largestGroup', 'groupsCleared', 'score', 'largestGroup', 'groupsCleared', 'score', 'largestGroup', 'groupsCleared', 'score', 'largestGroup', 'score'] },
};

export const LEVELS_PER_ZONE = 10;
export const ZONE_COUNT = 10;
export function completionAllowed(level: number, failedAttempts: number, rewardUsed: boolean): boolean {
  const stage = (level - 1) % LEVELS_PER_ZONE + 1;
  return (level % 7 !== 0 || failedAttempts >= 3) && ((stage !== 8 && stage !== 10) || rewardUsed);
}
const zoneNames: Record<string, string[]> = {
  'grid-foundry': ['Apprentice Bench', 'Copper Corner', 'Gearworks', 'Brass Studio', 'Steam Hall', 'Clock Tower', 'Crystal Forge', 'Sky Workshop', 'Master Foundry', 'Golden Engine'],
  'merge-drift': ['Sunny Shallows', 'Coral Cove', 'Tide Pools', 'Pearl Lagoon', 'Kelp Forest', 'Shipwreck Bay', 'Moonlit Reef', 'Deep Blue', 'Crystal Current', 'Ocean Crown'],
  'color-cascade': ['Sprout Garden', 'Sugar Meadow', 'Berry Patch', 'Honey Grove', 'Petal Falls', 'Candy Orchard', 'Moonflower Park', 'Rainbow Vale', 'Crystal Garden', 'Royal Bloom'],
};

export function levelInfo(slug: string, level: number) {
  const index = Math.max(0, Math.min(99, Number.isFinite(level) ? Math.floor(level) - 1 : 0));
  const stage = index % LEVELS_PER_ZONE + 1;
  const zone = Math.floor(index / LEVELS_PER_ZONE) + 1;
  const difficulty = stage === 10 ? 'Finale' : (index + 1) % 7 === 0 ? 'Expert' : stage === 8 ? 'Hard' : 'Standard';
  return { zone, stage, difficulty, name: (zoneNames[slug] ?? zoneNames['grid-foundry'])[zone - 1] };
}

const journeys = Object.fromEntries(Object.entries(introductions).map(([slug, intro]) => {
  const targets: number[] = [];
  const metrics: Metric[] = [];
  for (let level = 1; level <= LEVELS_PER_ZONE * ZONE_COUNT; level++) {
    const { zone, stage, difficulty } = levelInfo(slug, level);
    const hard = difficulty !== 'Standard';
    let metric: Metric;
    let target: number;
    if (level <= 6) {
      metric = intro.metrics[level - 1]; target = intro.targets[level - 1];
    } else if (slug === 'grid-foundry') {
      metric = hard ? 'score' : stage % 3 === 2 ? 'linesCleared' : stage % 3 === 0 ? 'multiClears' : 'score';
      target = metric === 'score' ? 1000 + zone * 450 + stage * 100 + (hard ? 1000 : 0)
        : metric === 'linesCleared' ? 4 + zone * 2 + stage : Math.min(6, 1 + Math.floor(zone / 2));
    } else if (slug === 'merge-drift') {
      metric = hard || stage % 2 === 1 ? 'highestTile' : 'score';
      target = metric === 'highestTile' ? 2 ** Math.min(11, 7 + Math.floor(zone / 3) + (hard ? 2 : 0)) : 400 + zone * 400 + stage * 100;
    } else {
      metric = hard ? 'score' : stage % 3 === 2 ? 'largestGroup' : stage % 3 === 0 ? 'groupsCleared' : 'score';
      target = metric === 'score' ? 2200 + zone * 450 + stage * 150 + (hard ? 2000 : 0)
        : metric === 'largestGroup' ? Math.min(7, 5 + Math.floor(zone / 3)) : 12 + zone * 3 + stage;
    }
    targets.push(target); metrics.push(metric);
  }
  return [slug, { name: intro.name, targets, metrics }];
}));

export function journey(slug: string) {
  return journeys[slug] ?? journeys['grid-foundry'];
}

export function levelGoal(slug: string, level: number, saved?: unknown): Goal {
  const { targets, metrics } = journey(slug);
  const index = Math.max(0, Math.min(targets.length - 1, Number.isFinite(level) ? Math.floor(level) - 1 : 0));
  const target = targets[index];
  const metric = metrics[index];
  const candidate = saved && typeof saved === 'object' ? (saved as Record<string, unknown>)[metric] : 0;
  const value = typeof candidate === 'number' && Number.isFinite(candidate) ? Math.max(0, candidate) : 0;
  const labels: Record<Metric, string> = { score: `Earn ${target.toLocaleString()} points`, highestTile: `Make a ${target.toLocaleString()} tile`, linesCleared: `Clear ${target} lines`, multiClears: target === 1 ? 'Clear 2+ lines together' : `Make ${target} multi-line clears`, largestGroup: `Match a group of ${target}`, groupsCleared: `Clear ${target} groups` };
  const hints: Record<Metric, string> = {
    score: slug === 'color-cascade' ? 'Grow bigger groups: clear beneath matching colors.' : slug === 'merge-drift' ? 'Keep your largest tile in a corner. Build toward it.' : 'Plan all three pieces before filling a gap.',
    highestTile: target <= 64 ? 'Merge small pairs. Keep a row open for new tiles.' : 'Keep your largest tile in a corner. Build toward it.',
    linesCleared: 'Leave room for long pieces. Finish nearly full lines.',
    multiClears: 'Build a row and column with one shared empty square.',
    largestGroup: 'Clear below matching colors to bring them together.',
    groupsCleared: 'Find easy groups of three. Keep your taps moving.',
  };
  return { label: labels[metric], value, target, fraction: Math.min(1, value / target), complete: value >= target, hint: hints[metric] };
}
