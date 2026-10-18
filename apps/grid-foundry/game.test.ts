import { describe, expect, it } from 'vitest';
import { canPlace, emptyBoard, fits, GameState, hasMove, newGame, place, random, restoreGame, revive, Shape, SHAPES } from './game';

const stateWith = (changes: Partial<GameState> = {}): GameState => ({ ...newGame(87654), ...changes });

describe('Grid Foundry engine', () => {
  it('starts with a fresh 8 by 8 board and three reproducible pieces', () => {
    expect(newGame(42)).toEqual(newGame(42));
    const game = newGame(42);
    expect(game.board).toHaveLength(8);
    expect(game.board.every(row => row.length === 8 && row.every(cell => cell === 0))).toBe(true);
    expect(game.tray.filter(Boolean)).toHaveLength(3);
    expect(hasMove(game.board, game.tray)).toBe(true);
    expect(game.score).toBe(0);
  });

  for (const [shape, cells] of Object.entries(SHAPES)) {
    it(`checks all edges and every cell collision for ${shape}`, () => {
      const board = emptyBoard();
      for (let r = -3; r < 11; r++) for (let c = -3; c < 11; c++) {
        const expected = cells.every(([dr, dc]) => r + dr >= 0 && r + dr < 8 && c + dc >= 0 && c + dc < 8);
        expect(canPlace(board, shape as Shape, r, c), `${shape} at ${r},${c}`).toBe(expected);
      }
      for (const [r, c] of cells) {
        const collision = emptyBoard(); collision[r + 2][c + 2] = 1;
        expect(canPlace(collision, shape as Shape, 2, 2)).toBe(false);
      }
      expect(canPlace(board, shape as Shape, .5, 0)).toBe(false);
      expect(canPlace(board, shape as Shape, 0, Number.NaN)).toBe(false);
    });
  }

  it('invalid drops and unavailable pieces preserve state, RNG, score and tray', () => {
    const game = stateWith({ tray: ['square', null, 'bar3'] });
    for (const [index, r, c] of [[0, 7, 7], [1, 0, 0], [3, 0, 0], [-1, 0, 0]]) {
      const result = place(game, index, r, c);
      expect(result.state).toBe(game);
      expect(result.points).toBe(0);
      expect(result.cleared).toEqual([]);
    }
  });

  it('scores cells and consumes only the chosen piece without mutating input', () => {
    const game = stateWith({ tray: ['square', 'bar3', 'spark'] });
    const before = JSON.stringify(game);
    const result = place(game, 0, 2, 3);
    expect(result.points).toBe(40);
    expect(result.state.score).toBe(40);
    expect(result.state.moves).toBe(1);
    expect(result.state.tray).toEqual([null, 'bar3', 'spark']);
    expect(result.state.board[2].slice(3, 5)).toEqual([1, 1]);
    expect(result.state.board[3].slice(3, 5)).toEqual([1, 1]);
    expect(JSON.stringify(game)).toBe(before);
  });

  it('clears crossing rows and columns simultaneously, counting their intersection once', () => {
    const board = emptyBoard();
    for (let i = 0; i < 8; i++) { board[3][i] = 1; board[i][3] = 1; }
    board[3][3] = 0; board[0][0] = 1;
    const result = place(stateWith({ board, tray: ['spark', 'square', 'bar2'] }), 0, 3, 3);
    expect(result.lines).toBe(2);
    expect(result.cleared).toHaveLength(15);
    expect(result.points).toBe(260); // 10 placement + (2 * 100 * 1.25) line combo.
    expect(result.state.board[0][0]).toBe(1);
    expect(result.state.board.flat().filter(Boolean)).toHaveLength(1);
  });

  it('applies the fixed four-line combo to a square completing two rows and columns', () => {
    const board = emptyBoard();
    for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) if (r < 2 || c < 2) board[r][c] = 1;
    for (let r = 0; r < 2; r++) for (let c = 0; c < 2; c++) board[r][c] = 0;
    const result = place(stateWith({ board, tray: ['square', 'spark', 'bar2'] }), 0, 0, 0);
    expect(result.lines).toBe(4);
    expect(result.points).toBe(740);
    expect(result.state.board).toEqual(emptyBoard());
  });

  it('refills exactly when the third piece is used', () => {
    let state = stateWith({ tray: ['spark', 'spark', 'spark'] });
    const rng = state.rng;
    state = place(state, 0, 0, 0).state;
    state = place(state, 1, 0, 1).state;
    expect(state.rng).toBe(rng);
    expect(state.tray).toEqual([null, null, 'spark']);
    state = place(state, 2, 0, 2).state;
    expect(state.tray.every(Boolean)).toBe(true);
    expect(state.rng).not.toBe(rng);
  });

  it('ends only when no available piece fits, rather than when one piece fails', () => {
    const board = Array.from({ length: 8 }, () => Array<number>(8).fill(1));
    board[0][0] = 0;
    expect(fits(board, 'square')).toBe(false);
    expect(hasMove(board, ['square', null, 'spark'])).toBe(true);
    expect(hasMove(board, ['square', null, 'bar3'])).toBe(false);
    expect(hasMove(board, [null, null, null])).toBe(false);
    const patterned = emptyBoard().map((row, r) => row.map((_, c) => (r + c) % 2));
    const result = place(stateWith({ board: patterned, tray: ['spark', 'square', 'bar3'] }), 0, 0, 0);
    expect(result.state.ended).toBe(true);
    expect(place(result.state, 1, 0, 2).state).toBe(result.state);
  });

  it('replays full deterministic placement sequences and survives serialized saves', () => {
    let a = newGame(20261017), b = newGame(20261017);
    for (let turn = 0; turn < 120 && !a.ended; turn++) {
      let move: [number, number, number] | undefined;
      for (let i = 0; i < 3 && !move; i++) {
        const shape = a.tray[i];
        if (shape) for (let r = 0; r < 8 && !move; r++) for (let c = 0; c < 8 && !move; c++) {
          if (canPlace(a.board, shape, r, c)) move = [i, r, c];
        }
      }
      expect(move).toBeDefined();
      a = place(a, ...move!).state;
      b = place(b, ...move!).state;
      expect(a).toEqual(b);
      expect(restoreGame(JSON.parse(JSON.stringify(a)))).toEqual(a);
    }
    expect(a.moves).toBeGreaterThan(3);
  });

  it('validates save contents, derives ended state and clones restored data', () => {
    expect(restoreGame(null)).toBeNull();
    const game = newGame(4);
    for (const patch of [{ version: 2 }, { board: [] }, { board: Array(8).fill(Array(8).fill(2)) },
      { tray: ['unknown', null, null] }, { tray: [null, null, null] }, { score: -1 }, { score: Infinity },
      { rng: 0 }, { rng: 4294967296 }, { moves: 1.1 }, { revived: 'yes' }, { ended: undefined }]) {
      expect(restoreGame({ ...game, ...patch })).toBeNull();
    }
    const restored = restoreGame({ ...game, ended: true })!;
    expect(restored.ended).toBe(false);
    restored.board[0][0] = 1;
    expect(game.board[0][0]).toBe(0);
  });

  it('uses a deterministic unsigned RNG with zero-state protection', () => {
    expect(random(123)).toEqual(random(123));
    for (const seed of [0, 1, -1, 123, 0xffffffff]) {
      const [sample, next] = random(seed);
      expect(sample).toBeGreaterThanOrEqual(0); expect(sample).toBeLessThan(1);
      expect(next).toBeGreaterThan(0); expect(Number.isInteger(next)).toBe(true);
    }
  });

  it('grants revive only at game over and once per run, clearing two busiest rows', () => {
    const active = newGame(5);
    expect(revive(active)).toBe(active);
    const board = emptyBoard();
    board[1].fill(1); board[6].fill(1); board[2][0] = 1;
    const ended = stateWith({ board, ended: true, score: 990, moves: 30 });
    const revived = revive(ended);
    expect(revived.board[1]).toEqual(Array(8).fill(0));
    expect(revived.board[6]).toEqual(Array(8).fill(0));
    expect(revived.board[2][0]).toBe(1);
    expect(revived.score).toBe(990);
    expect(revived.moves).toBe(30);
    expect(revived.revived).toBe(true);
    expect(revived.ended).toBe(false);
    expect(hasMove(revived.board, revived.tray)).toBe(true);
    expect(revive(revived)).toBe(revived);
    const endedAgain = { ...revived, ended: true };
    expect(revive(endedAgain)).toBe(endedAgain);
    expect(ended.board[1][0]).toBe(1);
  });

  it('revive is deterministic for tied occupancy and retains a playable hand', () => {
    const board = Array.from({ length: 8 }, () => Array<number>(8).fill(1));
    const ended = stateWith({ board, ended: true });
    const result = revive(ended);
    expect(result).toEqual(revive(ended));
    expect(result.board[0]).toEqual(Array(8).fill(0));
    expect(result.board[1]).toEqual(Array(8).fill(0));
    expect(result.board[2][0]).toBe(1);
    expect(hasMove(result.board, result.tray)).toBe(true);
  });
});
