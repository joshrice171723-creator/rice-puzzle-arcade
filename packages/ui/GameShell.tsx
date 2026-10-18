import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Platform, AppState, Image, Linking, Modal, Pressable, StyleSheet, Switch, Text, View, useWindowDimensions } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useAudioPlayer } from 'expo-audio';
import { gameTheme, Theme, ThemeContext } from './themes';
import { Music } from './Music';
import { createTelemetry, Fields } from '../analytics/client';
import { createAdsService } from '../ads';
import { boostAvailable } from '../game-utils/boost';
import { Goal, journey, levelGoal, levelInfo, completionAllowed, LEVELS_PER_ZONE, ZONE_COUNT } from '../game-utils/challenges';
import { ArcadeSave, createSaveWriter, dailySeed, emptySave, localDate, Mode, parseSave, Run, updateRun } from '../game-utils/storage';

type GameProps = { seed: number; paused: boolean; saved?: unknown; onSave: (state: unknown) => void; onEnd: () => void; rewardToken: number; haptics: boolean; bestScore?: number; goal?: Goal };
type Props = { slug: string; title: string; subtitle: string; accent: string; background: string; tutorial: string[]; rewardDescription: string; Game: React.ComponentType<GameProps> };

export default function GameShell(props: Props) {
  return <SafeAreaProvider><Shell {...props} /></SafeAreaProvider>;
}

