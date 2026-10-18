import sharp from 'sharp';
import { mkdir, writeFile } from 'node:fs/promises';
const items = [
  ['grid-foundry', '#192127', '#efa76c', '<rect x="270" y="270" width="210" height="210" rx="28"/><rect x="510" y="270" width="210" height="210" rx="28"/><rect x="270" y="510" width="210" height="210" rx="28"/>'],
  ['merge-drift', '#081e30', '#6ce6ed', '<rect x="250" y="250" width="524" height="524" rx="120"/><text x="512" y="640" text-anchor="middle" font-family="Arial" font-size="360" font-weight="bold" fill="#081e30">8</text>'],
  ['color-cascade', '#171c35', '#fae38a', '<path d="M512 230L794 512L512 794L230 512Z"/><circle cx="512" cy="512" r="120" fill="#e66d9e"/>']
];
for (const [slug, bg, accent, shape] of items) {
  const path = `apps/${slug}/assets`; await mkdir(path, { recursive: true });
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"><rect width="1024" height="1024" rx="180" fill="${bg}"/><g fill="${accent}">${shape}</g></svg>`;
  await writeFile(`${path}/icon.svg`, svg);
  await sharp(Buffer.from(svg)).png().toFile(`${path}/icon.png`);
  await sharp(Buffer.from(svg)).png().toFile(`${path}/adaptive-icon.png`);
  await sharp(Buffer.from(svg)).resize(480,480).png().toFile(`${path}/splash.png`);
}
await mkdir('packages/ui/assets', { recursive: true });
const rate = 22050, count = 3307, wav = Buffer.alloc(44 + count * 2);
wav.write('RIFF'); wav.writeUInt32LE(36 + count * 2,4); wav.write('WAVEfmt ',8); wav.writeUInt32LE(16,16); wav.writeUInt16LE(1,20); wav.writeUInt16LE(1,22); wav.writeUInt32LE(rate,24); wav.writeUInt32LE(rate*2,28); wav.writeUInt16LE(2,32); wav.writeUInt16LE(16,34); wav.write('data',36); wav.writeUInt32LE(count*2,40);
for(let i=0;i<count;i++) wav.writeInt16LE(Math.round(Math.sin(i/rate*2*Math.PI*660)*5000*(1-i/count)),44+i*2);
await writeFile('packages/ui/assets/move.wav',wav);
