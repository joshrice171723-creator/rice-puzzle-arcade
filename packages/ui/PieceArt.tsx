import React from 'react';
import { Image, StyleSheet, View } from 'react-native';

const wood = require('./assets/wood-piece.png');
const glass = require('./assets/sea-piece.png');
const candy = require('./assets/candy-pieces.png');
// Source-pixel frames exclude neighboring sweets and the atlas's transparent margins.
const candyFrames = [[6, 436], [454, 430], [896, 406], [1314, 438], [1764, 402]];

/** Decorative sprites never intercept the board's touch or accessibility targets. */
export function PieceArt({ kind, color = 0 }: { kind: 'wood' | 'glass' | 'candy'; color?: number }) {
  const [x, width] = candyFrames[color] ?? candyFrames[0];
  return <View pointerEvents="none" accessible={false} style={[StyleSheet.absoluteFill, { overflow: 'hidden' }]}>
    {kind === 'candy' ? <Image accessible={false} source={candy} resizeMode="stretch" style={{ position: 'absolute', width: `${2172 / width * 100}%`, height: `${724 / 470 * 100}%`, top: `${-110 / 470 * 100}%`, left: `${-x / width * 100}%` }} /> :
      <Image accessible={false} source={kind === 'wood' ? wood : glass} resizeMode="stretch" style={{ width: '100%', height: '100%' }} />}
  </View>;
}
