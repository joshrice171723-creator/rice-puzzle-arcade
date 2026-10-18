export const SIZE = 7;
export const COLORS = 5;
export const ROUND_MS = 90_000;
export type Board = number[][];
export type Cell = { row: number; col: number };
export type CascadeState = {
  version: 1;
  board: Board;
  rng: number;
  score: number;
  remainingMs: number;
  reviveUsed: boolean;
  shuffleCount: number;
  groupsCleared: number;
  lastGroupSize: number;
};

function random(seed: number): [number, number] {
  let next = seed >>> 0 || 0x9e3779b9;
  next ^= next << 13;
  next ^= next >>> 17;
  next ^= next << 5;
  return [(next >>> 0) / 0x100000000, next >>> 0];
}

export function findGroup(board: Board, row: number, col: number): Cell[] {
  if (!Number.isInteger(row) || !Number.isInteger(col) || row < 0 || row >= SIZE || col < 0 || col >= SIZE) return [];
  const color = board[row][col];
  const pending: Cell[] = [{ row, col }];
  const visited = new Set<number>();
  const group: Cell[] = [];
  while (pending.length) {
    const cell = pending.pop()!;
    const key = cell.row * SIZE + cell.col;
    if (visited.has(key)) continue;
    visited.add(key);
    if (board[cell.row][cell.col] !== color) continue;
    group.push(cell);
    for (const [dr, dc] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
      const nr = cell.row + dr;
      const nc = cell.col + dc;
      if (nr >= 0 && nr < SIZE && nc >= 0 && nc < SIZE) pending.push({ row: nr, col: nc });
    }
  }
  return group;
}

export function hasMove(board: Board): boolean {
  for (let row = 0; row < SIZE; row++) {
    for (let col = 0; col < SIZE; col++) {
      if (findGroup(board, row, col).length >= 3) return true;
    }
  }
  return false;
}

export function shuffleBoard(board: Board, rng: number): { board: Board; rng: number } {
  const cells = board.flat();
  for (let attempt = 0; attempt < 20; attempt++) {
    for (let i = cells.length - 1; i > 0; i--) {
      let value: number;
      [value, rng] = random(rng);
      const j = Math.floor(value * (i + 1));
      [cells[i], cells[j]] = [cells[j], cells[i]];
    }
    const candidate = Array.from({ length: SIZE }, (_, row) => cells.slice(row * SIZE, (row + 1) * SIZE));
    if (hasMove(candidate)) return { board: candidate, rng };
  }
  // A finite shuffle must always preserve a move, even for an unlucky seed.
  const color = cells.find(value => cells.filter(cell => cell === value).length >= 3)!;
  for (let i = 0; i < 3; i++) {
    const index = cells.findIndex((value, index) => index >= i && value === color);
    [cells[i], cells[index]] = [cells[index], cells[i]];
  }
  return { board: Array.from({ length: SIZE }, (_, row) => cells.slice(row * SIZE, (row + 1) * SIZE)), rng };
}

export function collapseAndRefill(board: Board, removed: Cell[], rng: number): { board: Board; rng: number } {
  const keys = new Set(removed.map(({ row, col }) => row * SIZE + col));
  const next = Array.from({ length: SIZE }, () => Array<number>(SIZE));
  for (let col = 0; col < SIZE; col++) {
    const survivors = board.map(row => row[col]).filter((_, row) => !keys.has(row * SIZE + col));
    const missing = SIZE - survivors.length;
    for (let row = 0; row < SIZE; row++) {
      if (row >= missing) next[row][col] = survivors[row - missing];
      else {
        let value: number;
        [value, rng] = random(rng);
        next[row][col] = Math.floor(value * COLORS);
      }
    }
  }
  return { board: next, rng };
}

export function createGame(seed: number): CascadeState {
  let rng = seed >>> 0 || 0x9e3779b9;
  const board = Array.from({ length: SIZE }, () => Array.from({ length: SIZE }, () => {
    let value: number;
    [value, rng] = random(rng);
    return Math.floor(value * COLORS);
  }));
  const playable = hasMove(board) ? { board, rng } : shuffleBoard(board, rng);
  return { version: 1, ...playable, score: 0, remainingMs: ROUND_MS, reviveUsed: false, shuffleCount: hasMove(board) ? 0 : 1, groupsCleared: 0, lastGroupSize: 0 };
}

export function tapGroup(state: CascadeState, row: number, col: number): CascadeState {
  if (state.remainingMs <= 0) return state;
  const group = findGroup(state.board, row, col);
  if (group.length < 3) return state;
  const result = collapseAndRefill(state.board, group, state.rng);
  const shuffled = !hasMove(result.board);
  const playable = shuffled ? shuffleBoard(result.board, result.rng) : result;
  return { ...state, ...playable, score: state.score + 10 * group.length ** 2, groupsCleared: state.groupsCleared + 1, lastGroupSize: group.length, shuffleCount: state.shuffleCount + Number(shuffled) };
}

export function advanceTimer(state: CascadeState, elapsedMs: number, foreground = true): CascadeState {
  if (!foreground || !Number.isFinite(elapsedMs) || elapsedMs <= 0 || state.remainingMs <= 0) return state;
  return { ...state, remainingMs: Math.max(0, state.remainingMs - elapsedMs) };
}

export function extendTime(state: CascadeState): CascadeState {
  if (state.remainingMs > 0 || state.reviveUsed) return state;
  return { ...state, remainingMs: 20_000, reviveUsed: true };
}

export function restoreGame(value: unknown): CascadeState | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const state = value as CascadeState;
  const count = (number: unknown) => typeof number === 'number' && Number.isSafeInteger(number) && number >= 0;
  if (state.version !== 1 || !Array.isArray(state.board) || state.board.length !== SIZE || !state.board.every(row => Array.isArray(row) && row.length === SIZE && row.every(color => count(color) && color < COLORS))) return undefined;
  if (!count(state.rng) || state.rng > 0xffffffff || !count(state.score) || !count(state.shuffleCount) || !count(state.groupsCleared) || !count(state.lastGroupSize) || state.lastGroupSize > SIZE * SIZE || typeof state.reviveUsed !== 'boolean' || !Number.isFinite(state.remainingMs) || state.remainingMs < 0 || state.remainingMs > ROUND_MS) return undefined;
  if (!hasMove(state.board)) return { ...state, ...shuffleBoard(state.board, state.rng), shuffleCount: state.shuffleCount + 1 };
  return { ...state, board: state.board.map(row => [...row]) };
}
