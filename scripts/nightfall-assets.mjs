import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
const svg = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="210" fill="#14262c"/><path d="M240 760V264h124l296 310V264h124v496H660L364 450v310z" fill="#e9bd6c"/><path d="M450 165h124v60H450zM450 799h124v60H450z" fill="#80b9a8"/></svg>`);
await Promise.all(['icon', 'adaptive-icon', 'splash'].map(name => sharp(svg).png().toFile(fileURLToPath(new URL(`../apps/nightfall-arena/assets/${name}.png`, import.meta.url)))));
