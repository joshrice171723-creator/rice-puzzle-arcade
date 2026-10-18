import React, { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, AppState, Pressable, StyleSheet, Text, View } from 'react-native';
import * as Haptics from 'expo-haptics';
import { advanceTimer, createGame, extendTime, findGroup, restoreGame, tapGroup } from './game';

const symbols = [
  { glyph: '●', name: 'coral circle', color: '#ea625b' },
  { glyph: '◆', name: 'blue diamond', color: '#527edc' },
  { glyph: '▲', name: 'green triangle', color: '#299d7c' },
  { glyph: '✦', name: 'violet star', color: '#a16cd1' },
  { glyph: '■', name: 'gold square', color: '#c18a11' },
];

type Props = {
  seed: number;
  paused: boolean;
  saved?: unknown;
  onSave: (state: unknown) => void;
  onEnd: () => void;
  rewardToken: number;
  haptics: boolean;
};

export default function Game({ seed, paused, saved, onSave, onEnd, rewardToken, haptics }: Props) {
  const [state, setState] = useState(() => restoreGame(saved) ?? createGame(seed));
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  const [feedback, setFeedback] = useState('Find a matching group of 3 or more');
  const [reducedMotion, setReducedMotion] = useState(false);
  const [stride, setStride] = useState(42);
  const [drops, setDrops] = useState(() => Array.from({ length: 7 }, () => Array<number>(7).fill(0)));
  const entrance = useRef(new Animated.Value(1)).current;
  const ended = useRef(false);
  const rewardSeen = useRef(rewardToken);
  const callbacks = useRef({ onSave, onEnd });
  callbacks.current = { onSave, onEnd };
  const pausedRef = useRef(paused);
  pausedRef.current = paused;

  useEffect(() => {
    const subscription = AppState.addEventListener('change', value => setForeground(value === 'active'));
    return () => subscription.remove();
  }, []);

  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled().then(value => { if (mounted) setReducedMotion(value); }).catch(() => {});
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReducedMotion);
    return () => { mounted = false; subscription.remove(); };
  }, []);

  useEffect(() => {
    if (paused || !foreground || state.remainingMs <= 0) return;
    let previous = performance.now();
    const subscription = AppState.addEventListener('change', () => { previous = performance.now(); });
    const interval = setInterval(() => {
      const now = performance.now();
      const elapsed = Math.max(0, now - previous);
      previous = now;
      if (!pausedRef.current && AppState.currentState === 'active') setState(current => advanceTimer(current, elapsed));
    }, 100);
    return () => { clearInterval(interval); subscription.remove(); };
  }, [paused, foreground, state.remainingMs <= 0]);

  const seconds = Math.ceil(state.remainingMs / 1000);
  useEffect(() => { callbacks.current.onSave(state); }, [seconds, state.score, state.reviveUsed, state.shuffleCount, paused, foreground]);

  useEffect(() => {
    if (state.remainingMs === 0 && !ended.current) {
      ended.current = true;
      callbacks.current.onEnd();
    } else if (state.remainingMs > 0) ended.current = false;
  }, [state.remainingMs]);

  useEffect(() => {
    const incremented = rewardToken > rewardSeen.current;
    rewardSeen.current = rewardToken;
    if (!incremented) return;
    setState(current => extendTime(current));
    setFeedback('20 extra seconds. Keep the colors flowing!');
  }, [rewardToken]);

  function tap(row: number, col: number) {
    if (paused || !foreground || state.remainingMs <= 0) return;
    const next = tapGroup(state, row, col);
    if (next === state) {
      setFeedback('Match 3 or more touching symbols. Diagonals do not connect.');
      return;
    }
    const removed = findGroup(state.board, row, col);
    const fall = Array.from({ length: 7 }, () => Array<number>(7).fill(0));
    for (let c = 0; c < 7; c++) {
      const cleared = new Set(removed.filter(cell => cell.col === c).map(cell => cell.row));
      const survivors = Array.from({ length: 7 }, (_, r) => r).filter(r => !cleared.has(r));
      for (let r = 0; r < 7; r++) fall[r][c] = r < cleared.size ? -cleared.size : survivors[r - cleared.size] - r;
    }
    setDrops(fall);
    setState(next);
    setFeedback(next.shuffleCount > state.shuffleCount ? 'Free shuffle! A fresh match is ready.' : `+${next.score - state.score} · ${next.lastGroupSize} symbols${next.lastGroupSize >= 6 ? ' · Beautiful cascade!' : ''}`);
    if (haptics) void Haptics.selectionAsync().catch(() => {});
    if (!reducedMotion) {
      entrance.stopAnimation();
      entrance.setValue(0);
      Animated.spring(entrance, { toValue: 1, speed: 22, bounciness: 5, useNativeDriver: true }).start();
    }
  }

  return (
    <View style={styles.game}>
      <View style={styles.stats}>
        <View><Text style={styles.eyebrow}>YOUR SCORE</Text><Text style={styles.score}>{state.score.toLocaleString()}</Text></View>
        <View style={[styles.clock, seconds <= 15 && styles.urgent]} accessibilityLabel={`${seconds} seconds remaining`}>
          <Text style={styles.clockLabel}>TIME LEFT</Text><Text style={[styles.time, seconds <= 15 && styles.urgentText]}>{Math.floor(seconds / 60)}:{String(seconds % 60).padStart(2, '0')}</Text>
        </View>
      </View>
      <View style={styles.track}><View style={[styles.progress, { width: `${state.remainingMs / 90_000 * 100}%`, backgroundColor: seconds <= 15 ? '#ff8c91' : '#fae38a' }]} /></View>
      <Text style={styles.feedback} accessibilityLiveRegion="polite">{state.shuffleCount > 0 && state.groupsCleared === 0 ? 'Free shuffle! A fresh match is ready.' : feedback}</Text>
      <View onLayout={event => setStride((event.nativeEvent.layout.width - 11) / 7)} style={styles.board} accessibilityLabel="Color Cascade symbol board">
        {state.board.map((row, r) => (
          <View key={r} style={styles.row}>
            {row.map((color, c) => (
              <Animated.View key={c} style={[styles.tileSlot, { opacity: entrance.interpolate({ inputRange: [0, 1], outputRange: [0.55, 1] }), transform: [{ translateY: entrance.interpolate({ inputRange: [0, 1], outputRange: [drops[r][c] * stride, 0] }) }] }]}>
                <Pressable accessibilityRole="button" accessibilityLabel={`Row ${r + 1}, column ${c + 1}, ${symbols[color].name}, group of ${findGroup(state.board, r, c).length}`} disabled={paused || !foreground || seconds === 0} onPress={() => tap(r, c)} style={({ pressed }) => [styles.tile, { backgroundColor: symbols[color].color }, pressed && styles.pressed]}>
                  <Text style={styles.symbol}>{symbols[color].glyph}</Text>
                </Pressable>
              </Animated.View>
            ))}
          </View>
        ))}
      </View>
      <View style={styles.legend}>{symbols.map(symbol => <Text key={symbol.name} style={[styles.legendSymbol, { color: symbol.color }]}>{symbol.glyph}</Text>)}</View>
      <Text style={styles.hint}>Tap a connected group of 3+. Bigger groups, bigger scores.</Text>
      <Text style={styles.detail}>{state.groupsCleared} groups cleared · {state.shuffleCount} free shuffles</Text>
      {state.remainingMs === 0 && <Text style={styles.finished} accessibilityLiveRegion="polite">Time’s up! You scored {state.score.toLocaleString()}.</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  game: { width: '100%', maxWidth: 490, alignSelf: 'center', paddingHorizontal: 12, paddingBottom: 18 },
  stats: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 8 },
  eyebrow: { color: '#b6bddc', fontSize: 11, fontWeight: '700', letterSpacing: 2 },
  score: { color: '#fff8e1', fontSize: 42, fontWeight: '800', fontVariant: ['tabular-nums'] },
  clock: { alignItems: 'center', backgroundColor: '#2b3152', borderRadius: 18, paddingHorizontal: 20, paddingVertical: 9 },
  clockLabel: { color: '#c6ccec', fontSize: 9, letterSpacing: 1.5, fontWeight: '700' },
  time: { fontSize: 26, color: '#fae38a', fontWeight: '800', fontVariant: ['tabular-nums'] },
  urgent: { backgroundColor: '#fbe5df' },
  urgentText: { color: '#a93532' },
  track: { height: 5, backgroundColor: '#313956', borderRadius: 4, marginTop: 14, overflow: 'hidden' },
  progress: { height: '100%', borderRadius: 4 },
  feedback: { minHeight: 48, textAlign: 'center', color: '#e4e7fa', fontSize: 13, fontWeight: '600', paddingVertical: 14 },
  board: { padding: 7, borderRadius: 22, backgroundColor: '#262c49', borderWidth: 1, borderColor: '#4b5275', gap: 5, overflow: 'hidden' },
  row: { flexDirection: 'row', gap: 5 },
  tileSlot: { flex: 1, aspectRatio: 1 },
  tile: { flex: 1, borderRadius: 10, alignItems: 'center', justifyContent: 'center', borderWidth: 1.5, borderColor: '#ffffff99', borderBottomWidth: 4, borderBottomColor: '#00000020' },
  pressed: { opacity: 0.65, transform: [{ scale: 0.9 }] },
  symbol: { color: '#ffffff', fontSize: 25, fontWeight: '800', textShadowColor: '#00000020', textShadowRadius: 2, textShadowOffset: { width: 0, height: 1 } },
  legend: { flexDirection: 'row', justifyContent: 'center', gap: 16, marginTop: 16 },
  legendSymbol: { fontSize: 19 },
  hint: { color: '#c4cbe7', textAlign: 'center', fontSize: 12, lineHeight: 19, marginTop: 6 },
  detail: { color: '#a2adce', fontSize: 11, textAlign: 'center', marginTop: 7 },
  finished: { textAlign: 'center', fontSize: 18, fontWeight: '700', color: '#fae38a', padding: 18 },
});
