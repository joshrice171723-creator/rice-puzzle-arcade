import { describe, expect, it } from 'vitest';
import { createGame, Direction, isGameOver, MergeState, move, random, rescue, restoreGame, spawn, spawnValue } from './game';

function state(board: number[], extra: Partial<MergeState> = {}): MergeState {
  return { version: 1, board, score: 0, highestTile: Math.max(2, ...board), rng: 1234, moves: 0, rescueUsed: false, ended: isGameOver(board), ...extra };
}
const blocked = [2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2];

describe('Merge Drift engine', () => {
  it('recovers older saves whose highest tile omitted a spawned 4', () => {
    const saved = state([2, 4, ...Array(14).fill(0)], { highestTile: 2, score: 0, moves: 1 });
    expect(restoreGame(saved)).toEqual({ ...saved, highestTile: 4 });
    expect(saved.highestTile).toBe(2);
  });
  it('keeps every early swipe resumable when a new 4 is spawned', () => {
    for (let seed = 1; seed <= 100; seed++) {
      const initial = state([0, 2, 0, 0, 0, 2, ...Array(10).fill(0)], { rng: seed });
      const next = move(initial, 'left').state;
      expect(next.highestTile).toBe(Math.max(...next.board));
      expect(restoreGame(JSON.parse(JSON.stringify(next)))).toEqual(next);
    }
  });

  it('starts with exactly two seeded tiles and deterministic independent boards', () => {
    const game = createGame(45);
    expect(game.board.filter(Boolean)).toHaveLength(2);
    expect(game.board.every(tile => [0, 2, 4].includes(tile))).toBe(true);
    expect(game).toEqual(createGame(45));
    expect(createGame(46)).not.toEqual(game);
    expect(createGame(0).board.filter(Boolean)).toHaveLength(2);
  });

  it.each([
    ['left', [0, 2, 2, 0, ...Array(12).fill(0)], 0],
    ['right', [0, 2, 2, 0, ...Array(12).fill(0)], 3],
    ['up', [0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0], 0],
    ['down', [0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0], 12],
  ] as [Direction, number[], number][])('%s slides and merges into its leading edge', (direction, board, target) => {
    const result = move(state(board), direction);
    expect(result.changed).toBe(true);
    expect(result.state.board[target]).toBe(4);
    expect(result.state.score).toBe(4);
    expect(result.state.board.filter(Boolean)).toHaveLength(2);
    expect(result.state.moves).toBe(1);
    expect(result.movements).toHaveLength(2);
    expect(result.movements.every(item => item.to === target && item.merged)).toBe(true);
  });

  it('merges 2,2,2,2 into 4,4 and never merges the results together', () => {
    const result = move(state([2, 2, 2, 2, ...Array(12).fill(0)]), 'left');
    expect(result.state.board.slice(0, 2)).toEqual([4, 4]);
    expect(result.state.score).toBe(8);
    expect(result.state.board.filter(Boolean)).toHaveLength(3);
  });

  it('does not merge a new 4 again into an existing 4', () => {
    const result = move(state([2, 2, 4, 0, ...Array(12).fill(0)], { score: 12 }), 'left');
    expect(result.state.board.slice(0, 2)).toEqual([4, 4]);
    expect(result.state.score).toBe(16);
    expect(result.state.highestTile).toBe(4);
  });

  it('slides across gaps and merges in direction order', () => {
    const result = move(state([2, 0, 2, 2, ...Array(12).fill(0)]), 'right');
    expect(result.state.board.slice(2, 4)).toEqual([2, 4]);
    expect(result.movements.filter(item => item.merged).map(item => item.from)).toEqual([3, 2]);
  });

  it('preserves input, tracks milestones and keeps playing above 1024', () => {
    const initial = state([1024, 1024, 0, 0, ...Array(12).fill(0)]);
    const before = JSON.stringify(initial);
    const result = move(initial, 'left');
    expect(result.state.highestTile).toBe(2048);
    expect(result.state.score).toBe(2048);
    expect(result.state.ended).toBe(false);
    expect(JSON.stringify(initial)).toBe(before);
  });

  it.each(['left', 'right', 'up', 'down'] as Direction[])('adds one cube after a blocked %s move', direction => {
    const board = Array(16).fill(0);
    const positions = { left: [0, 4], right: [3, 7], up: [0, 1], down: [12, 13] }[direction];
    board[positions[0]] = 2; board[positions[1]] = 4;
    const initial = state(board);
    const result = move(initial, direction);
    expect(result.changed).toBe(true);
    expect(result.state.board.filter(Boolean)).toHaveLength(3);
    expect(result.state.score).toBe(0);
    expect(result.state.moves).toBe(1);
    expect(result.state.rng).not.toBe(initial.rng);
    expect(initial.board).toEqual(board);
    expect(restoreGame(JSON.parse(JSON.stringify(result.state)))).toEqual(result.state);
  });

  it('does not overwrite cubes on a full board with a blocked direction', () => {
    const initial = state([2, 4, 8, 16, 2, 4, 8, 16, 4, 8, 16, 32, 8, 16, 32, 64]);
    expect(initial.ended).toBe(false);
    expect(move(initial, 'right').state).toBe(initial);
  });

  it('checks game over when the penalty cube fills the final space', () => {
    const board = [...blocked]; board[15] = 0;
    let losses = 0;
    for (let seed = 1; seed <= 30; seed++) {
      const result = move(state(board, { rng: seed }), 'up').state;
      expect(result.board.filter(Boolean)).toHaveLength(16);
      expect(result.ended).toBe(isGameOver(result.board));
      if (result.ended) losses++;
    }
    expect(losses).toBeGreaterThan(0);
  });

  it('uses the exact 90/10 tile probability boundary', () => {
    expect(spawnValue(0)).toBe(2);
    expect(spawnValue(0.899999999)).toBe(2);
    expect(spawnValue(0.9)).toBe(4);
    expect(spawnValue(0.999999999)).toBe(4);
    for (let seed = 1; seed < 300; seed++) {
      const board = [...blocked];
      board[7] = 0;
      const [_, next] = random(seed);
      const [probability, expectedRng] = random(next);
      const result = spawn(board, seed);
      expect(result.board[7]).toBe(spawnValue(probability));
      expect(result.rng).toBe(expectedRng);
      expect(result.board.filter(Boolean)).toHaveLength(16);
    }
  });

  it('does not overwrite full boards or advance RNG without room', () => {
    expect(spawn(blocked, 17)).toEqual({ board: blocked, rng: 17 });
  });

  it('ends only on a full board without orthogonal pairs', () => {
    expect(isGameOver(blocked)).toBe(true);
    const empty = [...blocked]; empty[15] = 0;
    expect(isGameOver(empty)).toBe(false);
    const horizontal = [...blocked]; horizontal[1] = 2;
    expect(isGameOver(horizontal)).toBe(false);
    const vertical = [...blocked]; vertical[4] = 2;
    expect(isGameOver(vertical)).toBe(false);
    const rowBoundary = [2, 4, 8, 16, 16, 8, 4, 2, 2, 4, 8, 16, 16, 8, 4, 2];
    expect(isGameOver(rowBoundary)).toBe(true);
    const initial = state(blocked);
    expect(move(initial, 'up').state).toBe(initial);
  });

  it('only an earned rescue at game over removes the two smallest tiles once', () => {
    const initial = state(blocked, { score: 200 });
    const result = rescue(initial);
    expect(result.board[0]).toBe(0);
    expect(result.board[2]).toBe(0);
    expect(result.board.filter(Boolean)).toHaveLength(14);
    expect(result.rescueUsed).toBe(true);
    expect(result.ended).toBe(false);
    expect(result.score).toBe(200);
    expect(rescue(result)).toBe(result);
    const endedAgain = { ...result, board: blocked, ended: true };
    expect(rescue(endedAgain)).toBe(endedAgain);
    const active = createGame(1);
    expect(rescue(active)).toBe(active);
    expect(initial.board).toEqual(blocked);
  });

  it('replays identical swipe sequences and resumes without random drift', () => {
    let original = createGame(90);
    let restored = restoreGame(JSON.parse(JSON.stringify(original)))!;
    for (const direction of ['left', 'down', 'right', 'up', 'left', 'down'] as Direction[]) {
      original = move(original, direction).state;
      restored = move(restored, direction).state;
      expect(restored).toEqual(original);
    }
    expect(restoreGame(JSON.parse(JSON.stringify(rescue(state(blocked)))))).toEqual(rescue(state(blocked)));
  });

  it('rejects corrupt, impossible or unsupported saved games', () => {
    const valid = createGame(89);
    for (const saved of [null, [], {}, { ...valid, version: 2 }, { ...valid, board: [2] },
      { ...valid, board: [3, ...valid.board.slice(1)] }, { ...valid, score: -1 },
      { ...valid, score: Infinity }, { ...valid, rng: -1 }, { ...valid, rng: 0x100000000 },
      { ...valid, moves: 0.5 }, { ...valid, highestTile: 0 }, { ...valid, highestTile: 1 },
      { ...valid, ended: true }, { ...valid, rescueUsed: 'no' }, { ...valid, board: Array(16).fill(0) }]) {
      expect(restoreGame(saved)).toBeNull();
    }
    const restored = restoreGame(valid)!;
    restored.board[0] = 16;
    expect(restored.board).not.toEqual(valid.board);
  });
});
