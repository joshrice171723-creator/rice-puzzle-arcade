import { expect, it } from 'vitest';
import { scoreGoal } from './progress';

it('offers real score goals and advances only after earned progress', () => {
  expect(scoreGoal(0, 0)).toEqual({ target: 500, fraction: 0, label: 'Next milestone' });
  expect(scoreGoal(260, 260)).toEqual({ target: 270, fraction: 260 / 270, label: 'Beat your best' });
  expect(scoreGoal(280, 260).target).toBe(500);
  expect(scoreGoal(500, 260).target).toBe(1000);
});
