import { describe, it, expect } from 'vitest';
import { createRequire } from 'node:module';
const { validateAds } = createRequire(import.meta.url)('../scripts/app-config.cjs');
describe('release guard', () => {
  const production = { EAS_BUILD_PROFILE: 'production', EXPO_PUBLIC_ADS_MODE: 'production', PUBLISHER_RELEASE_APPROVED: 'true' };
  const publishers = createRequire(import.meta.url)('../packages/ads/publisher.json');
  it('maps each game to its own real app and ad units', () => {
    const units = new Set<string>();
    for (const [slug, ids] of Object.entries(publishers) as [string, { appId: string; rewarded: string; interstitial: string }][]) {
      expect(validateAds(production, slug)).toBe(ids.appId);
      expect(validateAds({}, slug)).toContain('3940256099942544');
      for (const id of [ids.rewarded, ids.interstitial]) { expect(id).toMatch(/^ca-app-pub-8089701632338419\/\d{10}$/); expect(units.has(id)).toBe(false); units.add(id); }
      expect(() => validateAds({ ...production, PUBLISHER_RELEASE_APPROVED: 'false' }, slug)).toThrow('Owner');
      expect(() => validateAds({ ...production, EXPO_PUBLIC_ADMOB_REWARDED_ID: 'wrong-game' }, slug)).toThrow('Mismatched');
    }
    expect(units.size).toBe(6);
    expect(() => validateAds(production, 'unknown')).toThrow('Unknown');
  });
  it('forces test application in internal builds', () => expect(validateAds({ ADMOB_ANDROID_APP_ID:'live' })).toContain('3940256099942544'));
  it('blocks production without owner IDs', () => {
    expect(() => validateAds({ EAS_BUILD_PROFILE:'production' })).toThrow();
    expect(() => validateAds({ EAS_BUILD_PROFILE:'production', EXPO_PUBLIC_ADS_MODE:'production', ADMOB_ANDROID_APP_ID:'ca-app-pub-3940256099942544~3347511713' })).toThrow();
  });
});
