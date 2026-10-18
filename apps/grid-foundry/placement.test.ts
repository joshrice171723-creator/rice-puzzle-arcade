import { expect, it } from 'vitest';
import { canPlace, emptyBoard } from './game';
import { dragTarget } from './placement';

it('centers different shapes on the pointer without clamping invalid edge drops', () => {
  expect(dragTarget('square', 50, 50, 50)).toEqual({ row: 0, col: 0 });
  expect(dragTarget('bar3', 175, 125, 50)).toEqual({ row: 2, col: 2 });
  const edge = dragTarget('square', 399, 399, 50)!;
  expect(canPlace(emptyBoard(), 'square', edge.row, edge.col)).toBe(false);
});
it('cancels outside the board and maps consistently after board resize', () => {
  for (const [x, y] of [[-1, 50], [50, -1], [400, 50], [50, 400]]) expect(dragTarget('spark', x, y, 50)).toBeNull();
  expect(dragTarget('hook', 100, 140, 40)).toEqual(dragTarget('hook', 125, 175, 50));
});
