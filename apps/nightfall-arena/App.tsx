import '@expo/metro-runtime';
import React, { useEffect, useState } from 'react';
import { AppState, StatusBar, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import Arena from './Arena';
import { createTelemetry } from '../../packages/analytics/client';

const KEY = 'rice-arcade:nightfall-arena:v1';
let writes = Promise.resolve();
async function load() { return AsyncStorage.getItem(KEY); }
async function save(value: string) {
  const next = writes.catch(() => {}).then(() => AsyncStorage.setItem(KEY, value));
  writes = next; await next;
}
export default function App() {
  const [telemetry] = useState(() => createTelemetry('nightfall-arena', AsyncStorage, process.env.EXPO_PUBLIC_ANALYTICS_URL || 'https://aimetaclinic.com/games/api/events', process.env.EXPO_PUBLIC_BUILD_PROFILE === 'production' ? 'production' : 'test'));
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  useEffect(() => {
    void telemetry.record('session_start', { platform: Platform.OS, version: '0.1.0' });
    const timer = setInterval(() => { void telemetry.flush(); }, 15000);
    return () => { clearInterval(timer); void telemetry.flush(); };
  }, [telemetry]);
  useEffect(() => { const listener = AppState.addEventListener('change', state => setForeground(state === 'active')); return () => listener.remove(); }, []);
  return <SafeAreaProvider><StatusBar barStyle="light-content" /><SafeAreaView style={{ flex: 1, backgroundColor: '#101b20' }}>
    <Arena foreground={foreground} load={load} save={save} emit={telemetry.record} getTracking={async () => { await telemetry.ready; return telemetry.isEnabled(); }} setTracking={telemetry.setEnabled} dom={{ scrollEnabled: false, style: { flex: 1 } }} />
  </SafeAreaView></SafeAreaProvider>;
}
