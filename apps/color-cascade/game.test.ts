import { describe, expect, it } from 'vitest';
import { advanceTimer, collapseAndRefill, createGame, extendTime, findGroup, hasMove, restoreGame, shuffleBoard, tapGroup, type Board } from './game';

const checker = (): Board => Array.from({ length: 7 }, (_, row) => Array.from({ length: 7 }, (_, col) => (row + col) % 5));
const playable = () => {
  const state = createGame(123);
  state.board = checker();
  state.board[0][0] = state.board[0][1] = state.board[0][2] = 4;
  return state;
};

describe('Color Cascade groups and scoring', () => {
  it('counts a branching orthogonal group without double counting', () => {
    const board = checker();
    for (const [r, c] of [[2, 2], [2, 3], [2, 4], [1, 3], [3, 3]]) board[r][c] = 0;
    const group = findGroup(board, 2, 3);
    expect(group.length).toBeGreaterThanOrEqual(5);
    expect(new Set(group.map(({ row, col }) => `${row},${col}`)).size).toBe(group.length);
  });

  it('does not connect diagonal-only matches', () => {
    const board = checker();
    board[0][0] = board[1][1] = board[2][2] = 4;
    expect(findGroup(board, 0, 0)).toEqual([{ row: 0, col: 0 }]);
    expect(hasMove(checker())).toBe(false);
  });

  it('rejects taps outside the board or on a group below three without consuming random values', () => {
    const state = createGame(5);
    state.board = checker();
    for (const [r, c] of [[-1, 0], [0, 7], [7, 0], [0.5, 2], [NaN, 0], [0, 0]]) {
      expect(tapGroup(state, r, c)).toBe(state);
    }
  });

  it('scores precisely 10 times group size squared and preserves its input', () => {
    const state = playable();
    const before = JSON.stringify(state);
    const size = findGroup(state.board, 0, 0).length;
    const next = tapGroup(state, 0, 0);
    expect(size).toBe(3);
    expect(next.score).toBe(90);
    expect(next.lastGroupSize).toBe(3);
    expect(next.groupsCleared).toBe(1);
    expect(next.remainingMs).toBe(90_000);
    expect(JSON.stringify(state)).toBe(before);
  });

  it('rewards large groups quadratically, including a full-board cascade', () => {
    const state = playable();
    state.board = Array.from({ length: 7 }, () => Array(7).fill(2));
    const next = tapGroup(state, 6, 6);
    expect(next.score).toBe(24_010);
    expect(next.lastGroupSize).toBe(49);
    expect(hasMove(next.board)).toBe(true);
  });
});

describe('Color Cascade gravity, refill and shuffle', () => {
  it('preserves survivor order and drops cells into the correct column', () => {
    const board = checker();
    const result = collapseAndRefill(board, [{ row: 2, col: 1 }, { row: 4, col: 1 }], 77);
    expect(result.board.slice(2).map(row => row[1])).toEqual([board[0][1], board[1][1], board[3][1], board[5][1], board[6][1]]);
    for (let row = 0; row < 7; row++) {
      for (let col = 0; col < 7; col++) {
        if (col !== 1) expect(result.board[row][col]).toBe(board[row][col]);
      }
    }
    expect(result.board.flat().every(value => Number.isInteger(value) && value >= 0 && value < 5)).toBe(true);
  });

  it('refills deterministically without mutating its input', () => {
    const board = checker();
    const before = JSON.stringify(board);
    const removed = [{ row: 6, col: 0 }, { row: 0, col: 4 }];
    expect(collapseAndRefill(board, removed, 16)).toEqual(collapseAndRefill(board, removed, 16));
    expect(JSON.stringify(board)).toBe(before);
  });

  it('always restores a legal match while preserving all symbol counts', () => {
    const board = checker();
    const sorted = [...board.flat()].sort();
    for (let seed = 0; seed < 200; seed++) {
      const result = shuffleBoard(board, seed);
      expect(hasMove(result.board)).toBe(true);
      expect([...result.board.flat()].sort()).toEqual(sorted);
      expect(result).toEqual(shuffleBoard(board, seed));
    }
    expect(board).toEqual(checker());
  });

  it('creates valid playable deterministic starting boards across seeds', () => {
    for (let seed = 0; seed < 100; seed++) {
      const state = createGame(seed);
      expect(state).toEqual(createGame(seed));
      expect(state.board).toHaveLength(7);
      expect(state.board.every(row => row.length === 7)).toBe(true);
      expect(hasMove(state.board)).toBe(true);
      expect(state.score).toBe(0);
      expect(state.remainingMs).toBe(90_000);
    }
    expect(createGame(1).board).not.toEqual(createGame(2).board);
  });

  it('stays playable through a long deterministic sequence of cascades', () => {
    let state = createGame(9831);
    let replay = createGame(9831);
    for (let step = 0; step < 120; step++) {
      let row = 0;
      let col = 0;
      outer: for (row = 0; row < 7; row++) {
        for (col = 0; col < 7; col++) if (findGroup(state.board, row, col).length >= 3) break outer;
      }
      const previousScore = state.score;
      state = tapGroup(state, row, col);
      replay = tapGroup(replay, row, col);
      expect(state.score).toBeGreaterThan(previousScore);
      expect(state).toEqual(replay);
      expect(hasMove(state.board)).toBe(true);
    }
  });
});

