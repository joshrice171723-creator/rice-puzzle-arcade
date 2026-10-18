import { expect, it } from 'vitest';
import * as grid from '../apps/grid-foundry/game';
import * as merge from '../apps/merge-drift/game';
import * as cascade from '../apps/color-cascade/game';

it('preserves Grid rounds across repeated placements and save/relaunch', () => {
  for (let seed = 1; seed <= 20; seed++) {
    let state = grid.newGame(seed);
    for (let step = 0; step < 100 && !state.ended; step++) {
      const choices = state.tray.flatMap((shape, index) => shape === null ? [] :
        Array.from({ length: 64 }, (_, cell) => ({ index, row: Math.floor(cell / 8), col: cell % 8 }))
          .filter(({ row, col }) => grid.canPlace(state.board, shape, row, col)));
      expect(choices.length).toBeGreaterThan(0);
      const choice = choices[(seed * 17 + step * 7) % choices.length];
      const next = grid.place(state, choice.index, choice.row, choice.col).state;
      expect(next.score).toBeGreaterThan(state.score);
      expect(grid.restoreGame(JSON.parse(JSON.stringify(next)))).toEqual(next);
      state = next;
    }
  }
});

it('preserves Merge rounds across long swipe sequences and save/relaunch', () => {
  const directions: merge.Direction[] = ['left', 'down', 'right', 'up'];
  for (let seed = 1; seed <= 30; seed++) {
    let state = merge.createGame(seed);
    for (let step = 0; step < 200 && !state.ended; step++) {
      const next = merge.move(state, directions[(seed + step) % 4]).state;
      expect(next.score).toBeGreaterThanOrEqual(state.score);
      expect(merge.restoreGame(JSON.parse(JSON.stringify(next)))).toEqual(next);
      state = next;
    }
  }
});

it('keeps Cascade playable and resumable until foreground time expires', () => {
  for (let seed = 1; seed <= 20; seed++) {
    let state = cascade.createGame(seed);
    for (let step = 0; step < 90; step++) {
      const cell = Array.from({ length: 49 }, (_, index) => index)
        .find(index => cascade.findGroup(state.board, Math.floor(index / 7), index % 7).length >= 3)!;
      const next = cascade.advanceTimer(cascade.tapGroup(state, Math.floor(cell / 7), cell % 7), 1000);
      expect(next.score).toBeGreaterThan(state.score);
      expect(cascade.hasMove(next.board)).toBe(true);
      expect(cascade.restoreGame(JSON.parse(JSON.stringify(next)))).toEqual(next);
      state = next;
    }
    expect(state.remainingMs).toBe(0);
    expect(cascade.tapGroup(state, 0, 0)).toBe(state);
  }
});
