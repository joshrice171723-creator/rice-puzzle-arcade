import { PieceArt } from '../../packages/ui/PieceArt';
import { Theme, useGameTheme } from '../../packages/ui/themes';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, PanResponder, Pressable, StyleSheet, Text, useWindowDimensions, View, type ViewInstance } from 'react-native';
import * as Haptics from 'expo-haptics';
import { canPlace, GameState, newGame, place, restoreGame, revive, Shape, SHAPES, SIZE } from './game';

type Props = {
  seed: number; paused: boolean; saved?: unknown; onSave: (state: unknown) => void;
  onEnd: () => void; rewardToken: number; haptics: boolean;
};
type Preview = { row: number; col: number; index: number };


export default function Game({ seed, paused, saved, onSave, onEnd, rewardToken, haptics }: Props) {
  const { theme, softTiles } = useGameTheme();
  const styles = makeStyles(theme, softTiles);
  const [state, setState] = useState<GameState>(() => restoreGame(saved) ?? newGame(seed));
  const [selected, setSelected] = useState<number | null>(null);
  const [preview, setPreview] = useState<Preview | null>(null);
  const [clearCells, setClearCells] = useState<string[]>([]);
  const [notice, setNotice] = useState('Choose a shape. Give it a home.');
  const [reducedMotion, setReducedMotion] = useState(false);
  const clearOpacity = useRef(new Animated.Value(0)).current;
  const boardRef = useRef<ViewInstance>(null);
  const bounds = useRef({ x: 0, y: 0 });
  const stateRef = useRef(state); stateRef.current = state;
  const pauseRef = useRef(paused); pauseRef.current = paused;
  const callbackRef = useRef({ onSave, onEnd }); callbackRef.current = { onSave, onEnd };
  const endedReported = useRef(false);
  const lastReward = useRef(rewardToken);
  const width = useWindowDimensions().width;
  const boardSize = Math.min(width - 48, 420);
  const cellSize = (boardSize - 8) / SIZE;

  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled().then(value => { if (mounted) setReducedMotion(value); });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReducedMotion);
    return () => { mounted = false; subscription.remove(); clearOpacity.stopAnimation(); };
  }, [clearOpacity]);
  useEffect(() => {
    callbackRef.current.onSave(state);
    if (state.ended && !endedReported.current) { endedReported.current = true; callbackRef.current.onEnd(); }
    if (!state.ended) endedReported.current = false;
  }, [state]);
  useEffect(() => {
    if (rewardToken > lastReward.current && stateRef.current.ended && !stateRef.current.revived) {
      setState(current => revive(current));
      setNotice('Two busiest rows cleared. Back to the workshop.');
      setSelected(null); setPreview(null);
    }
    lastReward.current = rewardToken;
  }, [rewardToken]);
  useEffect(() => { if (paused) setPreview(null); }, [paused]);

  function drop(index: number, row: number, col: number) {
    if (pauseRef.current) return;
    const result = place(stateRef.current, index, row, col);
    setPreview(null);
    if (result.state === stateRef.current) {
      setNotice('That shape needs empty space. Try another spot.');
      return;
    }
    stateRef.current = result.state;
    setState(result.state); setSelected(null);
    const lineText = result.lines > 1 ? result.lines + ' lines · combo!' : result.lines === 1 ? 'Clean line!' : 'Solid fit.';
    setNotice(lineText + ' +' + result.points);
    AccessibilityInfo.announceForAccessibility(lineText + ' ' + result.points + ' points. Score ' + result.state.score + '.');
    if (haptics) void Haptics.impactAsync(result.lines ? Haptics.ImpactFeedbackStyle.Medium : Haptics.ImpactFeedbackStyle.Light).catch(() => {});
    if (result.cleared.length) {
      setClearCells(result.cleared.map(([r, c]) => r + ':' + c));
      clearOpacity.stopAnimation(); clearOpacity.setValue(1);
      Animated.timing(clearOpacity, { toValue: 0, duration: reducedMotion ? 0 : 460, useNativeDriver: true }).start();
    }
  }

  function locate(index: number, x: number, y: number): Preview | null {
    const shape = stateRef.current.tray[index];
    if (!shape || pauseRef.current || stateRef.current.ended) return null;
    const cells = SHAPES[shape];
    const rows = Math.max(...cells.map(([r]) => r)) + 1;
    const cols = Math.max(...cells.map(([, c]) => c)) + 1;
    return { index, row: Math.floor((y - bounds.current.y - 4) / cellSize - rows / 2 + .5), col: Math.floor((x - bounds.current.x - 4) / cellSize - cols / 2 + .5) };
  }

  const handlers = useRef({ drop, locate }); handlers.current = { drop, locate };
  const responders = useMemo(() => [0, 1, 2].map(index => PanResponder.create({
    onStartShouldSetPanResponder: () => !pauseRef.current && !stateRef.current.ended && stateRef.current.tray[index] !== null,
    onMoveShouldSetPanResponder: () => !pauseRef.current && !stateRef.current.ended,
    onPanResponderGrant: () => {
      setSelected(index);
      boardRef.current?.measureInWindow((x, y) => { bounds.current = { x, y }; });
    },
    onPanResponderMove: (_, gesture) => setPreview(handlers.current.locate(index, gesture.moveX, gesture.moveY)),
    onPanResponderRelease: (_, gesture) => {
      if (Math.abs(gesture.dx) + Math.abs(gesture.dy) > 8) {
        const target = handlers.current.locate(index, gesture.moveX, gesture.moveY);
        if (target) handlers.current.drop(index, target.row, target.col);
      }
      setPreview(null);
    },
    onPanResponderTerminate: () => setPreview(null),
    onPanResponderTerminationRequest: () => true,
  })), []);
  const ghostShape = preview ? state.tray[preview.index] : null;
  const legalPreview = !!(preview && ghostShape && canPlace(state.board, ghostShape, preview.row, preview.col));
  const ghost = new Set(ghostShape && preview ? SHAPES[ghostShape].map(([r, c]) => (r + preview.row) + ':' + (c + preview.col)) : []);
  const activeShape = selected === null ? null : state.tray[selected];

  return <View style={styles.root}>
    <View style={[styles.scorePanel, { width: boardSize }]}>
      <View><Text style={styles.eyebrow}>WORKSHOP SCORE</Text><Text accessibilityLabel={'Score ' + state.score} style={styles.score}>{state.score.toLocaleString()}</Text></View>
      <View style={styles.moveBadge}><Text style={styles.moveNumber}>{String(state.moves).padStart(2, '0')}</Text><Text style={styles.eyebrow}>DROPS</Text></View>
    </View>
    <Text style={styles.notice} accessibilityLiveRegion="polite">{state.ended ? 'The workshop is full. A new run awaits.' : paused ? 'Workshop paused' : notice}</Text>
    <View ref={boardRef} onLayout={() => boardRef.current?.measureInWindow((x, y) => { bounds.current = { x, y }; })}
      style={[styles.board, { width: boardSize, height: boardSize }, paused && styles.paused]} accessibilityLabel="Foundry board, 8 rows and 8 columns">
      {state.board.map((row, r) => <View key={r} style={styles.row}>{row.map((occupied, c) => {
        const key = r + ':' + c;
        const highlighted = ghost.has(key);
        return <Pressable key={c} accessibilityRole="button"
          accessibilityLabel={'Row ' + (r + 1) + ', column ' + (c + 1) + ', ' + (occupied ? 'occupied' : 'empty')}
          accessibilityHint={activeShape ? 'Place the selected shape starting here' : 'First choose a shape from the tray'}
          disabled={paused || state.ended}
          onPress={() => { if (selected !== null) drop(selected, r, c); else setNotice('Choose one of the three shapes below first.'); }}
          style={[styles.cell, { width: cellSize - 4, height: cellSize - 4 }, !!occupied && styles.filled,
            highlighted && (legalPreview ? styles.ghost : styles.illegal)]}>
          {!!occupied && <PieceArt kind="wood" />}
          {clearCells.includes(key) && <Animated.View pointerEvents="none" style={[styles.clearFlash, { opacity: clearOpacity }]} />}
        </Pressable>;
      })}</View>)}
    </View>
    <View style={[styles.trayHeader, { width: boardSize }]}><Text style={styles.eyebrow}>YOUR LITTLE BUILDING BLOCKS</Text><Text style={styles.trayHint}>drag or tap to place</Text></View>
    <View style={[styles.tray, { width: boardSize }]}>{state.tray.map((shape, index) =>
      <View key={index} {...responders[index].panHandlers} style={[styles.pieceSlot, selected === index && styles.selectedSlot]}>
        {shape ? <Pressable accessibilityRole="button" accessibilityLabel={'Select ' + shape + ' shape, ' + SHAPES[shape].length + ' cells'}
          accessibilityState={{ selected: selected === index, disabled: paused || state.ended }}
          disabled={paused || state.ended} onPress={() => { setSelected(index); setNotice('Tap an empty cell for the top-left corner.'); }} style={styles.pieceButton}>
          <MiniShape shape={shape} />
        </Pressable> : <Text style={styles.usedSlot} accessibilityLabel="Piece placed">✓</Text>}
      </View>)}</View>
    {state.ended ? <View style={[styles.result, { width: boardSize }]} accessibilityRole="summary">
      <Text style={styles.resultTitle}>NICE BUILDING!</Text>
      <Text style={styles.resultCopy}>{state.revived ? 'Your second wind was well spent.' : 'A rewarded revive clears your two busiest rows and brings a playable tray.'}</Text>
    </View> : <Text style={styles.footer}>Fill a row or column. Make room for what’s next.</Text>}
  </View>;
}