function Shell({ slug, title, subtitle, tutorial, rewardDescription, Game }: Props) {
  const [data, setData] = useState<ArcadeSave>(emptySave);
  const theme = gameTheme(slug);
  const { accent, background } = theme;
  const styles = makeStyles(theme);
  const latest = useRef(data);
  const [loaded, setLoaded] = useState(false);
  const [screen, setScreen] = useState<'home' | 'play'>('home');
  const viewport = useWindowDimensions();
  const fitPlay = screen === 'play';
  const [levelsOpen, setLevelsOpen] = useState(false);
  const [levelPage, setLevelPage] = useState(0);
  const trail = journey(slug);
  const [mode, setMode] = useState<Mode>('normal');
  const currentMode = useRef<Mode>('normal');
  const [paused, setPaused] = useState(false);
  const [foreground, setForeground] = useState(AppState.currentState !== 'background');
  const [settings, setSettings] = useState(false);
  const [help, setHelp] = useState(false);
  const [privacy, setPrivacy] = useState(false);
  const [privacyPage, setPrivacyPage] = useState(0);
  const [boostOpen, setBoostOpen] = useState(false);
  const [notice, setNotice] = useState('');
  const [rewardToken, setRewardToken] = useState(0);
  const ads = useRef(createAdsService(slug)).current;
  const [telemetry] = useState(() => createTelemetry(slug, AsyncStorage, process.env.EXPO_PUBLIC_ANALYTICS_URL || 'https://aimetaclinic.com/games/api/events', process.env.EXPO_PUBLIC_BUILD_PROFILE === 'production' ? 'production' : 'test'));
  const [tracking, setTracking] = useState(true);
  const activity = useRef(false);
  const runFields = (r: Run, saved: unknown = r.saved): Fields => { const state = saved as { score?: number; moves?: number; groupsCleared?: number } | undefined; return { run: r.id, mode: r.mode, level: r.level ?? 0, score: state?.score ?? 0, moves: state?.moves ?? state?.groupsCleared ?? 0, rewardUsed: r.rewardUsed }; };
  const [adState, setAdState] = useState(ads.getState);
  const [transitioning, setTransitioning] = useState(false);
  const transitionLock = useRef(false);
  const player = useAudioPlayer(require('./assets/move.wav'));
  const audio = useRef(player); audio.current = player;
  const storageKey = `rice-arcade:${slug}:v1`;
  const writer = useRef(createSaveWriter(AsyncStorage, storageKey, () => setNotice('Progress could not be saved. Free some device storage and keep this app open.'))).current;
  const pendingWrite = useRef<ReturnType<typeof setTimeout> | null>(null);
  const mayWrite = useRef(false);
  const commit = useCallback((next: ArcadeSave) => {
    mayWrite.current = true;
    latest.current = next;
    setData(next);
    if (!pendingWrite.current) pendingWrite.current = setTimeout(() => {
      pendingWrite.current = null;
      void writer(latest.current);
    }, 500);
  }, [writer]);

  useEffect(() => {
    let live = true;
    void AsyncStorage.getItem(storageKey).then(text => {
      if (!live) return;
      const restored = parseSave(text);
      if (!restored) setNotice('The saved file could not be read. Start a fresh run.');
      latest.current = restored ?? emptySave();
      mayWrite.current = true;
      setData(latest.current);
      setLoaded(true);
    }).catch(() => { if (live) { setNotice('Saved progress is unavailable. New games still work.'); setLoaded(true); } });
    const unsubscribe = ads.subscribe(setAdState);
    const unsubscribeEvents = ads.subscribeEvents((name, fields) => { void telemetry.record(name, fields); });
    void telemetry.ready.then(() => { if (live) setTracking(telemetry.isEnabled()); void telemetry.record('session_start', { platform: Platform.OS, version: '0.1.0' }); });
    const heartbeat = setInterval(() => { if (activity.current && AppState.currentState !== 'background') { void telemetry.record('session_active', { seconds: 15 }); const activeRun = latest.current.runs[currentMode.current]; if (activeRun) void telemetry.record('run_progress', runFields(activeRun)); } void telemetry.flush(); }, 15000);
    void ads.initializeAfterConsent();
    const subscription = AppState.addEventListener('change', status => {
      setForeground(status === 'active');
      if (status !== 'active') {
        setPaused(true);
        void telemetry.flush();
        if (live && mayWrite.current) void writer(latest.current);
      } else void ads.initializeAfterConsent().then(() => ads.preload());
    });
    return () => {
      live = false;
      subscription.remove(); unsubscribe(); unsubscribeEvents(); clearInterval(heartbeat); void telemetry.flush(); ads.dispose();
      if (pendingWrite.current) clearTimeout(pendingWrite.current);
      if (mayWrite.current) void writer(latest.current);
    };
  }, [ads, storageKey, writer, telemetry]);

  const onSave = useCallback((saved: unknown) => {
    const run = latest.current.runs[currentMode.current];
    if (!run || run.ended) return;
    const score = saved && typeof saved === 'object' && 'score' in saved && typeof saved.score === 'number' ? saved.score : 0;
    const previous = run.saved && typeof run.saved === 'object' && 'score' in run.saved ? Number(run.saved.score) : 0;
    if (score > previous && latest.current.settings.sound) {
      void audio.current.seekTo(0).then(() => audio.current.play()).catch(() => {});
    }
    const playing = saved && typeof saved === 'object' && (('ended' in saved && saved.ended === false) || ('remainingMs' in saved && typeof saved.remainingMs === 'number' && saved.remainingMs > 0));
    const reachedGoal = run.mode === 'journey' && levelGoal(slug, run.level!, saved).complete;
    const completed = reachedGoal && completionAllowed(run.level!, latest.current.levelFailures[run.level!] ?? 0, run.rewardUsed);
    if (reachedGoal) void telemetry.record('run_end', { ...runFields(run, saved), outcome: completed ? 'win' : 'loss', reason: completed ? 'goal' : 'progression_rule' });
    if (completed && !run.counted) ads.roundCompleted();
    commit(updateRun(latest.current, { ...run, saved, ended: reachedGoal || (playing ? false : run.ended), ...(run.mode === 'journey' ? { completed: !!completed } : {}) }));
  }, [commit, slug, ads]);
  const onEnd = useCallback(() => {
    const run = latest.current.runs[currentMode.current];
    if (!run || run.ended) return;
    void telemetry.record('run_end', { ...runFields(run), outcome: 'loss', reason: 'board_or_timer' });
    if (!run.counted) ads.roundCompleted();
    commit(updateRun(latest.current, { ...run, ended: true }));
  }, [ads, commit]);
  const run = data.runs[mode];
  const today = localDate();
  const begin = (nextMode: Mode, resume = false, selectedLevel?: number) => {
    const outgoing = latest.current.runs[currentMode.current];
    if (!resume && outgoing && !outgoing.ended) void telemetry.record('run_exit', { ...runFields(outgoing), reason: 'new_run' });
    currentMode.current = nextMode;
    setMode(nextMode);
    const previous = latest.current.runs[nextMode];
    if (!resume || !previous || (nextMode === 'daily' && previous.date !== localDate())) {
      const date = localDate();
      const level = Math.max(1, Math.min(selectedLevel ?? latest.current.stats.unlockedLevel, latest.current.stats.unlockedLevel, trail.targets.length));
      const next: Run = { id: `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`, seed: nextMode === 'daily' ? dailySeed(slug, date) : nextMode === 'journey' ? dailySeed(slug + '-journey', String(level)) : Math.floor(Math.random() * 0xffffffff), mode: nextMode, date, ended: false, rewardUsed: false, counted: false, ...(nextMode === 'journey' ? { level, completed: false } : {}) };
      commit({ ...latest.current, runs: { ...latest.current.runs, [nextMode]: next } });
      void telemetry.record('run_start', runFields(next));
    }
    if (resume && previous) void telemetry.record('run_resume', runFields(previous));
    void telemetry.flush();
    setRewardToken(0); setPaused(false); setBoostOpen(false); setLevelsOpen(false); setScreen('play');
    if (!latest.current.settings.tutorialSeen) setHelp(true);
    void ads.initializeAfterConsent().then(() => ads.preload());
  };
  const replay = async () => {
    if (transitionLock.current) return;
    transitionLock.current = true; setTransitioning(true);
    try {
      const previous = latest.current.runs[currentMode.current];
      await ads.showInterstitialAtNaturalBreak({ atResults: true, level: previous?.mode === 'journey' ? (previous.completed ? previous.level : 0) : undefined });
      if (previous?.completed && previous.level === trail.targets.length) setScreen('home');
      else begin(currentMode.current, false, previous?.mode === 'journey' ? previous.level! + Number(!!previous.completed) : undefined);
    } finally { transitionLock.current = false; setTransitioning(false); }
  };
  const reward = async () => {
    const target = latest.current.runs[currentMode.current];
    if (!target || target.completed || (!target.ended && !boostAvailable(slug, target.saved)) || target.rewardUsed || transitionLock.current) return;
    transitionLock.current = true; setTransitioning(true);
    void telemetry.record('boost_request', runFields(target));
    try {
      const result = await ads.showRewardedIfReady(() => {
        const current = latest.current.runs[target.mode];
        if (!current || current.id !== target.id || current.rewardUsed || (!current.ended && !boostAvailable(slug, current.saved))) return;
        const completed = current.mode === 'journey' && levelGoal(slug, current.level!, current.saved).complete && completionAllowed(current.level!, latest.current.levelFailures[current.level!] ?? 0, true);
        commit(updateRun(latest.current, { ...current, rewardUsed: true, ended: completed, ...(current.mode === 'journey' ? { completed } : {}) }));
        void telemetry.record('boost_earned', runFields(current));
        if (completed) void telemetry.record('run_end', { ...runFields(current), rewardUsed: true, outcome: 'win', reason: 'boost_goal' });
        setRewardToken(value => value + 1);
      });
      if (!result.earned) setNotice('No reward was earned. You can start a new game anytime.');
    } finally { transitionLock.current = false; setTransitioning(false); setBoostOpen(false); }
  };
  activity.current = screen === 'play' && !paused && !settings && !help && !privacy && !boostOpen && !run?.ended && !adState.busy;
  useEffect(() => { if (screen === 'play' && run && !run.completed && !run.rewardUsed && (run.ended || boostAvailable(slug, run.saved))) void telemetry.record('boost_offer', runFields(run)); }, [screen, run?.id, run?.ended, run?.rewardUsed, !!run && boostAvailable(slug, run.saved)]);
  useEffect(() => { if (screen === 'home' && run && !run.ended) { void telemetry.record('run_exit', { ...runFields(run), reason: 'home' }); void telemetry.flush(); } }, [screen]);
  const closeTutorial = () => { setHelp(false); commit({ ...latest.current, settings: { ...latest.current.settings, tutorialSeen: true } }); };
  const button = (label: string, action: () => void, primary = false, disabled = false) => <Pressable key={label} accessibilityRole="button" disabled={disabled} onPress={action} style={({ pressed }) => [styles.button, { borderColor: accent }, primary && { backgroundColor: accent }, pressed && { opacity: 0.7 }, disabled && { opacity: 0.4 }]}><Text style={[styles.buttonText, { color: primary ? theme.background : accent }]}>{label}</Text></Pressable>;
  const iconButton = (label: string, icon: string, action: () => void, disabled = false) => <Pressable accessibilityRole="button" accessibilityLabel={label} disabled={disabled} onPress={action} style={({ pressed }) => [styles.button, { borderColor: accent, width: 48, height: 48, paddingHorizontal: 0, paddingVertical: 0 }, pressed && { opacity: .7 }, disabled && { opacity: .4 }]}><Text style={{ color: accent, fontSize: 24, fontWeight: '700' }}>{icon}</Text></Pressable>;
  const modal = (visible: boolean, title: string, children: React.ReactNode, close: () => void) => <Modal visible={visible} transparent animationType="fade" onRequestClose={close}><View style={styles.scrim}><View accessibilityViewIsModal style={[styles.dialog, { backgroundColor: background }]}><View style={styles.dialogContent}><Text style={[styles.dialogTitle, { color: accent }]}>{title}</Text>{children}</View></View></View></Modal>;
  return <ThemeContext.Provider value={{ theme, softTiles: true }}><SafeAreaView style={[styles.safe, { backgroundColor: background }, { height: viewport.height, maxHeight: viewport.height }]}><Image pointerEvents="none" accessible={false} source={sceneArt[slug]} style={[StyleSheet.absoluteFill, { width: '100%', height: '100%' }]} resizeMode="cover" />
    <Music slug={slug} playing={loaded && data.settings.music && foreground && screen === 'play' && !paused && !settings && !help && !privacy && !boostOpen && !run?.ended && !adState.busy && !transitioning} />
    <View style={[styles.page, { flex: 1, minHeight: 0, padding: 8, paddingBottom: 8 }]}>
      <View style={[styles.content, { flex: 1, minHeight: 0, gap: 8, maxHeight: 844, maxWidth: slug === 'grid-foundry' && viewport.width > viewport.height && viewport.height < 500 ? 900 : 430, alignSelf: 'center' }]}>
        <View style={styles.header}><View style={styles.brand}><Text style={[styles.eyebrow, { color: accent }]}>{fitPlay ? mode === 'daily' ? 'DAILY PUZZLE' : mode === 'journey' ? `ZONE ${levelInfo(slug, run?.level ?? 1).zone} / 10 · LEVEL ${levelInfo(slug, run?.level ?? 1).stage} / 10` : '' : ''}</Text><Text numberOfLines={1} adjustsFontSizeToFit style={[styles.title, { fontSize: 22, marginTop: 2 }]}>{title}</Text></View>{fitPlay ? <>{iconButton('Pause', 'Ⅱ', () => setPaused(true), !!run?.ended)}{iconButton('Settings', '⚙', () => setSettings(true))}</> : button('Settings', () => setSettings(true))}</View>
        {!!notice && <Pressable accessibilityRole="button" accessibilityLabel={`${notice} Dismiss notice`} onPress={() => setNotice('')}><Text accessibilityLiveRegion="polite" style={styles.notice}>{notice}</Text></Pressable>}
        {!loaded ? <Text style={styles.copy}>Loading…</Text> : screen === 'home' ? <>
          <View style={[styles.welcome, { flex: 1, minHeight: 64, maxHeight: 240, padding: 0, overflow: 'hidden' }]}>
            <Image source={sceneArt[slug]} accessibilityLabel={theme.name + ' illustration'} style={[StyleSheet.absoluteFill, { width: '100%', height: '100%' }]} resizeMode="cover" />
            <View style={{ marginTop: 'auto', padding: 12, backgroundColor: theme.surface + 'ed', alignItems: 'center' }}><Text style={[styles.eyebrow, { color: accent }]}>BEST SCORE TO BEAT</Text><Text adjustsFontSizeToFit numberOfLines={1} style={[styles.best, { color: accent, fontSize: 44, textAlign: 'center' }]}>{data.stats.best.toLocaleString()}</Text></View>
          </View>
          {data.runs.journey && !data.runs.journey.completed && button(`${data.runs.journey.ended ? 'View result -' : 'Continue'} zone ${levelInfo(slug, data.runs.journey.level!).zone} · level ${levelInfo(slug, data.runs.journey.level!).stage}`, () => begin('journey', true), true)}
          {button(`${trail.name} · ${Math.min(data.stats.unlockedLevel - 1, trail.targets.length)} / ${trail.targets.length} complete`, () => { setLevelPage(Math.floor((Math.min(data.stats.unlockedLevel, trail.targets.length) - 1) / LEVELS_PER_ZONE)); setLevelsOpen(true); }, !data.runs.journey || data.runs.journey.ended)}
          {data.runs.normal && button(data.runs.normal.ended ? 'View last result' : 'Continue game', () => begin('normal', true), true)}
          <View style={styles.homeRow}><View style={{ flex: 1 }}>{button('New game', () => begin('normal'), !data.runs.normal)}</View><View style={{ flex: 1 }}>{button('How to play', () => setHelp(true))}</View></View>
          {button(data.runs.daily?.date === today && !data.runs.daily.ended ? 'Continue daily challenge' : 'Daily challenge', () => begin('daily', data.runs.daily?.date === today))}
        </> : run ? <>
          <Game key={run.id} seed={run.seed} saved={run.saved} onSave={onSave} onEnd={onEnd} paused={paused || settings || help || privacy || boostOpen || !!run.ended || adState.busy || transitioning} rewardToken={rewardToken} haptics={data.settings.haptics} bestScore={data.stats.best} goal={mode === 'journey' ? levelGoal(slug, run.level!, run.saved) : undefined} />
          {!run.ended && !run.rewardUsed && boostAvailable(slug, run.saved) && button(slug === 'grid-foundry' ? 'Optional boost · clear 2 rows' : slug === 'merge-drift' ? 'Optional boost · free 2 spaces' : 'Optional boost · +20 seconds', () => setBoostOpen(true))}
        </> : null}

      </View>
    </View>
    {modal(boostOpen && !adState.busy, 'Video boost', <>
      <Text style={styles.copy}>{rewardDescription}</Text>
      <Text style={styles.small}>This uses your one boost or continue for this run. Your game is paused while you decide.</Text>
      {ads.isReady('rewarded') ? button('Watch video · earn boost', () => { void reward(); }, true, transitioning) : <><Text style={styles.copy}>{adState.lastResult === 'unsupported' ? 'Video rewards are available in the Android app. This browser preview has no ads.' : 'No reward video is available right now. You can keep playing.'}</Text>{adState.lastResult !== 'unsupported' && button('Try loading video again', () => { void ads.initializeAfterConsent().then(() => ads.preload()); }, false, adState.busy)}</>}
      {button('Keep playing', () => setBoostOpen(false), false, transitioning)}
    </>, () => { if (!transitioning) setBoostOpen(false); })}
    {modal(paused && screen === 'play' && !settings && !help && !privacy && !boostOpen && !run?.ended && !adState.busy, 'Paused', <>
      <Text style={styles.copy}>Your game is paused. Resume when you’re ready.</Text>{button('Resume', () => setPaused(false), true)}
      {button('Restart', () => begin(mode, false, run?.level))}{button('Home · save progress', () => { setScreen('home'); setPaused(false); })}
    </>, () => setPaused(false))}
    {modal(fitPlay && !!run?.ended && !settings && !privacy && !help && !adState.busy, run?.completed ? run.level === trail.targets.length ? 'Journey complete!' : run.level! % 10 === 0 ? `Zone ${levelInfo(slug, run.level!).zone} complete!` : `Level ${levelInfo(slug, run.level!).stage} complete!` : mode === 'journey' ? 'Level ended' : 'Game over', <>
      {mode === 'journey' && <Text style={styles.copy}>{run?.completed ? 'Goal reached. Your progress is saved.' : `${levelGoal(slug, run!.level!, run?.saved).label}. Try a different approach—the puzzle stays the same.`}</Text>}
      {run?.saved && typeof run.saved === 'object' && 'score' in run.saved && <View style={styles.summary}><Text style={styles.eyebrow}>THIS RUN</Text><Text style={[styles.best, { color: accent }]}>{Number(run.saved.score).toLocaleString()}</Text><Text style={[styles.eyebrow, { textAlign: 'center' }]}>BEST SCORE</Text><Text style={[styles.best, { color: accent, fontSize: 28, textAlign: 'center' }]}>{data.stats.best.toLocaleString()}</Text></View>}
      {run?.completed && run.level! < trail.targets.length && <Text style={styles.copy}>Up next: {levelGoal(slug, run.level! + 1).label.toLowerCase()}.</Text>}
      {button((run?.completed ? run.level === trail.targets.length ? 'Back to your journey' : run.level! % 10 === 0 ? 'Next zone' : 'Next level' : mode === 'journey' ? 'Retry level' : 'Play again') + (ads.isReady('interstitial') && (mode !== 'journey' || (!!run?.completed && run.level! % 3 === 0)) ? ' · may show an ad' : ''), () => { void replay(); }, true, transitioning)}
      {button('Back to home', () => setScreen('home'), false, transitioning)}
      {!run?.completed && !run?.rewardUsed && <><Text style={styles.small}>{rewardDescription}</Text>{ads.isReady('rewarded') ? button('Watch video · earn continue', () => { void reward(); }, false, transitioning) : <><Text style={styles.small}>No video is ready. Retry loading or play again.</Text>{adState.lastResult !== 'unsupported' && button('Load reward video', () => { void ads.initializeAfterConsent().then(() => ads.preload()); }, false, adState.busy)}</>}</>}
    </>, () => setScreen('home'))}
    {modal(levelsOpen, `Zone ${levelPage + 1} / ${ZONE_COUNT}`, <>
      <Text style={[styles.copy, { fontWeight: '700' }]}>{levelInfo(slug, levelPage * 10 + 1).name}</Text>
      <Text style={styles.small}>10 levels per zone. Reach each goal to unlock the next stop on your journey.</Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6 }}>
        {trail.targets.slice(levelPage * 10, levelPage * 10 + 10).map((_, offset) => {
          const level = levelPage * 10 + offset + 1;
          const info = levelInfo(slug, level);
          const locked = level > data.stats.unlockedLevel;
          return <Pressable key={level} accessibilityRole="button" accessibilityLabel={`Zone ${info.zone} level ${info.stage}, ${levelGoal(slug, level).label}${locked ? ', locked' : ''}`} disabled={locked} onPress={() => begin('journey', false, level)} style={({ pressed }) => [{ width: '48%', minHeight: 44, padding: 5, borderRadius: 12, borderWidth: 1, borderColor: accent, alignItems: 'center', justifyContent: 'center', backgroundColor: level === data.stats.unlockedLevel ? theme.surface : 'transparent', opacity: locked ? .4 : pressed ? .7 : 1 }]}>
            <Text style={styles.buttonText}>{level < data.stats.unlockedLevel ? '✓ ' : ''}Level {info.stage}</Text>
          </Pressable>;
        })}
      </View>
      <View style={styles.homeRow}>{button('Previous zone', () => setLevelPage(value => value - 1), false, levelPage === 0)}{button('Next zone', () => setLevelPage(value => value + 1), false, levelPage === ZONE_COUNT - 1)}</View>
      {button('Back', () => setLevelsOpen(false))}
    </>, () => setLevelsOpen(false))}
    {modal(settings, 'Settings', <>
      <View style={styles.setting}><Text style={styles.copy}>Music</Text><Switch accessibilityLabel="Music" value={data.settings.music} onValueChange={music => commit({ ...latest.current, settings: { ...latest.current.settings, music } })} trackColor={{ true: accent }} /></View>
      <View style={styles.setting}><Text style={styles.copy}>Sound</Text><Switch accessibilityLabel="Sound" value={data.settings.sound} onValueChange={sound => commit({ ...latest.current, settings: { ...latest.current.settings, sound } })} trackColor={{ true: accent }} /></View>
      <View style={styles.setting}><Text style={styles.copy}>Haptics</Text><Switch accessibilityLabel="Haptics" value={data.settings.haptics} onValueChange={haptics => commit({ ...latest.current, settings: { ...latest.current.settings, haptics } })} trackColor={{ true: accent }} /></View>
      {button('How to play', () => { setSettings(false); setHelp(true); })}
      {button('Privacy & support', () => { setSettings(false); setPrivacy(true); })}
      {button('Privacy choices', () => { void ads.showPrivacyOptions().then(result => { if (result.code === 'unsupported') setNotice('Advertising is unavailable in this browser preview.'); }); }, false, adState.busy)}
      {button('Done', () => setSettings(false), true)}
    </>, () => setSettings(false))}
    {modal(help, 'How to play', <>{tutorial.map((line, index) => <Text key={line} style={styles.tutorial}>{index + 1}. {line}</Text>)}{button('Let’s play', closeTutorial, true)}{button('Skip tutorial', closeTutorial)}</>, closeTutorial)}
    {modal(privacy, 'Privacy & support', <>
      {privacyPage === 0 && <><View style={styles.setting}><Text style={styles.copy}>Share gameplay analytics</Text><Switch accessibilityLabel="Share gameplay analytics" value={tracking} onValueChange={value => { setTracking(value); void telemetry.setEnabled(value); }} /></View><Text style={styles.copy}>Progress is saved on this device. Optional gameplay analytics sends a random installation ID, session activity, level results and ad outcomes to our studio. No name or email is collected. Events expire after 90 days. Turning this off clears unsent events.</Text></>}
      {privacyPage === 1 && <Text style={styles.copy}>Android builds include Google AdMob. With permission where required, its SDK may process device identifiers, approximate location, ad interactions and diagnostic information to serve and measure ads. Privacy choices are available in Settings. Core gameplay works without ads.</Text>}
      {privacyPage === 2 && <><Text style={styles.copy}>Google’s privacy policy explains its advertising data practices.</Text>{button('Google privacy policy', () => { void Linking.openURL('https://policies.google.com/privacy').catch(() => setNotice('Could not open the privacy policy.')); })}</>}
      {privacyPage === 3 && <Text selectable style={styles.copy}>Support: {process.env.EXPO_PUBLIC_SUPPORT_EMAIL || 'The support website will be available with the published release.'}</Text>}
      <Text style={styles.small}>{privacyPage + 1} / 4</Text><View style={styles.homeRow}>{button('Previous', () => setPrivacyPage(value => value - 1), false, privacyPage === 0)}{button('Next', () => setPrivacyPage(value => value + 1), false, privacyPage === 3)}</View><Text selectable style={styles.small}>App: {slug} · Version 0.1.0</Text>{button('Close', () => setPrivacy(false), true)}
    </>, () => setPrivacy(false))}
  </SafeAreaView></ThemeContext.Provider>;
}

