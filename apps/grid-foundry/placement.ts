import { Shape, SHAPES, SIZE } from './game';

/** Match the ghost and release position to the center of the floating piece. */
export function dragTarget(shape: Shape, x: number, y: number, cellSize: number) {
  if (x < 0 || y < 0 || x >= SIZE * cellSize || y >= SIZE * cellSize) return null;
  const rows = Math.max(...SHAPES[shape].map(([r]) => r)) + 1;
  const cols = Math.max(...SHAPES[shape].map(([, c]) => c)) + 1;
  return { row: Math.floor(y / cellSize - rows / 2 + .5), col: Math.floor(x / cellSize - cols / 2 + .5) };
}
