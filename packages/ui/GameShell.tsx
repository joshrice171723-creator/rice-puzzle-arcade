import React, { useCallback, useEffect, useRef, useState } from 'react';
import { AppState, Image, Linking, Modal, Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useAudioPlayer } from 'expo-audio';
import { gameTheme, Theme, ThemeContext } from './themes';
import { createAdsService } from '../ads';
import { ArcadeSave, createSaveWriter, dailySeed, emptySave, localDate, Mode, parseSave, Run, updateRun } from '../game-utils/storage';

type GameProps = { seed: number; paused: boolean; saved?: unknown; onSave: (state: unknown) => void; onEnd: () => void; rewardToken: number; haptics: boolean };
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
  const [mode, setMode] = useState<Mode>('normal');
  const currentMode = useRef<Mode>('normal');
  const [paused, setPaused] = useState(false);
  const [settings, setSettings] = useState(false);
  const [help, setHelp] = useState(false);
  const [privacy, setPrivacy] = useState(false);
  const [notice, setNotice] = useState('');
  const [rewardToken, setRewardToken] = useState(0);
  const ads = useRef(createAdsService(slug)).current;
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
    void ads.initializeAfterConsent();
    const subscription = AppState.addEventListener('change', status => {
      if (status !== 'active') {
        setPaused(true);
        if (live && mayWrite.current) void writer(latest.current);
      } else ads.preload();
    });
    return () => {
      live = false;
      subscription.remove(); unsubscribe(); ads.dispose();
      if (pendingWrite.current) clearTimeout(pendingWrite.current);
      if (mayWrite.current) void writer(latest.current);
    };
  }, [ads, storageKey, writer]);

  const onSave = useCallback((saved: unknown) => {
    const run = latest.current.runs[currentMode.current];
    if (!run) return;
    const score = saved && typeof saved === 'object' && 'score' in saved && typeof saved.score === 'number' ? saved.score : 0;
    const previous = run.saved && typeof run.saved === 'object' && 'score' in run.saved ? Number(run.saved.score) : 0;
    if (score > previous && latest.current.settings.sound) {
      void audio.current.seekTo(0).then(() => audio.current.play()).catch(() => {});
    }
    const playing = saved && typeof saved === 'object' && (('ended' in saved && saved.ended === false) || ('remainingMs' in saved && typeof saved.remainingMs === 'number' && saved.remainingMs > 0));
    commit(updateRun(latest.current, { ...run, saved, ended: playing ? false : run.ended }));
  }, [commit]);
  const onEnd = useCallback(() => {
    const run = latest.current.runs[currentMode.current];
    if (!run || run.ended) return;
    if (!run.counted) ads.roundCompleted();
    commit(updateRun(latest.current, { ...run, ended: true }));
  }, [ads, commit]);
  const run = data.runs[mode];
  const today = localDate();
  const begin = (nextMode: Mode, resume = false) => {
    currentMode.current = nextMode;
    setMode(nextMode);
    const previous = latest.current.runs[nextMode];
    if (!resume || !previous || (nextMode === 'daily' && previous.date !== localDate())) {
      const date = localDate();
      const next: Run = { id: `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`, seed: nextMode === 'daily' ? dailySeed(slug, date) : Math.floor(Math.random() * 0xffffffff), mode: nextMode, date, ended: false, rewardUsed: false, counted: false };
      commit({ ...latest.current, runs: { ...latest.current.runs, [nextMode]: next } });
    }
    setRewardToken(0); setPaused(false); setScreen('play');
    if (!latest.current.settings.tutorialSeen) setHelp(true);
    ads.preload();
  };
  const replay = async () => {
    if (transitionLock.current) return;
    transitionLock.current = true; setTransitioning(true);
    try {
      await ads.showInterstitialAtNaturalBreak({ atResults: true });
      begin(currentMode.current);
    } finally { transitionLock.current = false; setTransitioning(false); }
  };
  const reward = async () => {
    const target = latest.current.runs[currentMode.current];
    if (!target || !target.ended || target.rewardUsed || transitionLock.current) return;
    transitionLock.current = true; setTransitioning(true);
    try {
      const result = await ads.showRewardedIfReady(() => {
        const current = latest.current.runs[target.mode];
        if (!current || current.id !== target.id || current.rewardUsed || !current.ended) return;
        commit(updateRun(latest.current, { ...current, rewardUsed: true, ended: false }));
        setRewardToken(value => value + 1);
      });
      if (!result.earned) setNotice('No reward was earned. You can start a new game anytime.');
    } finally { transitionLock.current = false; setTransitioning(false); }
  };
  const closeTutorial = () => { setHelp(false); commit({ ...latest.current, settings: { ...latest.current.settings, tutorialSeen: true } }); };
  const button = (label: string, action: () => void, primary = false, disabled = false) => <Pressable accessibilityRole="button" disabled={disabled} onPress={action} style={({ pressed }) => [styles.button, { borderColor: accent }, primary && { backgroundColor: accent }, pressed && { opacity: 0.7 }, disabled && { opacity: 0.4 }]}><Text style={[styles.buttonText, { color: primary ? theme.background : accent }]}>{label}</Text></Pressable>;
  const openSite = (path: string) => {
    const base = process.env.EXPO_PUBLIC_WEBSITE_URL;
    if (base && /^https:\/\//.test(base)) void Linking.openURL(`${base.replace(/\/$/, '')}/${path}`).catch(() => setNotice('This link could not be opened. Please try again later.'));
    else setPrivacy(true);
  };
  const modal = (visible: boolean, title: string, children: React.ReactNode, close: () => void) => <Modal visible={visible} transparent animationType="fade" onRequestClose={close}><View style={styles.scrim}><View accessibilityViewIsModal style={[styles.dialog, { backgroundColor: background }]}><ScrollView contentContainerStyle={styles.dialogContent}><Text style={[styles.dialogTitle, { color: accent }]}>{title}</Text>{children}</ScrollView></View></View></Modal>;
  return <ThemeContext.Provider value={{ theme, softTiles: true }}><SafeAreaView style={[styles.safe, { backgroundColor: background }]}><Image pointerEvents="none" accessible={false} source={sceneArt[slug]} style={StyleSheet.absoluteFill} resizeMode="cover" />
    <ScrollView contentContainerStyle={styles.page} keyboardShouldPersistTaps="handled">
      <View style={styles.content}>
        <View style={styles.header}><View style={styles.brand}><Text style={[styles.eyebrow, { color: accent }]}>RICE PUZZLE ARCADE</Text><Text style={styles.title}>{title}</Text></View>{button('Settings', () => setSettings(true))}</View>
        {!!notice && <Pressable accessibilityRole="button" accessibilityLabel={`${notice} Dismiss notice`} onPress={() => setNotice('')}><Text accessibilityLiveRegion="polite" style={styles.notice}>{notice}</Text></Pressable>}
        {!loaded ? <Text style={styles.copy}>Opening your arcade…</Text> : screen === 'home' ? <>
          <View style={styles.welcome}>
            <View style={styles.heroTop}><Text style={styles.themeLabel}>{theme.name.toUpperCase()}</Text><Text style={styles.sparkles}>✦ · ✦</Text></View>
            <Image source={sceneArt[slug]} accessibilityLabel={theme.name + " illustration"} style={styles.scene} resizeMode="cover" />
            <Text style={styles.subtitle}>{theme.greeting}</Text>
            <Text style={styles.copy}>{subtitle}</Text>
          </View>
          <View style={styles.summary}><Text style={[styles.eyebrow, { color: accent }]}>YOUR PERSONAL BEST</Text><Text style={styles.best}>{data.stats.best.toLocaleString()}</Text><Text style={styles.copy}>{data.stats.games} games played{data.stats.highestTile > 0 ? ` · Highest tile ${data.stats.highestTile.toLocaleString()}` : ''}</Text></View>
          {data.runs.normal && button(data.runs.normal.ended ? 'View last result' : 'Continue game', () => begin('normal', true), true)}
          {button('New game', () => begin('normal'), !data.runs.normal)}
          {button(data.runs.daily?.date === today && !data.runs.daily.ended ? 'Continue daily challenge' : 'Daily challenge', () => begin('daily', data.runs.daily?.date === today))}
          <Text style={styles.small}>A fresh puzzle every day · {today}{data.stats.dailyDate === today ? ` · Best ${data.stats.dailyBest.toLocaleString()}` : ''}</Text>
          {button('How to play', () => setHelp(true))}
          <Text style={styles.small}>Play offline. No account needed. Optional reward videos may be available after a run.</Text>
        </> : run ? <>
          <Image source={sceneArt[slug]} accessible={false} style={styles.playScene} resizeMode="cover" />
          <View style={styles.toolbar}><Text style={[styles.eyebrow, { color: accent }]}>{mode === 'daily' ? `DAILY · ${run.date}` : 'FREE PLAY'}</Text>{button('Pause', () => setPaused(true), false, run.ended)}</View>
          <Game key={run.id} seed={run.seed} saved={run.saved} onSave={onSave} onEnd={onEnd} paused={paused || settings || help || privacy || adState.busy || transitioning} rewardToken={rewardToken} haptics={data.settings.haptics} />
          {run.ended && <View style={styles.results}><Text accessibilityRole="header" accessibilityLiveRegion="polite" style={[styles.dialogTitle, { color: accent }]}>A good run.</Text><Text style={styles.copy}>Personal best: {data.stats.best.toLocaleString()}</Text>
            {!run.rewardUsed && <><Text style={styles.copy}>{rewardDescription}</Text>{ads.isReady('rewarded') ? button('Watch video · earn continue', () => { void reward(); }, false, transitioning || adState.busy) : <Text style={styles.small}>No reward video is available. Replay is always free.</Text>}</>}
            {button(ads.isReady('interstitial') ? 'Replay · may show an ad' : 'Replay', () => { void replay(); }, true, transitioning || adState.busy)}
            {button('Back to home', () => setScreen('home'), false, transitioning || adState.busy)}
          </View>}
        </> : null}
        <View style={styles.links}>{button('Privacy', () => openSite('privacy'))}{button('Help & support', () => openSite('support'))}</View>
      </View>
    </ScrollView>
    {modal(paused && screen === 'play' && !settings && !help && !privacy && !run?.ended && !adState.busy, 'Take a breath.', <>
      <Text style={styles.copy}>Your game is paused. Resume when you’re ready.</Text>{button('Resume', () => setPaused(false), true)}
      {button('Restart', () => begin(mode))}{button('Home · save progress', () => { setScreen('home'); setPaused(false); })}
    </>, () => setPaused(false))}
    {modal(settings, 'Settings', <>
      <View style={styles.setting}><Text style={styles.copy}>Sound</Text><Switch accessibilityLabel="Sound" value={data.settings.sound} onValueChange={sound => commit({ ...latest.current, settings: { ...latest.current.settings, sound } })} trackColor={{ true: accent }} /></View>
      <View style={styles.setting}><Text style={styles.copy}>Haptics</Text><Switch accessibilityLabel="Haptics" value={data.settings.haptics} onValueChange={haptics => commit({ ...latest.current, settings: { ...latest.current.settings, haptics } })} trackColor={{ true: accent }} /></View>
      {button('How to play', () => { setSettings(false); setHelp(true); })}
      {button('Privacy choices', () => { void ads.showPrivacyOptions().then(result => { if (result.code === 'unsupported') setNotice('Advertising is unavailable in this browser preview.'); }); }, false, adState.busy)}
      {button('Done', () => setSettings(false), true)}
    </>, () => setSettings(false))}
    {modal(help, 'Find your rhythm', <>{tutorial.map((line, index) => <Text key={line} style={styles.tutorial}>{index + 1}. {line}</Text>)}{button('Let’s play', closeTutorial, true)}{button('Skip tutorial', closeTutorial)}</>, closeTutorial)}
    {modal(privacy, 'Privacy & support', <>
      <Text style={styles.copy}>Scores, games and preferences are saved on this device. There is no player account or game server. You can remove local progress by clearing app storage.</Text>
      <Text style={styles.copy}>Android builds include Google AdMob. With permission where required, its SDK may process device identifiers, approximate location, ad interactions and diagnostic information to serve and measure ads. Privacy choices are available in Settings. Core gameplay works without ads.</Text>
      <Text style={styles.copy}>Google’s privacy policy explains its advertising data practices.</Text>{button('Google privacy policy', () => { void Linking.openURL('https://policies.google.com/privacy').catch(() => setNotice('Could not open the privacy policy.')); })}
      <Text selectable style={styles.copy}>Support: {process.env.EXPO_PUBLIC_SUPPORT_EMAIL || 'The support website will be available with the published release.'}</Text>
      <Text selectable style={styles.small}>App: {slug} · Version 0.1.0</Text>{button('Close', () => setPrivacy(false), true)}
    </>, () => setPrivacy(false))}
  </SafeAreaView></ThemeContext.Provider>;
}

