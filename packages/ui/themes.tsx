import React, { createContext, useContext } from 'react';

export type ThemeId = 'day' | 'bloom' | 'night';
export type Theme = { id: ThemeId; name: string; icon: string; description: string; background: string; surface: string; board: string; empty: string; ink: string; muted: string; accent: string; tile: string; edge: string };
const palettes = {
  workshop: ['#fff5e5', '#fffdf7', '#dbb98a', '#f1ddbc', '#493124', '#765d48', '#945128', '#ce8b48', '#bc986b'],
  ocean: ['#edfafa', '#ffffff', '#9bcfd5', '#d8edef', '#173f50', '#476b78', '#176c80', '#52b8c4', '#83b7c1'],
  garden: ['#fff1f5', '#fffafb', '#dfb8cf', '#f3dce7', '#542d49', '#80576f', '#9b3d73', '#d980ac', '#c699b5'],
  forest: ['#f1f6e8', '#fbfff5', '#b2c79e', '#e0eace', '#30452e', '#5b7052', '#486b34', '#87a86a', '#94ad80'],
  sunset: ['#fff0e9', '#fffbf6', '#e5b5a7', '#f8dace', '#56372f', '#825c50', '#9f4f3c', '#df9177', '#c89787'],
  night: ['#182638', '#24364b', '#0f1c2d', '#2c4055', '#f4f5ee', '#bac9d7', '#a9dccf', '#80bbae', '#506980'],
};
type Palette = keyof typeof palettes;
const identities: Record<string, { icon: string; greeting: string; themes: [string, Palette][] }> = {
  'grid-foundry': { icon: '🧸', greeting: 'A little space. A lovely fit.', themes: [['Cozy workshop', 'workshop'], ['Woodland cabin', 'forest'], ['Midnight maker', 'night']] },
  'merge-drift': { icon: '🐳', greeting: 'Little numbers. Ocean-sized possibilities.', themes: [['Ocean breeze', 'ocean'], ['Coral sunset', 'sunset'], ['Moonlit tide', 'night']] },
  'color-cascade': { icon: '🌷', greeting: 'Pick a bunch of happy colors.', themes: [['Candy garden', 'garden'], ['Meadow picnic', 'forest'], ['Starlight garden', 'night']] },
};
export function gameThemes(slug: string): { greeting: string; themes: Theme[] } {
  const identity = identities[slug] ?? identities['grid-foundry'];
  return { greeting: identity.greeting, themes: identity.themes.map(([name, palette], index) => {
    const [background, surface, board, empty, ink, muted, accent, tile, edge] = palettes[palette];
    return { id: (['day', 'bloom', 'night'] as ThemeId[])[index], name, icon: identity.icon, description: index === 2 ? 'A softer glow for evening play' : index === 1 ? 'A fresh change of scenery' : 'Your happy little puzzle place', background, surface, board, empty, ink, muted, accent, tile, edge };
  }) };
}
export const ThemeContext = createContext({ theme: gameThemes('grid-foundry').themes[0], softTiles: true });
export const useGameTheme = () => useContext(ThemeContext);