const sceneArt: Record<string, ReturnType<typeof require>> = {
  'grid-foundry': require('./assets/workshop.png'),
  'merge-drift': require('./assets/ocean.png'),
  'color-cascade': require('./assets/garden.png'),
};

const makeStyles = (theme: Theme) => StyleSheet.create({
  homeRow: { flexDirection: 'row', gap: 8, justifyContent: 'space-between' },
  welcome: { padding: 12, borderRadius: 30, backgroundColor: theme.surface, gap: 12 },
  heroTop: { paddingHorizontal: 8, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  themeLabel: { color: theme.accent, fontSize: 10, letterSpacing: 1.4, fontWeight: '800' },
  sparkles: { color: theme.accent, fontSize: 22 },
  scene: { width: '100%', aspectRatio: 1.6, borderRadius: 20 },
  safe: { flex: 1, overflow: 'hidden' }, page: { flexGrow: 1, padding: 12, paddingBottom: 30 }, content: { width: '100%', maxWidth: 494, alignSelf: 'center', gap: 16, padding: 12, borderRadius: 28, backgroundColor: theme.background + 'ed' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 }, brand: { flex: 1 }, title: { color: theme.ink, fontWeight: '800', fontSize: 28, marginTop: 6 },
  eyebrow: { fontSize: 10, letterSpacing: 1.6, fontWeight: '700' }, subtitle: { color: theme.ink, fontSize: 23, lineHeight: 32, marginVertical: 4, paddingHorizontal: 8 },
  summary: { padding: 10, gap: 3, borderRadius: 24, backgroundColor: theme.surface }, best: { color: theme.ink, fontSize: 40, fontWeight: '800', fontVariant: ['tabular-nums'] },
  copy: { color: theme.ink, fontSize: 15, lineHeight: 23 }, small: { color: theme.muted, fontSize: 12, lineHeight: 19 },
  button: { borderWidth: 1, borderRadius: 14, minHeight: 48, paddingHorizontal: 15, paddingVertical: 13, justifyContent: 'center', alignItems: 'center' },
  buttonText: { fontSize: 14, fontWeight: '700', textAlign: 'center' },
  links: { flexDirection: 'row', gap: 12, justifyContent: 'center', marginTop: 12, flexWrap: 'wrap' },
  notice: { backgroundColor: '#273b50', color: '#f0e4ba', padding: 14, borderRadius: 12, lineHeight: 21 },
  scrim: { flex: 1, backgroundColor: '#000b', padding: 12, alignItems: 'center', justifyContent: 'center' }, dialog: { width: '100%', maxWidth: 430, maxHeight: '100%', borderRadius: 24, borderWidth: 1, borderColor: theme.edge },
  dialogContent: { padding: 16, gap: 10 }, dialogTitle: { fontSize: 26, fontWeight: '800' }, tutorial: { color: theme.ink, fontSize: 17, lineHeight: 27 }, setting: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
});
