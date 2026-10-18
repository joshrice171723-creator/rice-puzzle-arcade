import React, { createContext, useContext } from 'react';

export type Theme = { name: string; greeting: string; background: string; surface: string; board: string; empty: string; ink: string; muted: string; accent: string; tile: string; edge: string };
const palettes = {
  workshop: ['#fff5e5', '#fffdf7', '#dbb98a', '#f1ddbc', '#493124', '#765d48', '#945128', '#ce8b48', '#bc986b'],
  ocean: ['#edfafa', '#ffffff', '#9bcfd5', '#d8edef', '#173f50', '#476b78', '#176c80', '#52b8c4', '#83b7c1'],
  garden: ['#fff1f5', '#fffafb', '#dfb8cf', '#f3dce7', '#542d49', '#80576f', '#9b3d73', '#d980ac', '#c699b5'],
};
type Palette = keyof typeof palettes;
const identities: Record<string, { name: string; greeting: string; palette: Palette }> = {
  'grid-foundry': { name: 'Cozy workshop', greeting: 'A little space. A lovely fit.', palette: 'workshop' },
  'merge-drift': { name: 'Ocean breeze', greeting: 'Little numbers. Ocean-sized possibilities.', palette: 'ocean' },
  'color-cascade': { name: 'Candy garden', greeting: 'Pick a bunch of happy colors.', palette: 'garden' },
};
export function gameTheme(slug: string): Theme {
  const { name, greeting, palette } = identities[slug] ?? identities['grid-foundry'];
  const [background, surface, board, empty, ink, muted, accent, tile, edge] = palettes[palette];
  return { name, greeting, background, surface, board, empty, ink, muted, accent, tile, edge };
}
export const ThemeContext = createContext({ theme: gameTheme('grid-foundry'), softTiles: true });
export const useGameTheme = () => useContext(ThemeContext);
