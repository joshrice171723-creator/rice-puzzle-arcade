import { HEIGHT, State, WALLS, WIDTH, ZONES, wave } from './game';

function disk(c: CanvasRenderingContext2D, x: number, y: number, r: number, color: string) {
  c.fillStyle = color; c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.fill();
}
function rounded(c: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  c.beginPath(); c.moveTo(x + r, y); c.lineTo(x + w - r, y); c.quadraticCurveTo(x + w, y, x + w, y + r);
  c.lineTo(x + w, y + h - r); c.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  c.lineTo(x + r, y + h); c.quadraticCurveTo(x, y + h, x, y + h - r); c.lineTo(x, y + r); c.quadraticCurveTo(x, y, x + r, y); c.closePath();
}
export function makeFloor() {
  const floor = document.createElement('canvas'); floor.width = WIDTH; floor.height = HEIGHT;
  const c = floor.getContext('2d')!;
  c.fillStyle = '#101b20'; c.fillRect(0, 0, WIDTH, HEIGHT);
  for (let y = 16; y < HEIGHT - 16; y += 32) for (let x = 16; x < WIDTH - 16; x += 32) {
    c.fillStyle = ((x * 7 + y * 11) % 13 < 6) ? '#1b2b30' : '#1e2f33'; c.fillRect(x + 1, y + 1, 30, 30);
    c.fillStyle = '#293b3c'; c.fillRect(x + 3, y + 3, 2, 2);
  }
  c.strokeStyle = '#4a5a51'; c.lineWidth = 4; c.strokeRect(14, 14, WIDTH - 28, HEIGHT - 28);
  c.strokeStyle = '#293c3d'; c.lineWidth = 7; c.strokeRect(6, 6, WIDTH - 12, HEIGHT - 12);
  for (const b of WALLS) {
    c.fillStyle = '#08131690'; c.fillRect(b.x + 5, b.y + 8, b.w, b.h);
    c.fillStyle = '#435451'; c.fillRect(b.x, b.y, b.w, b.h);
    c.fillStyle = '#617169'; c.fillRect(b.x, b.y, b.w, 4);
    c.fillStyle = '#2e4140'; c.fillRect(b.x + 4, b.y + 7, b.w - 8, b.h - 11);
    for (let x = b.x + 7; x < b.x + b.w - 5; x += 12) { c.fillStyle = '#d6ab57'; c.fillRect(x, b.y + b.h - 5, 6, 3); }
  }
  for (const x of [36, WIDTH - 36]) for (const y of [36, HEIGHT - 36]) {
    const g = c.createRadialGradient(x, y, 0, x, y, 58); g.addColorStop(0, '#ffcc631c'); g.addColorStop(1, '#ffcc6300');
    c.fillStyle = g; c.fillRect(x - 58, y - 58, 116, 116); c.fillStyle = '#ffcf77'; c.fillRect(x - 5, y - 2, 10, 4);
  }
  c.fillStyle = '#7e98952e'; c.font = 'bold 11px monospace'; c.fillText('NORTH / 04', 160, 48); c.fillText('EXTRACTION', 164, 520);
  return floor;
}
export function draw(c: CanvasRenderingContext2D, s: State, floor: HTMLCanvasElement) {
  c.drawImage(floor, 0, 0);
  const zone = ZONES[wave(s) - 1], breathe = Math.sin(s.time * 2) * .15 + .85;
  disk(c, zone.x, zone.y, 43, `rgba(91,207,169,${.07 * breathe})`);
  c.strokeStyle = '#71d9b260'; c.lineWidth = 1.5; c.setLineDash([5, 6]); c.beginPath(); c.arc(zone.x, zone.y, 43, s.time * .08, Math.PI * 2 + s.time * .08); c.stroke(); c.setLineDash([]);
  c.fillStyle = '#74d2ad66'; c.fillRect(zone.x - 2, zone.y - 8, 4, 16); c.fillRect(zone.x - 8, zone.y - 2, 16, 4);
  for (const p of s.pickups) if (p.active) {
    disk(c, p.x, p.y, 9, '#f5c96716'); c.fillStyle = '#edc46b'; c.save(); c.translate(p.x, p.y); c.rotate(Math.PI / 4); c.fillRect(-3, -3, 6, 6); c.restore();
  }
  for (const e of s.enemies) if (e.active) {
    const angle = Math.atan2(s.player.y - e.y, s.player.x - e.x), runner = e.kind === 'runner';
    disk(c, e.x + 2, e.y + 5, 11, '#00000045'); c.save(); c.translate(e.x, e.y); c.rotate(angle);
    const stride = Math.sin(s.time * (runner ? 17 : 8) + e.id) * 3;
    c.fillStyle = '#23312d'; c.fillRect(-8, -7 + stride, 9, 5); c.fillRect(-8, 3 - stride, 9, 5);
    c.fillStyle = e.flash > 0 ? '#fff7d0' : runner ? '#be7450' : '#64806b';
    rounded(c, -7, -9, 13, 18, 4); c.fill();
    disk(c, 5, 0, runner ? 6 : 7, e.flash > 0 ? '#fff7d0' : runner ? '#e9a06b' : '#a5b590');
    c.fillStyle = '#eddf7d'; c.fillRect(8, -4, 2, 3); c.fillRect(8, 1, 2, 3); c.restore();
    if (e.hp < e.maxHp) { c.fillStyle = '#0009'; c.fillRect(e.x - 9, e.y - 16, 18, 2); c.fillStyle = '#d68a67'; c.fillRect(e.x - 9, e.y - 16, 18 * Math.max(0, e.hp / e.maxHp), 2); }
  }
  for (const b of s.shots) if (b.active) {
    c.strokeStyle = '#efc75c'; c.lineWidth = 2.5; c.beginPath(); c.moveTo(b.x - b.vx * .018, b.y - b.vy * .018); c.lineTo(b.x, b.y); c.stroke(); disk(c, b.x, b.y, 2, '#ffefb6');
  }
  const p = s.player;
  if (s.pulse > 0) { c.strokeStyle = `rgba(140,230,222,${s.pulse})`; c.lineWidth = 5; c.beginPath(); c.arc(p.x, p.y, (1 - s.pulse / .7) * 155, 0, Math.PI * 2); c.stroke(); }
  disk(c, p.x + 2, p.y + 5, 13, '#0006');
  if (p.invincible > 0) { c.strokeStyle = '#b1efe1aa'; c.lineWidth = 2; c.beginPath(); c.arc(p.x, p.y, 17, 0, Math.PI * 2); c.stroke(); }
  c.save(); c.translate(p.x, p.y); c.rotate(p.angle);
  c.fillStyle = '#1b343e'; c.fillRect(-9, -8, 10, 6); c.fillRect(-9, 3, 10, 6);
  c.fillStyle = '#d5ab60'; rounded(c, -7, -11, 14, 22, 5); c.fill();
  c.fillStyle = '#735b3e'; c.fillRect(-8, -6, 5, 12); disk(c, 3, 0, 8, '#e5d7ab');
  c.fillStyle = '#3b919c'; c.fillRect(6, -6, 4, 12); c.fillStyle = '#9ee3e6'; c.fillRect(8, -4, 2, 8);
  c.fillStyle = '#14292f'; c.fillRect(4, 6, 16, 5); c.fillStyle = '#c5b286'; c.fillRect(17, 6, 4, 5); c.restore();
  if (p.hp < p.maxHp * .3) { c.strokeStyle = '#df775a66'; c.lineWidth = 8; c.strokeRect(4, 4, WIDTH - 8, HEIGHT - 8); }
}
