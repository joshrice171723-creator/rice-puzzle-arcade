import { scoreGoal } from './progress';
import { dragTarget } from './placement';
import { PieceArt } from '../../packages/ui/PieceArt';
import { Theme, useGameTheme } from '../../packages/ui/themes';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, PanResponder, Platform, Pressable, StyleSheet, Text, useWindowDimensions, View, type ViewStyle, type ViewInstance } from 'react-native';
import * as Haptics from 'expo-haptics';
import { canPlace, GameState, newGame, place, restoreGame, revive, Shape, SHAPES, SIZE } from './game';

type Props = {
  seed: number; paused: boolean; saved?: unknown; onSave: (state: unknown) => void;
  onEnd: () => void; rewardToken: number; haptics: boolean; bestScore?: number;
};
type Preview = { row: number; col: number; index: number };


export default function Game({ seed, paused, saved, onSave, onEnd, rewardToken, haptics, bestScore = 0 }: Props) {
  const { theme, softTiles } = useGameTheme();
  const styles = makeStyles(theme, softTiles);
  const [state, setState] = useState<GameState>(() => restoreGame(saved) ?? newGame(seed));
  const startingBest = useRef(bestScore).current;
  const scorePulse = useRef(new Animated.Value(1)).current;
  const [frame, setFrame] = useState({ width: 340, height: 600 });
  const landscape = useWindowDimensions().width > useWindowDimensions().height;
  const [hoveredPiece, setHoveredPiece] = useState<number | null>(null);
  const [selected, setSelected] = useState<number | null>(null);
  const [drag, setDrag] = useState<{ index: number; x: number; y: number } | null>(null);
  const dragRef = useRef(false);
  const rootRef = useRef<ViewInstance>(null);
  const rootBounds = useRef({ x: 0, y: 0 });
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
  const boardSize = Math.max(80, Math.min(landscape ? frame.width * .53 : frame.width, landscape ? frame.height - 8 : frame.height - 248, 420));
  const panelWidth = landscape ? Math.max(130, frame.width - boardSize - 16) : boardSize;
  const goal = scoreGoal(state.score, startingBest);
  const cellSize = (boardSize - 8) / SIZE;

  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled().then(value => { if (mounted) setReducedMotion(value); });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReducedMotion);
    return () => { mounted = false; subscription.remove(); clearOpacity.stopAnimation(); scorePulse.stopAnimation(); };
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
  useEffect(() => { setPreview(null); setDrag(null); dragRef.current = false; }, [paused, frame.width, frame.height]);

  function drop(index: number, row: number, col: number) {
    if (pauseRef.current) return;
    const result = place(stateRef.current, index, row, col);
    setPreview(null);
    if (result.state === stateRef.current) {
      setNotice('That shape needs empty space. Try another spot.');
      return;
    }
    const previousScore = stateRef.current.score;
    if (!reducedMotion) {
      scorePulse.stopAnimation(); scorePulse.setValue(1.12);
      Animated.spring(scorePulse, { toValue: 1, speed: 22, bounciness: 7, useNativeDriver: true }).start();
    }
    stateRef.current = result.state;
    setState(result.state); setSelected(null);
    const lineText = result.lines > 1 ? result.lines + ' lines · combo!' : result.lines === 1 ? 'Clean line!' : 'Solid fit.';
    const celebration = previousScore <= startingBest && result.state.score > startingBest && startingBest > 0 ? 'New personal best!' : Math.floor(result.state.score / 500) > Math.floor(previousScore / 500) ? 'Milestone reached!' : lineText;
    setNotice(celebration + ' +' + result.points);
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
    const target = dragTarget(shape, x - bounds.current.x - 4, y - bounds.current.y - 4, cellSize);
    return target ? { index, ...target } : null;
  }

  const lift = Platform.OS === 'web' ? 0 : 56;
  function moveDrag(index: number, x: number, y: number) {
    if (pauseRef.current || stateRef.current.ended) return;
    dragRef.current = true;
    setDrag({ index, x: x - rootBounds.current.x, y: y - lift - rootBounds.current.y });
    setPreview(locate(index, x, y - lift));
  }
  const handlers = useRef({ drop, locate, moveDrag }); handlers.current = { drop, locate, moveDrag };
  const responders = useMemo(() => [0, 1, 2].map(index => PanResponder.create({
    onStartShouldSetPanResponderCapture: () => !pauseRef.current && !stateRef.current.ended && stateRef.current.tray[index] !== null,
    onMoveShouldSetPanResponder: () => !pauseRef.current && !stateRef.current.ended,
    onPanResponderGrant: () => {
      setSelected(index); setPreview(null);
      setNotice('Drag onto the board. Green fits; red needs more room.');
      rootRef.current?.measureInWindow((x, y) => { rootBounds.current = pagePosition(x, y); });
      boardRef.current?.measureInWindow((x, y) => { bounds.current = pagePosition(x, y); });
    },
    onPanResponderMove: (_, gesture) => {
      if (Math.abs(gesture.dx) + Math.abs(gesture.dy) > 6) handlers.current.moveDrag(index, gesture.moveX, gesture.moveY);
    },
    onPanResponderRelease: (_, gesture) => {
      if (dragRef.current) {
        const target = handlers.current.locate(index, gesture.moveX, gesture.moveY - lift);
        if (target) handlers.current.drop(index, target.row, target.col);
        else setNotice('Drop cancelled. Your piece is still in the tray.');
      }
      setPreview(null); setDrag(null); dragRef.current = false;
    },
    onPanResponderTerminate: () => { setPreview(null); setDrag(null); dragRef.current = false; },
    onPanResponderTerminationRequest: () => false,
  })), []);
  const ghostShape = preview ? state.tray[preview.index] : null;
  const legalPreview = !!(preview && ghostShape && canPlace(state.board, ghostShape, preview.row, preview.col));
  const ghost = new Set(ghostShape && preview ? SHAPES[ghostShape].map(([r, c]) => (r + preview.row) + ':' + (c + preview.col)) : []);
  const activeShape = selected === null ? null : state.tray[selected];

  const draggedShape = drag ? state.tray[drag.index] : null;
  const metrics = <><View style={[styles.scorePanel, { width: panelWidth }]}>
      <View><Text style={styles.eyebrow}>WORKSHOP SCORE</Text><Animated.Text accessibilityLabel={'Score ' + state.score} style={[styles.score, { transform: [{ scale: scorePulse }] }]}>{state.score.toLocaleString()}</Animated.Text></View>
      <View style={styles.moveBadge}><Text style={styles.moveNumber}>{String(state.moves).padStart(2, '0')}</Text><Text style={styles.eyebrow}>DROPS</Text></View>
    </View>
    <Text style={styles.notice} accessibilityLiveRegion="polite">{state.ended ? 'The workshop is full. A new run awaits.' : paused ? 'Workshop paused' : preview ? legalPreview ? (drag ? 'Release to place · Fits here' : 'Fits here · Click to place') : 'Needs more room · Try another spot' : notice}</Text><View style={{ width: panelWidth, gap: 4 }}><View style={styles.goalLabels}><Text style={styles.trayHint}>{goal.label}</Text><Text style={styles.trayHint}>{state.score.toLocaleString()} / {goal.target.toLocaleString()}</Text></View><View style={styles.goalTrack}><View style={[styles.goalFill, { width: (goal.fraction * 100) + '%' }]} /></View></View></>;
  const board = (<View ref={boardRef} onLayout={() => boardRef.current?.measureInWindow((x, y) => { bounds.current = pagePosition(x, y); })}
      style={[styles.board, { width: boardSize, height: boardSize }, paused && styles.paused]} accessibilityLabel="Foundry board, 8 rows and 8 columns">
      {state.board.map((row, r) => <View key={r} style={styles.row}>{row.map((occupied, c) => {
        const key = r + ':' + c;
        const highlighted = ghost.has(key);
        return <Pressable key={c} accessibilityRole="button"
          accessibilityLabel={'Row ' + (r + 1) + ', column ' + (c + 1) + ', ' + (occupied ? 'occupied' : 'empty')}
          accessibilityHint={activeShape ? 'Place the selected shape starting here' : 'First choose a shape from the tray'}
          disabled={paused || state.ended}
          onHoverIn={() => { if (!dragRef.current && selected !== null && !paused && !state.ended) setPreview({ index: selected, row: r, col: c }); }}
          onHoverOut={() => { if (!dragRef.current) setPreview(null); }}
          onPress={() => { if (selected !== null) drop(selected, r, c); else setNotice('Choose one of the three shapes below first.'); }}
          style={[styles.cell, { width: cellSize - 4, height: cellSize - 4 }, !!occupied && styles.filled,
            highlighted && (legalPreview ? styles.ghost : styles.illegal)]}>
          {!!occupied && <PieceArt kind="wood" />}
          {highlighted && <View pointerEvents="none" style={[StyleSheet.absoluteFill, legalPreview ? styles.previewGood : styles.previewBad]}><Text style={styles.previewMark}>{legalPreview ? '+' : '×'}</Text></View>}
          {clearCells.includes(key) && <Animated.View pointerEvents="none" style={[styles.clearFlash, { opacity: clearOpacity }]} />}
        </Pressable>;
      })}</View>)}
    </View>);
  const tray = <><View style={[styles.trayHeader, { width: panelWidth }]}><Text style={styles.eyebrow}>YOUR PIECES</Text><Text style={styles.trayHint}>drag or tap to place</Text></View>
    <View style={[styles.tray, { width: panelWidth }]}>{state.tray.map((shape, index) =>
      <View key={index} {...responders[index].panHandlers} style={[styles.pieceSlot, selected === index && styles.selectedSlot, drag?.index === index && { opacity: .45 }, webDragStyle]}>
        {shape ? <Pressable accessibilityRole="button" accessibilityLabel={'Select ' + shape + ' shape, ' + SHAPES[shape].length + ' cells'}
          accessibilityState={{ selected: selected === index, disabled: paused || state.ended }}
          onHoverIn={() => setHoveredPiece(index)} onHoverOut={() => setHoveredPiece(null)}
          disabled={paused || state.ended} onPress={() => { setSelected(index); setNotice('Hover to preview, then click. Or drag the piece onto the board.'); }} style={({ pressed }) => [styles.pieceButton, hoveredPiece === index && !paused && !state.ended && styles.hoveredPiece, pressed && { opacity: .8 }, webDragStyle]}>
          <MiniShape shape={shape} step={Math.min(22, (panelWidth / 3 - 14) / 3)} />
        </Pressable> : <Text style={styles.usedSlot} accessibilityLabel="Piece placed">✓</Text>}
      </View>)}</View></>;
  return <View ref={rootRef} onLayout={event => setFrame({ width: event.nativeEvent.layout.width, height: event.nativeEvent.layout.height })} style={[styles.root, landscape && { flexDirection: 'row', gap: 16, justifyContent: 'center' }]}>
    {landscape ? <>{board}<View style={{ width: panelWidth, gap: 8 }}>{metrics}{tray}</View></> : <>{metrics}{board}{tray}</>}
    {drag && draggedShape && <View pointerEvents="none" accessibilityElementsHidden style={[styles.floatingPiece, { left: drag.x - (Math.max(...SHAPES[draggedShape].map(([, c]) => c)) + 1) * cellSize / 2, top: drag.y - (Math.max(...SHAPES[draggedShape].map(([r]) => r)) + 1) * cellSize / 2 }]}><MiniShape shape={draggedShape} step={cellSize} /></View>}
  </View>;
}

