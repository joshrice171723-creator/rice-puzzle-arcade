import { PieceArt } from '../../packages/ui/PieceArt';
import { Goal } from '../../packages/game-utils/challenges';
import { GoalMeter } from '../../packages/ui/GoalMeter';
import { Theme, useGameTheme } from '../../packages/ui/themes';
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
  goal?: Goal;
  bestScore?: number;
};

export default function Game({ seed, paused, saved, onSave, onEnd, rewardToken, haptics, goal, bestScore = 0 }: Props) {
  const { theme, softTiles } = useGameTheme();
  const styles = makeStyles(theme, softTiles);
  const [state, setState] = useState(() => restoreGame(saved) ?? createGame(seed));
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  const [feedback, setFeedback] = useState(goal?.hint ?? 'Find a matching group of 3 or more');
  const [reducedMotion, setReducedMotion] = useState(false);
  const [stride, setStride] = useState(42);
  const [frame, setFrame] = useState({ width: 300, height: 600 });
  const boardSize = Math.max(100, Math.min(frame.width, frame.height - 210, 420));
  const startingBest = useRef(bestScore).current;
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
    setState(current => extendTime(current, true));
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
    <View onLayout={event => setFrame({ width: event.nativeEvent.layout.width, height: event.nativeEvent.layout.height })} style={styles.game}>
      <View style={styles.stats}>
        <View><Text style={styles.eyebrow}>YOUR SCORE</Text><Text style={styles.score}>{state.score.toLocaleString()}</Text></View>
        <View style={[styles.clock, seconds <= 15 && styles.urgent]} accessibilityLabel={`${seconds} seconds remaining`}>
          <Text style={styles.clockLabel}>TIME LEFT</Text><Text style={[styles.time, seconds <= 15 && styles.urgentText]}>{Math.floor(seconds / 60)}:{String(seconds % 60).padStart(2, '0')}</Text>
        </View>
      </View>
      <View style={styles.track}><View style={[styles.progress, { width: `${state.remainingMs / 90_000 * 100}%`, backgroundColor: seconds <= 15 ? '#ff8c91' : theme.accent }]} /></View>
      <GoalMeter {...(goal ?? { label: state.score <= startingBest && startingBest > 0 ? 'Beat your best' : 'Next milestone', value: state.score, target: state.score <= startingBest && startingBest > 0 ? startingBest + 10 : (Math.floor(state.score / 1000) + 1) * 1000 })} />
      <Text style={styles.feedback} accessibilityLiveRegion="polite">{state.shuffleCount > 0 && state.groupsCleared === 0 ? 'Free shuffle! A fresh match is ready.' : feedback}</Text>
      <View onLayout={event => setStride((event.nativeEvent.layout.width - 11) / 7)} style={[styles.board, { width: boardSize }]} accessibilityLabel="Color Cascade symbol board">
        {state.board.map((row, r) => (
          <View key={r} style={styles.row}>
            {row.map((color, c) => (
              <Animated.View key={c} style={[styles.tileSlot, { opacity: entrance.interpolate({ inputRange: [0, 1], outputRange: [0.55, 1] }), transform: [{ translateY: entrance.interpolate({ inputRange: [0, 1], outputRange: [drops[r][c] * stride, 0] }) }] }]}>
                <Pressable accessibilityRole="button" accessibilityLabel={`Row ${r + 1}, column ${c + 1}, ${symbols[color].name}, group of ${findGroup(state.board, r, c).length}`} disabled={paused || !foreground || seconds === 0} onPress={() => tap(r, c)} style={({ pressed }) => [styles.tile, pressed && styles.pressed]}>
                  <PieceArt kind="candy" color={color} />
                </Pressable>
              </Animated.View>
            ))}
          </View>
        ))}
      </View>
      <Text style={styles.hint}>{state.remainingMs === 0 ? `Time’s up! ${state.score.toLocaleString()} points.` : `${state.groupsCleared} groups cleared · Bigger groups, bigger scores.`}</Text>
    </View>
  );
}

const makeStyles = (theme: Theme, softTiles: boolean) => StyleSheet.create({
  game: { flex: 1, minHeight: 0, width: '100%', alignSelf: 'center', justifyContent: 'center', gap: 8 },
  stats: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 8 },
  eyebrow: { color: theme.muted, fontSize: 11, fontWeight: '700', letterSpacing: 2 },
  score: { color: theme.ink, fontSize: 34, fontWeight: '800', fontVariant: ['tabular-nums'] },
  clock: { alignItems: 'center', backgroundColor: theme.empty, borderRadius: 18, paddingHorizontal: 20, paddingVertical: 9 },
  clockLabel: { color: theme.muted, fontSize: 9, letterSpacing: 1.5, fontWeight: '700' },
  time: { fontSize: 26, color: theme.accent, fontWeight: '800', fontVariant: ['tabular-nums'] },
  urgent: { backgroundColor: '#fbe5df' },
  urgentText: { color: '#a93532' },
  track: { height: 5, backgroundColor: theme.empty, borderRadius: 4, overflow: 'hidden' },
  progress: { height: '100%', borderRadius: 4 },
  feedback: { minHeight: 30, lineHeight: 15, textAlign: 'center', color: theme.ink, fontSize: 12, fontWeight: '600' },
  board: { alignSelf: 'center', padding: 7, borderRadius: 22, backgroundColor: theme.board, borderWidth: 1, borderColor: theme.edge, gap: 5, overflow: 'hidden' },
  row: { flexDirection: 'row', gap: 5 },
  tileSlot: { flex: 1, aspectRatio: 1 },
  tile: { flex: 1, borderRadius: softTiles ? 15 : 3, alignItems: 'center', justifyContent: 'center', backgroundColor: '#ffffff30' },
  pressed: { opacity: 0.65, transform: [{ scale: 0.9 }] },
  legend: { flexDirection: 'row', justifyContent: 'center', gap: 16, marginTop: 16 },
  legendSymbol: { fontSize: 19 },
  hint: { color: theme.muted, textAlign: 'center', fontSize: 12, lineHeight: 19 },
  detail: { color: theme.muted, fontSize: 11, textAlign: 'center', marginTop: 7 },
  finished: { textAlign: 'center', fontSize: 18, fontWeight: '700', color: theme.accent, padding: 18 },
});