const sceneArt: Record<string, ReturnType<typeof require>> = {
  'grid-foundry': require('./assets/workshop.png'),
  'merge-drift': require('./assets/ocean.png'),
  'color-cascade': require('./assets/garden.png'),
};

const makeStyles = (theme: Theme) => StyleSheet.create({
  welcome: { padding: 12, borderRadius: 30, backgroundColor: theme.surface, gap: 12 },
  heroTop: { paddingHorizontal: 8, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  themeLabel: { color: theme.accent, fontSize: 10, letterSpacing: 1.4, fontWeight: '800' },
  sparkles: { color: theme.accent, fontSize: 22 },
  playScene: { width: '100%', height: 100, borderRadius: 22 },
  scene: { width: '100%', aspectRatio: 1.6, borderRadius: 20 },
  safe: { flex: 1 }, page: { flexGrow: 1, padding: 12, paddingBottom: 30 }, content: { width: '100%', maxWidth: 494, alignSelf: 'center', gap: 16, padding: 12, borderRadius: 28, backgroundColor: theme.background + 'ed' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 }, brand: { flex: 1 }, title: { color: theme.ink, fontWeight: '800', fontSize: 28, marginTop: 6 },
  eyebrow: { fontSize: 10, letterSpacing: 1.6, fontWeight: '700' }, subtitle: { color: theme.ink, fontSize: 23, lineHeight: 32, marginVertical: 4, paddingHorizontal: 8 },
  summary: { padding: 20, gap: 5, borderRadius: 24, backgroundColor: theme.surface }, best: { color: theme.ink, fontSize: 40, fontWeight: '800', fontVariant: ['tabular-nums'] },
  copy: { color: theme.ink, fontSize: 15, lineHeight: 23 }, small: { color: theme.muted, fontSize: 12, lineHeight: 19 },
  button: { borderWidth: 1, borderRadius: 14, minHeight: 48, paddingHorizontal: 15, paddingVertical: 13, justifyContent: 'center', alignItems: 'center' },
  buttonText: { fontSize: 14, fontWeight: '700', textAlign: 'center' }, toolbar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  results: { paddingVertical: 18, gap: 14 }, links: { flexDirection: 'row', gap: 12, justifyContent: 'center', marginTop: 12, flexWrap: 'wrap' },
  notice: { backgroundColor: '#273b50', color: '#f0e4ba', padding: 14, borderRadius: 12, lineHeight: 21 },
  scrim: { flex: 1, backgroundColor: '#000b', padding: 24, alignItems: 'center', justifyContent: 'center' }, dialog: { width: '100%', maxWidth: 430, maxHeight: '90%', borderRadius: 24, borderWidth: 1, borderColor: theme.edge },
  dialogContent: { padding: 24, gap: 18 }, dialogTitle: { fontSize: 26, fontWeight: '800' }, tutorial: { color: theme.ink, fontSize: 17, lineHeight: 27 }, setting: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
});