describe('Color Cascade foreground clock and earned extension', () => {
  it('counts foreground milliseconds precisely and clamps timeout to zero', () => {
    const state = createGame(6);
    expect(advanceTimer(state, 250).remainingMs).toBe(89_750);
    expect(advanceTimer(state, 123_456).remainingMs).toBe(0);
    expect(advanceTimer(advanceTimer(state, 90_000), 100)).toEqual(advanceTimer(state, 90_000));
  });

  it('does not count explicit pause, background, consent, or full-screen-ad time', () => {
    let state = createGame(6);
    state = advanceTimer(state, 1_000, true);
    for (const interruption of [30_000, 150_000, 2_000, 22_000]) {
      const before = state;
      state = advanceTimer(state, interruption, false);
      expect(state).toBe(before);
    }
    expect(advanceTimer(state, 1_000, true).remainingMs).toBe(88_000);
  });

  it('ignores invalid, non-finite and backwards elapsed values', () => {
    const state = createGame(1);
    for (const delta of [-1, 0, NaN, Infinity, -Infinity]) expect(advanceTimer(state, delta)).toBe(state);
  });

  it('refuses clearing and extensions during active play', () => {
    const state = playable();
    expect(extendTime(state)).toBe(state);
    const expired = advanceTimer(state, 90_000);
    expect(tapGroup(expired, 0, 0)).toBe(expired);
  });

  it('grants exactly one earned 20-second continuation after timeout', () => {
    const expired = advanceTimer(playable(), 90_000);
    const earned = extendTime(expired);
    expect(earned.remainingMs).toBe(20_000);
    expect(earned.reviveUsed).toBe(true);
    expect(earned.score).toBe(expired.score);
    expect(earned.board).toEqual(expired.board);
    expect(extendTime(earned)).toBe(earned);
    const endedAgain = advanceTimer(earned, 20_000);
    expect(extendTime(endedAgain)).toBe(endedAgain);
  });
});

describe('Color Cascade validated persistence', () => {
  it('round-trips score, random state, foreground time and once-only reward', () => {
    const played = tapGroup(playable(), 0, 0);
    const earned = advanceTimer(extendTime(advanceTimer(played, 90_000)), 500);
    const saved = JSON.parse(JSON.stringify(earned));
    expect(restoreGame(saved)).toEqual(earned);
    expect(restoreGame(saved)?.board).not.toBe(saved.board);
    expect(extendTime(advanceTimer(restoreGame(saved)!, 20_000)).reviveUsed).toBe(true);
  });

  it('repairs a dead saved board with an explicit free-shuffle count', () => {
    const state = createGame(3);
    state.board = checker();
    const restored = restoreGame(state)!;
    expect(hasMove(restored.board)).toBe(true);
    expect(restored.shuffleCount).toBe(state.shuffleCount + 1);
    expect(restored.score).toBe(state.score);
    expect(restored.remainingMs).toBe(state.remainingMs);
  });

  it('rejects corrupted saves rather than rendering unsafe boards', () => {
    const state = createGame(3);
    for (const bad of [null, [], {}, { ...state, version: 2 }, { ...state, board: [] }, { ...state, board: [[0]] }, { ...state, score: -3 }, { ...state, score: '400' }, { ...state, score: Infinity }, { ...state, rng: -1 }, { ...state, rng: 2 ** 32 }, { ...state, remainingMs: NaN }, { ...state, remainingMs: -1 }, { ...state, remainingMs: 100_000 }, { ...state, reviveUsed: 'true' }, { ...state, groupsCleared: 0.5 }]) expect(restoreGame(bad)).toBeUndefined();
    for (const badColor of [-1, 5, 0.5, '2', NaN]) {
      const board = state.board.map(row => [...row]);
      board[0][0] = badColor as number;
      expect(restoreGame({ ...state, board })).toBeUndefined();
    }
  });
});
