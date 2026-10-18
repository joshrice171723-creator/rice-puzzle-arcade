import { describe, expect, it } from 'vitest';
import { boostAvailable } from './boost';
import { newGame, revive, hasMove } from '../../apps/grid-foundry/game';
import { createGame as mergeGame, rescue } from '../../apps/merge-drift/game';
import { createGame as cascadeGame, extendTime } from '../../apps/color-cascade/game';

describe('optional pressure-point boosts', () => {
  it('offers Grid help from 40 occupied cells and keeps the score unchanged', () => {
    const state = newGame(123);
    state.board = Array.from({ length: 8 }, () => [1, 1, 1, 1, 1, 0, 0, 0]);
    expect(boostAvailable('grid-foundry', state)).toBe(true);
    const helped = revive(state, true);
    expect(helped.board.flat().filter(Boolean)).toHaveLength(30);
    expect(helped.score).toBe(state.score);
    expect(hasMove(helped.board, helped.tray)).toBe(true);
    expect(revive({ ...helped, ended: true }, true).revived).toBe(true);
    expect(revive(helped, true)).toBe(helped);
    state.board[0][0] = 0;
    expect(boostAvailable('grid-foundry', state)).toBe(false);
    expect(revive(state, true)).toBe(state);
  });

  it('removes the two smallest Merge tiles only with three or fewer spaces', () => {
    const state = { ...mergeGame(123), board: [2, 4, 8, 16, 32, 64, 128, 2, 4, 8, 16, 32, 64, 0, 0, 0], highestTile: 128 };
    expect(boostAvailable('merge-drift', state)).toBe(true);
    const helped = rescue(state, true);
    expect(helped.board.filter(value => value === 0)).toHaveLength(5);
    expect(helped.board[0]).toBe(0);
    expect(helped.board[7]).toBe(0);
    expect(helped.score).toBe(state.score);
    expect(rescue(helped, true)).toBe(helped);
    expect(rescue({ ...helped, ended: true }, true).board).toEqual(helped.board);
    state.board[0] = 0;
    expect(boostAvailable('merge-drift', state)).toBe(false);
  });

  it('adds rather than replaces Cascade time and shares the once-per-run continue', () => {
    const state = { ...cascadeGame(123), remainingMs: 15_000 };
    expect(boostAvailable('color-cascade', { ...state, remainingMs: 15_001 })).toBe(false);
    expect(boostAvailable('color-cascade', state)).toBe(true);
    const helped = extendTime(state, true);
    expect(helped.remainingMs).toBe(35_000);
    expect(helped.score).toBe(state.score);
    expect(extendTime(helped, true)).toBe(helped);
    expect(extendTime({ ...helped, remainingMs: 0 }, true).remainingMs).toBe(0);
    expect(boostAvailable('color-cascade', { ...state, remainingMs: 0 })).toBe(false);
  });

  it('does not offer boosts at the start or after a boost is used', () => {
    expect(boostAvailable('grid-foundry', newGame(1))).toBe(false);
    expect(boostAvailable('merge-drift', mergeGame(1))).toBe(false);
    expect(boostAvailable('color-cascade', cascadeGame(1))).toBe(false);
    expect(boostAvailable('grid-foundry', { board: Array(8).fill(Array(8).fill(1)), revived: true })).toBe(false);
    expect(boostAvailable('merge-drift', { board: Array(16).fill(2), rescueUsed: true })).toBe(false);
    expect(boostAvailable('color-cascade', { remainingMs: 1000, reviveUsed: true })).toBe(false);
  });
});
