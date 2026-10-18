/** Eligibility uses only the board/clock, never ad availability or value. */
export function boostAvailable(slug: string, saved: unknown): boolean {
  if (!saved || typeof saved !== 'object') return false;
  const state = saved as { board?: unknown; remainingMs?: number; revived?: boolean; rescueUsed?: boolean; reviveUsed?: boolean; ended?: boolean };
  if (state.ended) return false;
  if (slug === 'grid-foundry') return !state.revived && Array.isArray(state.board) && state.board.flat().filter(cell => cell === 1).length >= 40;
  if (slug === 'merge-drift') return !state.rescueUsed && Array.isArray(state.board) && state.board.filter(cell => cell === 0).length <= 3 && state.board.length === 16;
  if (slug === 'color-cascade') return !state.reviveUsed && typeof state.remainingMs === 'number' && state.remainingMs > 0 && state.remainingMs <= 15_000;
  return false;
}
