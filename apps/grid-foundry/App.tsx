import React from 'react';
import Game from './GameScreen';
import GameShell from '../../packages/ui/GameShell';
export default function App() {
  return <GameShell slug="grid-foundry" title="Grid Foundry" subtitle="Make room for your next idea." accent="#efa76c" background="#192127" Game={Game}
    tutorial={['Drag a shape onto the 8 × 8 board. Or tap a shape, then a board square.', 'Fill a row or column to clear it. Clear several at once for a bonus.', 'Use all three shapes to get a new tray. The run ends when none fit.']}
    rewardDescription="Watch an optional video to clear the two fullest rows and get a fresh playable tray. Once per run." />;
}

