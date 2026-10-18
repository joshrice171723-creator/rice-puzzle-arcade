import type { Fields } from '../../packages/analytics/client';
import { State, wave } from './game';

/** Observes outcomes without changing simulation state or random numbers. */
export function createRunObserver(emit: (name: string, fields: Fields) => void) {
  let run = '', ended = false, lastProgress = 0, lastWave = 1;
  const fields = (state: State): Fields => ({ run, mode: 'normal', score: state.score, seconds: Math.floor(state.time), wave: wave(state) });
  return {
    begin(id: string, state: State, resume = false) {
      run = id; ended = false; lastProgress = state.time; lastWave = wave(state);
      emit(resume ? 'run_resume' : 'run_start', fields(state));
    },
    observe(state: State) {
      if (!run || ended) return;
      if (wave(state) !== lastWave) { lastWave = wave(state); emit('wave_start', fields(state)); }
      if (state.time - lastProgress >= 15) { lastProgress = state.time; emit('run_progress', fields(state)); }
      if (state.phase === 'won' || state.phase === 'lost') {
        ended = true; emit('run_end', { ...fields(state), outcome: state.phase === 'won' ? 'win' : 'loss', reason: state.phase === 'won' ? 'survived' : 'health' });
      }
    },
    exit(state: State) { if (run && !ended) emit('run_exit', { ...fields(state), reason: 'home' }); },
    upgrade(state: State, upgrade: string) { if (run) emit('upgrade_selected', { ...fields(state), upgrade }); },
  };
}
