import React from 'react';
import { Text, View } from 'react-native';
import { useGameTheme } from './themes';

export function GoalMeter({ label, value, target }: { label: string; value: number; target: number }) {
  const { theme } = useGameTheme();
  return <View accessibilityRole="progressbar" accessibilityLabel={label} accessibilityValue={{ min: 0, max: target, now: Math.min(value, target) }} style={{ width: '100%', gap: 4 }}>
    <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 8 }}>
      <Text style={{ color: theme.muted, fontSize: 11 }}>{label}</Text>
      <Text style={{ color: theme.ink, fontSize: 11, fontWeight: '700' }}>{value.toLocaleString()} / {target.toLocaleString()}</Text>
    </View>
    <View style={{ height: 6, borderRadius: 3, backgroundColor: theme.empty, overflow: 'hidden' }}><View style={{ width: `${Math.min(100, value / target * 100)}%`, height: '100%', borderRadius: 3, backgroundColor: theme.accent }} /></View>
  </View>;
}
