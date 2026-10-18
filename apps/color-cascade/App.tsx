import React from 'react';
import Game from './GameScreen';
import GameShell from '../../packages/ui/GameShell';
export default function App() {
  return <GameShell slug="color-cascade" title="Color Cascade" subtitle="Find your rhythm in a rush of color." accent="#fae38a" background="#171c35" Game={Game}
    tutorial={['Tap a group of at least three matching symbols connected along their sides.', 'Bigger groups score much more. New symbols fall in from above.', 'You have 90 seconds of active play. Pause anytime; shuffles are always free.']}
    rewardDescription="Watch an optional video to add 20 seconds to this round. Once per run." />;
}

