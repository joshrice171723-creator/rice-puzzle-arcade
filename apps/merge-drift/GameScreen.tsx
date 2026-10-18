import React, { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, PanResponder, Pressable, StyleSheet, Text, View } from 'react-native';
import * as Haptics from 'expo-haptics';
import { createGame, Direction, MergeState, Movement, move, rescue, restoreGame } from './game';

type Props = { seed: number; paused: boolean; saved?: unknown; onSave: (state: unknown) => void; onEnd: () => void; rewardToken: number; haptics: boolean };
const colors = ['#a9eef0', '#6cdcdf', '#38c8d4', '#2aabc5', '#237da9', '#3964ab', '#6656b8', '#9660ba', '#ba6ca8'];

export default function Game({ seed, paused, saved, onSave, onEnd, rewardToken, haptics }: Props) {
  const [state, setState] = useState<MergeState>(() => restoreGame(saved) ?? createGame(seed));
  const [width, setWidth] = useState(300);
  const [movement, setMovement] = useState<Movement[] | null>(null);
  const [milestone, setMilestone] = useState('Slide. Combine. Find your flow.');
  const progress = useRef(new Animated.Value(1)).current;
  const current = useRef(state);
  const busy = useRef(false);
  const reducedMotion = useRef(false);
  const previousReward = useRef(rewardToken);
  const ended = useRef(false);
  const callbacks = useRef({ paused, haptics });
  callbacks.current = { paused, haptics };
  current.current = state;
  const cell = (width - 30) / 4;
  const stride = cell + 6;

  useEffect(() => {
    let mounted = true;
    void AccessibilityInfo.isReduceMotionEnabled().then(value => { if (mounted) reducedMotion.current = value; });
    const listener = AccessibilityInfo.addEventListener('reduceMotionChanged', value => { reducedMotion.current = value; });
    return () => { mounted = false; listener.remove(); progress.stopAnimation(); };
  }, [progress]);
  useEffect(() => { onSave(state); }, [state, onSave]);
  useEffect(() => {
    if (state.ended && !ended.current) { ended.current = true; onEnd(); }
    if (!state.ended) ended.current = false;
  }, [state.ended, onEnd]);
  useEffect(() => {
    if (rewardToken > previousReward.current) {
      setState(value => rescue(value));
      setMilestone('A little room to drift. Keep going.');
    }
    previousReward.current = rewardToken;
  }, [rewardToken]);

  const swipe = useRef((direction: Direction) => {});
  swipe.current = (direction: Direction) => {
    if (callbacks.current.paused || busy.current || current.current.ended) return;
    const result = move(current.current, direction);
    if (!result.changed) return;
    current.current = result.state;
    setState(result.state);
    if (result.state.highestTile >= 128 && result.state.highestTile > state.highestTile) {
      setMilestone(`${result.state.highestTile.toLocaleString()} reached. Beautifully done.`);
      AccessibilityInfo.announceForAccessibility(`${result.state.highestTile} tile milestone reached`);
    }
    if (callbacks.current.haptics) void Haptics.selectionAsync().catch(() => {});
    if (!reducedMotion.current) {
      busy.current = true;
      setMovement(result.movements);
      progress.setValue(0);
      Animated.timing(progress, { toValue: 1, duration: 155, useNativeDriver: true }).start(() => {
        busy.current = false;
        setMovement(null);
      });
    }
  };
  const responder = useRef(PanResponder.create({
    onStartShouldSetPanResponder: () => !callbacks.current.paused && !current.current.ended,
    onMoveShouldSetPanResponder: (_, gesture) => Math.max(Math.abs(gesture.dx), Math.abs(gesture.dy)) > 12,
    onPanResponderRelease: (_, gesture) => {
      if (Math.max(Math.abs(gesture.dx), Math.abs(gesture.dy)) < 24) return;
      swipe.current(Math.abs(gesture.dx) > Math.abs(gesture.dy) ? gesture.dx > 0 ? 'right' : 'left' : gesture.dy > 0 ? 'down' : 'up');
    },
  })).current;
  const tile = (value: number, key: string, position: number, animation?: Movement) => {
    const color = colors[Math.min(colors.length - 1, Math.max(0, Math.log2(value) - 1))];
    return <Animated.View key={key} accessible accessibilityLabel={`${value}, row ${Math.floor(position / 4) + 1}, column ${position % 4 + 1}`}
      style={[styles.tile, { width: cell, height: cell, left: 6 + position % 4 * stride, top: 6 + Math.floor(position / 4) * stride, backgroundColor: color }, animation && {
        transform: [
          { translateX: progress.interpolate({ inputRange: [0, 1], outputRange: [0, (animation.to % 4 - animation.from % 4) * stride] }) },
          { translateY: progress.interpolate({ inputRange: [0, 1], outputRange: [0, (Math.floor(animation.to / 4) - Math.floor(animation.from / 4)) * stride] }) },
          { scale: progress.interpolate({ inputRange: [0, 0.8, 1], outputRange: [1, 1, animation.merged ? 1.07 : 1] }) },
        ],
      }]}>
      <Text adjustsFontSizeToFit numberOfLines={1} style={[styles.number, { fontSize: cell * (value >= 10000 ? 0.27 : 0.38), color: value <= 16 ? '#083344' : '#f4feff' }]}>{value}</Text>
    </Animated.View>;
  };
  return <View style={styles.container}>
    <View style={styles.stats}>
      <View><Text style={styles.label}>CURRENT FLOW</Text><Text style={styles.score}>{state.score.toLocaleString()}</Text></View>
      <View style={styles.best}><Text style={styles.label}>HIGHEST TILE</Text><Text style={styles.highest}>{state.highestTile.toLocaleString()}</Text></View>
    </View>
    <Text accessibilityLiveRegion="polite" style={styles.milestone}>{milestone}</Text>
    <View testID="merge-board" onLayout={event => setWidth(event.nativeEvent.layout.width)} {...responder.panHandlers} style={[styles.board, { aspectRatio: 1 }]}>
      {Array.from({ length: 16 }, (_, index) => <View key={index} style={[styles.empty, { width: cell, height: cell, left: 6 + index % 4 * stride, top: 6 + Math.floor(index / 4) * stride }]} />)}
      {movement ? movement.map((item, index) => tile(item.value, `move-${index}`, item.from, item)) : state.board.map((value, index) => value > 0 && tile(value, `${index}-${value}`, index))}
      {paused && <View style={styles.cover}><Text style={styles.coverTitle}>Flow paused</Text></View>}
    </View>
    <Text style={styles.hint}>{state.ended ? 'No moves remain. Your next flow awaits.' : 'Swipe anywhere on the board to combine equal numbers.'}</Text>
    <View style={styles.controls}>
      {(['left', 'up', 'down', 'right'] as Direction[]).map((direction, index) => <Pressable key={direction} accessibilityRole="button" accessibilityLabel={`Move ${direction}`} disabled={paused || state.ended} onPress={() => swipe.current(direction)} style={({ pressed }) => [styles.control, pressed && styles.pressed, (paused || state.ended) && styles.disabled]}><Text style={styles.arrow}>{['←', '↑', '↓', '→'][index]}</Text></Pressable>)}
    </View>
    <Text style={styles.footer}>{state.moves} MOVES · ONE SWIPE AT A TIME</Text>
  </View>;
}

