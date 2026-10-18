// Original AI-composed scores, synthesized from oscillators; no sampled recordings.
import { writeFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const rate = 22050;
const scores = [
  { name: 'grid-foundry', bpm: 96, root: 60, tone: .32, melody: [7,12,14,12,7,null,4,7,9,7,4,null,2,4,7,null] },
  { name: 'merge-drift', bpm: 80, root: 62, tone: .16, melody: [12,null,7,9,14,null,12,7,9,null,4,7,2,null,7,null] },
  { name: 'color-cascade', bpm: 104, root: 65, tone: .45, melody: [12,7,9,null,7,4,7,null,9,12,14,12,7,null,4,null] },
];
for (const score of scores) {
  const beat = 60 / score.bpm, length = Math.round(64 * beat * rate);
  const samples = new Float64Array(length);
  function note(midi, start, duration, gain, bright = score.tone) {
    const frequency = 440 * 2 ** ((midi - 69) / 12);
    const count = Math.round(duration * rate);
    for (let i = 0; i < count; i++) {
      const t = i / rate, phase = 2 * Math.PI * frequency * t;
      const envelope = Math.min(1, t / .015) * Math.exp(-3 * t / duration) * Math.min(1, (duration - t) / .08);
      const value = (Math.sin(phase) + bright * Math.sin(phase * 2) + .08 * Math.sin(phase * 3)) * envelope * gain;
      const index = (Math.round(start * rate) + i) % length;
      samples[index] += value;
      // Circular delay preserves the tail across the loop boundary.
      samples[(index + Math.round(beat * .75 * rate)) % length] += value * .13;
    }
  }
  const chords = [[0,4,7], [9,12,16], [5,9,12], [7,11,14]];
  for (let bar = 0; bar < 16; bar++) {
    const chord = chords[bar % 4], start = bar * 4 * beat;
    note(score.root + chord[0] - 24, start, beat * 3.8, .12, .1);
    chord.forEach((n, i) => note(score.root + n, start + i * beat * .5, beat * 2.4, .055, .1));
    for (let step = 0; step < 4; step++) {
      const n = score.melody[(bar * 4 + step) % score.melody.length];
      if (n !== null) note(score.root + n + (bar >= 8 && step === 2 ? 12 : 0), start + step * beat, beat * 1.3, .15);
    }
  }
  const peak = samples.reduce((max, sample) => Math.max(max, Math.abs(sample)), 0);
  assert(peak > .05 && Number.isFinite(peak));
  const wav = Buffer.alloc(44 + length * 2);
  wav.write('RIFF'); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(rate, 24); wav.writeUInt32LE(rate * 2, 28); wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
  wav.write('data', 36); wav.writeUInt32LE(length * 2, 40);
  for (let i = 0; i < length; i++) wav.writeInt16LE(Math.round(samples[i] / peak * 20000), 44 + i * 2);
  writeFileSync(`packages/ui/assets/${score.name}-music.wav`, wav);
  console.log(`${score.name}: ${(length / rate).toFixed(1)} seconds, ${(wav.length / 1024).toFixed(0)} KB`);
}
