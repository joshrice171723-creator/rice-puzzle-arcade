import '@expo/metro-runtime';
import React, { useEffect, useState } from 'react';
import { AppState, StatusBar } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import Arena from './Arena';

const KEY = 'rice-arcade:nightfall-arena:v1';
let writes = Promise.resolve();
async function load() { return AsyncStorage.getItem(KEY); }
async function save(value: string) {
  const next = writes.catch(() => {}).then(() => AsyncStorage.setItem(KEY, value));
  writes = next; await next;
}
export default function App() {
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  useEffect(() => { const listener = AppState.addEventListener('change', state => setForeground(state === 'active')); return () => listener.remove(); }, []);
  return <SafeAreaProvider><StatusBar barStyle="light-content" /><SafeAreaView style={{ flex: 1, backgroundColor: '#101b20' }}>
    <Arena foreground={foreground} load={load} save={save} dom={{ scrollEnabled: false, style: { flex: 1 } }} />
  </SafeAreaView></SafeAreaProvider>;
}