function MiniShape({ shape }: { shape: Shape }) {
  const { theme, softTiles } = useGameTheme();
  const styles = makeStyles(theme, softTiles);
  const cells = SHAPES[shape];
  const rows = Math.max(...cells.map(([r]) => r)) + 1;
  const cols = Math.max(...cells.map(([, c]) => c)) + 1;
  return <View pointerEvents="none" style={{ width: cols * 19, height: rows * 19 }}>{cells.map(([r, c]) =>
    <View key={r + ':' + c} style={[styles.miniCell, { top: r * 19, left: c * 19 }]}><PieceArt kind="wood" /></View>)}</View>;
}

const makeStyles = (theme: Theme, softTiles: boolean) => StyleSheet.create({
  root: { alignItems: 'center', paddingVertical: 12, width: '100%' },
  scorePanel: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 3 },
  eyebrow: { color: theme.muted, fontSize: 10, fontWeight: '700', letterSpacing: 1.5 },
  score: { color: theme.ink, fontSize: 45, fontWeight: '800', fontVariant: ['tabular-nums'], letterSpacing: -2 },
  moveBadge: { borderLeftWidth: 1, borderLeftColor: theme.edge, paddingLeft: 18, alignItems: 'center' },
  moveNumber: { color: theme.accent, fontSize: 24, fontWeight: '600', fontVariant: ['tabular-nums'] },
  notice: { color: theme.muted, fontSize: 12, textAlign: 'center', marginTop: 8, marginBottom: 16, minHeight: 18, paddingHorizontal: 16 },
  board: { backgroundColor: theme.board, borderRadius: 20, padding: 4, borderWidth: 0, overflow: 'hidden' },
  row: { flexDirection: 'row' },
  cell: { margin: 2, borderRadius: softTiles ? 9 : 2, backgroundColor: '#73502b25', borderWidth: 1, borderColor: '#7d512c50', justifyContent: 'center', alignItems: 'center', overflow: 'hidden' },
  filled: { backgroundColor: 'transparent', borderWidth: 0 },
  ghost: { backgroundColor: '#6d735e', borderColor: '#f8dda9', borderStyle: 'dashed', borderWidth: 2 },
  illegal: { backgroundColor: '#683e44', borderColor: '#f8a5a5', borderWidth: 2 },
  clearFlash: { position: 'absolute', top: 0, bottom: 0, left: 0, right: 0, backgroundColor: '#ffe8b9' },
  paused: { opacity: .35 },
  trayHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 24, marginBottom: 10 },
  trayHint: { color: theme.muted, fontSize: 10 },
  tray: { flexDirection: 'row', gap: 10 },
  pieceSlot: { flex: 1, height: 91, borderRadius: 12, backgroundColor: theme.empty, borderWidth: 1, borderColor: theme.edge, justifyContent: 'center', alignItems: 'center' },
  selectedSlot: { borderColor: theme.accent, borderWidth: 2, backgroundColor: theme.empty },
  pieceButton: { flex: 1, width: '100%', justifyContent: 'center', alignItems: 'center', minHeight: 48 },
  miniCell: { position: 'absolute', width: 16, height: 16, borderRadius: softTiles ? 5 : 1, backgroundColor: 'transparent' },
  usedSlot: { color: '#729281', fontSize: 25 },
  footer: { color: theme.muted, fontSize: 11, marginTop: 19, textAlign: 'center', paddingHorizontal: 12 },
  result: { marginTop: 18, borderTopWidth: 1, borderTopColor: theme.edge, paddingTop: 16 },
  resultTitle: { color: theme.accent, fontSize: 15, letterSpacing: 2, fontWeight: '800', textAlign: 'center' },
  resultCopy: { color: theme.muted, fontSize: 12, lineHeight: 19, textAlign: 'center', marginTop: 8 },
});
