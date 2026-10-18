import React from 'react';
import Game from './GameScreen';
import GameShell from '../../packages/ui/GameShell';
export default function App() {
  return <GameShell slug="merge-drift" title="Merge Drift" subtitle="Small moves. Bigger possibilities." accent="#6ce6ed" background="#081e30" Game={Game}
    tutorial={['Swipe to slide every tile. Arrow buttons work too.', 'Equal numbers combine once per swipe: 2 + 2 becomes 4.', 'A new tile arrives after each successful move. Keep a little room to drift.']}
    rewardDescription="Watch an optional video to remove the two smallest tiles and keep playing. Once per run." />;
}

