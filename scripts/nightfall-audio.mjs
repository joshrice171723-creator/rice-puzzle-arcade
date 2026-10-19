// Original Nightfall score and interface sounds. No samples or borrowed melodies.
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const output = fileURLToPath(new URL('../apps/nightfall-godot/assets/audio/', import.meta.url));
mkdirSync(output, { recursive: true });
const rate = 22050;

function save(name, samples) {
  const peak = samples.reduce((value, sample) => Math.max(value, Math.abs(sample)), 0);
  assert(Number.isFinite(peak) && peak > 0);
  const wav = Buffer.alloc(44 + samples.length * 2);
  wav.write('RIFF'); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(rate, 24); wav.writeUInt32LE(rate * 2, 28);
  wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
  wav.write('data', 36); wav.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) wav.writeInt16LE(Math.round(samples[i] / peak * 14000), 44 + i * 2);
  writeFileSync(`${output}/${name}.wav`, wav);
  console.log(`${name}: ${(samples.length / rate).toFixed(2)}s, peak ${peak.toFixed(3)}`);
}

function note(samples, midi, start, duration, gain, brightness = .12, circular = false) {
  const frequency = 440 * 2 ** ((midi - 69) / 12);
  const count = Math.round(duration * rate);
  for (let i = 0; i < count; i++) {
    const t = i / rate;
    const envelope = Math.min(1, t / .025) * Math.exp(-2.8 * t / duration) * Math.max(0, Math.min(1, (duration - t) / .1));
    const phase = 2 * Math.PI * frequency * t;
    const value = (Math.sin(phase) + brightness * Math.sin(phase * 2) + .04 * Math.sin(phase * 3)) * envelope * gain;
    const index = Math.round(start * rate) + i;
    if (circular || index < samples.length) samples[index % samples.length] += value;
    const echo = index + Math.round(.375 * rate);
    if (circular) samples[echo % samples.length] += value * .12;
  }
}

const melody = [12, null, 7, 10, 14, 12, null, 7, 8, null, 10, 7, 5, 3, null, 7];
const chords = [[0, 3, 7], [-4, 0, 3], [-2, 2, 5], [-5, -2, 2]];
for (const [name, bpm, active] of [['haven', 76, false], ['outskirts', 88, true]]) {
  const beat = 60 / bpm;
  const samples = new Float64Array(Math.round(64 * beat * rate));
  for (let bar = 0; bar < 16; bar++) {
    const chord = chords[bar % 4], start = bar * 4 * beat;
    note(samples, 50 + chord[0] - 12, start, beat * 3.8, .12, .05, true);
    chord.forEach((pitch, index) => note(samples, 50 + pitch, start + index * beat * .5, beat * 3, .045, .07, true));
    for (let step = 0; step < 4; step++) {
      const pitch = melody[(bar * 4 + step) % melody.length];
      if (pitch !== null) note(samples, 50 + pitch + (bar >= 8 ? 12 : 0), start + step * beat, beat * 1.6, .09, .15, true);
      if (active) note(samples, 26 + chord[0], start + step * beat, .22, .07, .5, true);
    }
  }
  save(name, samples);
}

const cues = {
  pickup: [[84, 0, .14, .18]],
  hurt: [[38, 0, .18, .3], [37, .04, .16, .15]],
  dodge: [[55, 0, .08, .1], [67, .035, .09, .1]],
  build: [[48, 0, .13, .2], [60, .08, .16, .18]],
  shrine: [[62, 0, .5, .12], [69, .13, .55, .12], [74, .26, .6, .13]],
  upgrade: [[62, 0, .28, .15], [65, .10, .3, .15], [69, .20, .4, .15]],
  victory: [[62, 0, .6, .13], [65, .14, .6, .13], [69, .28, .8, .13], [74, .46, 1.0, .15]],
  defeat: [[50, 0, .7, .15], [48, .22, .75, .13], [45, .45, 1.0, .13]],
  boss: [[26, 0, 1.0, .2], [38, .16, 1.2, .14], [41, .35, .8, .08]],
};
for (const [name, notes] of Object.entries(cues)) {
  const samples = new Float64Array(Math.round(Math.max(...notes.map(([, start, duration]) => start + duration)) * rate) + 2);
  for (const [pitch, start, duration, gain] of notes) note(samples, pitch, start, duration, gain, .22);
  save(name, samples);
}