const styles = StyleSheet.create({
  container: { width: '100%', maxWidth: 470, alignSelf: 'center', gap: 14 },
  stats: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  label: { color: '#93c6d0', fontSize: 11, fontWeight: '700', letterSpacing: 1.4 },
  score: { color: '#f0fdff', fontSize: 38, fontWeight: '800', fontVariant: ['tabular-nums'] },
  best: { alignItems: 'flex-end' },
  highest: { color: '#6ee7ee', fontSize: 28, fontWeight: '700', fontVariant: ['tabular-nums'] },
  milestone: { color: '#b9edf0', fontSize: 13, minHeight: 20 },
  board: { width: '100%', backgroundColor: '#0a233b', borderRadius: 18, borderWidth: 1, borderColor: '#28516b', overflow: 'hidden' },
  empty: { position: 'absolute', backgroundColor: '#14324a', borderRadius: 12 },
  tile: { position: 'absolute', justifyContent: 'center', alignItems: 'center', borderRadius: 12, borderWidth: 1, borderColor: '#ffffff50' },
  number: { fontWeight: '800', fontVariant: ['tabular-nums'], paddingHorizontal: 3 },
  cover: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: '#071829ed', alignItems: 'center', justifyContent: 'center' },
  coverTitle: { color: '#adf3f4', fontSize: 25, fontWeight: '700' },
  hint: { color: '#a5c5d3', textAlign: 'center', fontSize: 13, lineHeight: 20 },
  controls: { flexDirection: 'row', justifyContent: 'center', gap: 12 },
  control: { minWidth: 54, minHeight: 50, borderRadius: 14, borderWidth: 1, borderColor: '#366174', alignItems: 'center', justifyContent: 'center', backgroundColor: '#123247' },
  pressed: { backgroundColor: '#24536a' },
  disabled: { opacity: 0.35 },
  arrow: { color: '#b3f6f5', fontSize: 26 },
  footer: { color: '#739eae', fontSize: 10, letterSpacing: 1.7, textAlign: 'center' },
});