function MiniShape({ shape, step = 24 }: { shape: Shape; step?: number }) {
  const { theme, softTiles } = useGameTheme();
  const styles = makeStyles(theme, softTiles);
  const cells = SHAPES[shape];
  const rows = Math.max(...cells.map(([r]) => r)) + 1;
  const cols = Math.max(...cells.map(([, c]) => c)) + 1;
  return <View pointerEvents="none" style={{ width: cols * step, height: rows * step }}>{cells.map(([r, c]) =>
    <View key={r + ':' + c} style={[styles.miniCell, { top: r * step, left: c * step, width: step - 3, height: step - 3 }]}><PieceArt kind="wood" /></View>)}</View>;
}

// Web gestures report document coordinates; native gestures and measurements use window coordinates.
const pagePosition = (x: number, y: number) => ({ x: x + (Platform.OS === 'web' ? window.scrollX : 0), y: y + (Platform.OS === 'web' ? window.scrollY : 0) });

const webDragStyle = Platform.OS === 'web' ? { touchAction: 'none', cursor: 'pointer', userSelect: 'none' } as ViewStyle : undefined;

const makeStyles = (theme: Theme, softTiles: boolean) => StyleSheet.create({
  goalLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  goalTrack: { height: 6, borderRadius: 3, backgroundColor: theme.empty, overflow: 'hidden' },
  goalFill: { height: '100%', borderRadius: 3, backgroundColor: '#658545' },
  hoveredPiece: { backgroundColor: '#f5d4a2', transform: [{ translateY: -3 }], borderRadius: 11 },
  floatingPiece: { position: 'absolute', zIndex: 100, opacity: .85 },
  previewGood: { backgroundColor: '#4d9c6655', borderWidth: 2, borderColor: '#276440', borderRadius: 7, justifyContent: 'center', alignItems: 'center' },
  previewBad: { backgroundColor: '#df4e5c88', borderWidth: 2, borderColor: '#9e2432', borderRadius: 7, justifyContent: 'center', alignItems: 'center' },
  previewMark: { color: '#fff', fontSize: 20, fontWeight: '800' },
  root: { flex: 1, minHeight: 0, alignItems: 'center', justifyContent: 'center', width: '100%', gap: 8 },
  scorePanel: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 3 },
  eyebrow: { color: theme.muted, fontSize: 10, fontWeight: '700', letterSpacing: 1.5 },
  score: { color: theme.ink, fontSize: 34, fontWeight: '800', fontVariant: ['tabular-nums'], letterSpacing: -2 },
  moveBadge: { borderLeftWidth: 1, borderLeftColor: theme.edge, paddingLeft: 18, alignItems: 'center' },
  moveNumber: { color: theme.accent, fontSize: 24, fontWeight: '600', fontVariant: ['tabular-nums'] },
  notice: { color: theme.muted, fontSize: 12, textAlign: 'center', minHeight: 30, lineHeight: 15, paddingHorizontal: 4, maxWidth: '100%' },
  board: { backgroundColor: theme.board, borderRadius: 20, padding: 4, borderWidth: 0, overflow: 'hidden' },
  row: { flexDirection: 'row' },
  cell: { margin: 2, borderRadius: softTiles ? 9 : 2, backgroundColor: '#73502b25', borderWidth: 1, borderColor: '#7d512c50', justifyContent: 'center', alignItems: 'center', overflow: 'hidden' },
  filled: { backgroundColor: 'transparent', borderWidth: 0 },
  ghost: { backgroundColor: '#6d735e', borderColor: '#f8dda9', borderStyle: 'dashed', borderWidth: 2 },
  illegal: { backgroundColor: '#683e44', borderColor: '#f8a5a5', borderWidth: 2 },
  clearFlash: { position: 'absolute', top: 0, bottom: 0, left: 0, right: 0, backgroundColor: '#ffe8b9' },
  paused: { opacity: .35 },
  trayHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 2 },
  trayHint: { color: theme.muted, fontSize: 10 },
  tray: { flexDirection: 'row', gap: 10 },
  pieceSlot: { flex: 1, height: 72, borderRadius: 12, backgroundColor: theme.empty, borderWidth: 1, borderColor: theme.edge, justifyContent: 'center', alignItems: 'center' },
  selectedSlot: { borderColor: theme.accent, borderWidth: 2, backgroundColor: theme.empty },
  pieceButton: { flex: 1, width: '100%', justifyContent: 'center', alignItems: 'center', minHeight: 48 },
  miniCell: { position: 'absolute', width: 16, height: 16, borderRadius: softTiles ? 5 : 1, backgroundColor: 'transparent' },
  usedSlot: { color: '#729281', fontSize: 25 },
  footer: { color: theme.muted, fontSize: 11, marginTop: 19, textAlign: 'center', paddingHorizontal: 12 },
  result: { marginTop: 18, borderTopWidth: 1, borderTopColor: theme.edge, paddingTop: 16 },
  resultTitle: { color: theme.accent, fontSize: 15, letterSpacing: 2, fontWeight: '800', textAlign: 'center' },
  resultCopy: { color: theme.muted, fontSize: 12, lineHeight: 19, textAlign: 'center', marginTop: 8 },
});
