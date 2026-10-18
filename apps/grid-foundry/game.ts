export const SIZE = 8;
export const SHAPES = {
  spark: [[0, 0]], bar2: [[0, 0], [0, 1]], bar3: [[0, 0], [0, 1], [0, 2]],
  tower2: [[0, 0], [1, 0]], tower3: [[0, 0], [1, 0], [2, 0]],
  corner: [[0, 0], [1, 0], [1, 1]], hook: [[0, 1], [1, 0], [1, 1]],
  square: [[0, 0], [0, 1], [1, 0], [1, 1]],
  tee: [[0, 0], [0, 1], [0, 2], [1, 1]],
  stair: [[0, 0], [0, 1], [1, 1], [1, 2]],
} as const;
export type Shape = keyof typeof SHAPES;
export type Board = number[][];
export type GameState = {
  version: 1; board: Board; tray: (Shape | null)[]; score: number;
  rng: number; moves: number; ended: boolean; revived: boolean;
};
export const emptyBoard = (): Board => Array.from({ length: SIZE }, () => Array<number>(SIZE).fill(0));
const names = Object.keys(SHAPES) as Shape[];
// Xorshift32: the saved unsigned RNG state reproduces each tray exactly.
export function random(state: number): [number, number] {
  let next = state >>> 0 || 0x9e3779b9;
  next ^= next << 13; next ^= next >>> 17; next ^= next << 5;
  return [(next >>> 0) / 4294967296, next >>> 0];
}
export function canPlace(board: Board, shape: Shape, row: number, col: number): boolean {
  return Number.isInteger(row) && Number.isInteger(col) && SHAPES[shape].every(([r, c]) =>
    row + r >= 0 && row + r < SIZE && col + c >= 0 && col + c < SIZE && board[row + r][col + c] === 0);
}
export function fits(board: Board, shape: Shape): boolean {
  for (let r = 0; r < SIZE; r++) for (let c = 0; c < SIZE; c++) if (canPlace(board, shape, r, c)) return true;
  return false;
}
export const hasMove = (board: Board, tray: (Shape | null)[]): boolean => tray.some(shape => shape !== null && fits(board, shape));
function drawTray(board: Board, rng: number): { tray: Shape[]; rng: number } {
  const tray: Shape[] = [];
  for (let i = 0; i < 3; i++) {
    const [value, next] = random(rng); rng = next;
    tray.push(names[Math.floor(value * names.length)]);
  }
  // Retain a playable hand when a legal library piece exists; no ads influence the draw.
  if (!hasMove(board, tray)) {
    const playable = names.filter(shape => fits(board, shape));
    if (playable.length) {
      const [value, next] = random(rng); rng = next;
      tray[0] = playable[Math.floor(value * playable.length)];
    }
  }
  return { tray, rng };
}
export function newGame(seed: number): GameState {
  const board = emptyBoard();
  return { version: 1, board, ...drawTray(board, seed >>> 0 || 1), score: 0, moves: 0, ended: false, revived: false };
}
export type Placement = { state: GameState; cleared: [number, number][]; lines: number; points: number };
export function place(state: GameState, index: number, row: number, col: number): Placement {
  const unchanged = { state, cleared: [], lines: 0, points: 0 };
  const shape = state.tray[index];
  if (state.ended || !shape || !canPlace(state.board, shape, row, col)) return unchanged;
  const board = state.board.map(line => [...line]);
  SHAPES[shape].forEach(([r, c]) => { board[row + r][col + c] = 1; });
  const rows = board.map((line, r) => line.every(Boolean) ? r : -1).filter(r => r >= 0);
  const cols = Array.from({ length: SIZE }, (_, c) => c).filter(c => board.every(line => line[c] !== 0));
  const cleared: [number, number][] = [];
  for (let r = 0; r < SIZE; r++) for (let c = 0; c < SIZE; c++) {
    if (rows.includes(r) || cols.includes(c)) { cleared.push([r, c]); board[r][c] = 0; }
  }
  const lines = rows.length + cols.length;
  const points = SHAPES[shape].length * 10 + Math.round(lines * 100 * (1 + Math.max(0, lines - 1) * 0.25));
  let tray = state.tray.map((piece, i) => i === index ? null : piece);
  let rng = state.rng;
  if (tray.every(piece => piece === null)) ({ tray, rng } = drawTray(board, rng));
  return { state: { ...state, board, tray, rng, score: state.score + points, moves: state.moves + 1, ended: !hasMove(board, tray) }, cleared, lines, points };
}
export function revive(state: GameState): GameState {
  if (!state.ended || state.revived) return state;
  const occupied = state.board.map((line, row) => ({ row, count: line.filter(Boolean).length }))
    .sort((a, b) => b.count - a.count || a.row - b.row).slice(0, 2).map(item => item.row);
  const board = state.board.map((line, row) => occupied.includes(row) ? Array<number>(SIZE).fill(0) : [...line]);
  return { ...state, board, ...drawTray(board, state.rng), ended: false, revived: true };
}
export function restoreGame(value: unknown): GameState | null {
  if (!value || typeof value !== 'object') return null;
  const s = value as Partial<GameState>;
  if (s.version !== 1 || !Array.isArray(s.board) || s.board.length !== SIZE ||
    !s.board.every(line => Array.isArray(line) && line.length === SIZE && line.every(cell => cell === 0 || cell === 1)) ||
    !Array.isArray(s.tray) || s.tray.length !== 3 || !s.tray.some(Boolean) ||
    !s.tray.every(shape => shape === null || typeof shape === 'string' && names.includes(shape as Shape)) ||
    !Number.isSafeInteger(s.score) || s.score! < 0 || !Number.isSafeInteger(s.moves) || s.moves! < 0 ||
    !Number.isInteger(s.rng) || s.rng! <= 0 || s.rng! > 0xffffffff ||
    typeof s.ended !== 'boolean' || typeof s.revived !== 'boolean') return null;
  const state = s as GameState;
  return { ...state, board: state.board.map(row => [...row]), tray: [...state.tray], ended: !hasMove(state.board, state.tray) };
}
