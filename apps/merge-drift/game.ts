import { boostAvailable } from '../../packages/game-utils/boost';
export type Direction = 'left' | 'right' | 'up' | 'down';
export type MergeState = {
  version: 1;
  board: number[];
  score: number;
  highestTile: number;
  rng: number;
  moves: number;
  rescueUsed: boolean;
  ended: boolean;
};
export type Movement = { from: number; to: number; value: number; merged: boolean };

export function random(seed: number): [number, number] {
  let next = seed >>> 0 || 0x9e3779b9;
  next ^= next << 13;
  next ^= next >>> 17;
  next ^= next << 5;
  return [(next >>> 0) / 4294967296, next >>> 0];
}

export function spawn(board: number[], seed: number): { board: number[]; rng: number } {
  const empty = board.flatMap((value, index) => value === 0 ? [index] : []);
  if (!empty.length) return { board: [...board], rng: seed };
  const [position, next] = random(seed);
  const [value, rng] = random(next);
  const result = [...board];
  result[empty[Math.floor(position * empty.length)]] = spawnValue(value);
  return { board: result, rng };
}

export function spawnValue(probability: number): 2 | 4 {
  return probability < 0.9 ? 2 : 4;
}

export function isGameOver(board: number[]): boolean {
  return board.every((value, index) => value !== 0 &&
    (index % 4 === 3 || value !== board[index + 1]) &&
    (index >= 12 || value !== board[index + 4]));
}

export function createGame(seed: number): MergeState {
  const first = spawn(Array<number>(16).fill(0), seed);
  const second = spawn(first.board, first.rng);
  return { version: 1, ...second, score: 0, highestTile: Math.max(...second.board), moves: 0, rescueUsed: false, ended: false };
}

function lineIndexes(direction: Direction, line: number): number[] {
  return Array.from({ length: 4 }, (_, slot) => {
    if (direction === 'left') return line * 4 + slot;
    if (direction === 'right') return line * 4 + 3 - slot;
    if (direction === 'up') return slot * 4 + line;
    return (3 - slot) * 4 + line;
  });
}

export function move(state: MergeState, direction: Direction): { state: MergeState; changed: boolean; movements: Movement[] } {
  if (state.ended) return { state, changed: false, movements: [] };
  const board = Array<number>(16).fill(0);
  const movements: Movement[] = [];
  let gained = 0;
  for (let line = 0; line < 4; line++) {
    const indexes = lineIndexes(direction, line);
    const tiles = indexes.filter(index => state.board[index] !== 0);
    let destination = 0;
    for (let source = 0; source < tiles.length; source++) {
      const from = tiles[source];
      const value = state.board[from];
      const merged = source + 1 < tiles.length && value === state.board[tiles[source + 1]];
      const to = indexes[destination++];
      board[to] = merged ? value * 2 : value;
      movements.push({ from, to, value, merged });
      if (merged) {
        movements.push({ from: tiles[++source], to, value, merged: true });
        gained += value * 2;
      }
    }
  }
  if (board.every((value, index) => value === state.board[index])) return { state, changed: false, movements: [] };
  const spawned = spawn(board, state.rng);
  return {
    changed: true,
    movements,
    state: { ...state, ...spawned, score: state.score + gained, highestTile: Math.max(state.highestTile, ...spawned.board), moves: state.moves + 1, ended: isGameOver(spawned.board) },
  };
}

/** Called only after the shell confirms an earned SDK reward. */
export function rescue(state: MergeState, allowBoost = false): MergeState {
  if ((!state.ended && !(allowBoost && boostAvailable('merge-drift', state))) || state.rescueUsed) return state;
  const smallest = state.board.map((value, index) => ({ value, index }))
    .filter(tile => tile.value > 0).sort((a, b) => a.value - b.value || a.index - b.index).slice(0, 2);
  const board = [...state.board];
  smallest.forEach(tile => { board[tile.index] = 0; });
  return { ...state, board, ended: false, rescueUsed: true };
}

export function restoreGame(saved: unknown): MergeState | null {
  if (!saved || typeof saved !== 'object') return null;
  const value = saved as Partial<MergeState>;
  const validTile = (tile: unknown): tile is number => typeof tile === 'number' && Number.isSafeInteger(tile) &&
    (tile === 0 || (tile >= 2 && Number.isInteger(Math.log2(tile))));
  if (value.version !== 1 || !Array.isArray(value.board) || value.board.length !== 16 || !value.board.every(validTile) ||
    !Number.isSafeInteger(value.score) || value.score! < 0 || !validTile(value.highestTile) || value.highestTile < 2 ||
    !Number.isInteger(value.rng) || value.rng! < 0 || value.rng! > 0xffffffff ||
    !Number.isSafeInteger(value.moves) || value.moves! < 0 || typeof value.rescueUsed !== 'boolean' ||
    typeof value.ended !== 'boolean' || value.ended !== isGameOver(value.board) || value.board.filter(tile => tile > 0).length < 2) return null;
  return { version: 1, board: [...value.board], score: value.score!, highestTile: Math.max(value.highestTile, ...value.board), rng: value.rng!, moves: value.moves!, rescueUsed: value.rescueUsed, ended: value.ended };
}
