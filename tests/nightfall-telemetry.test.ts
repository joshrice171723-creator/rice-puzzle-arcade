import { describe, it, expect } from 'vitest';
import { createGame } from '../apps/nightfall-arena/game';
import { createRunObserver } from '../apps/nightfall-arena/telemetry';
describe('Nightfall tracking', () => {
  it('records real outcomes once without mutating gameplay', () => {
    const events: { name: string; fields: unknown }[] = [];
    const tracker = createRunObserver((name,fields) => events.push({name,fields}));
    const state = createGame(42);
    tracker.begin('run-123456',state);
    state.time=61; const before=JSON.stringify(state); tracker.observe(state);
    expect(JSON.stringify(state)).toBe(before);
    state.phase='lost'; tracker.observe(state); tracker.observe(state);
    expect(events.map(e=>e.name)).toEqual(['run_start','wave_start','run_progress','run_end']);
    expect(events.at(-1)?.fields).toMatchObject({outcome:'loss',run:'run-123456'});
  });
  it('resumes without inventing a start or old progress', () => {
    const names: string[]=[]; const tracker=createRunObserver(name=>names.push(name));
    const state=createGame(); state.time=100;
    tracker.begin('restored-run',state,true); tracker.observe(state); tracker.upgrade(state,'health'); tracker.exit(state);
    expect(names).toEqual(['run_resume','upgrade_selected','run_exit']);
  });
});
