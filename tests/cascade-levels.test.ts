import { expect, it } from 'vitest';
import { advanceTimer, createGame, findGroup, tapGroup } from '../apps/color-cascade/game';
import { journey, levelGoal } from '../packages/game-utils/challenges';
import { dailySeed } from '../packages/game-utils/storage';

// A fast scripted player establishes reachability, not human difficulty or retention.
it.each(journey('color-cascade').targets.map((_, index) => index + 1))('Cascade level %i numeric objective is reachable within the base timer', level => {
  let state = createGame(dailySeed('color-cascade-journey', String(level)));
  for (let turn = 0; turn < 90 && !levelGoal('color-cascade', level, state).complete; turn++) {
    let best = { row: 0, col: 0, size: 0 };
    for (let row = 0; row < 7; row++) for (let col = 0; col < 7; col++) {
      const size = findGroup(state.board, row, col).length;
      if (size > best.size) best = { row, col, size };
    }
    state = advanceTimer(tapGroup(state, best.row, best.col), 1000);
  }
  expect(levelGoal('color-cascade', level, state).complete).toBe(true);
  expect(state.reviveUsed).toBe(false);
});

