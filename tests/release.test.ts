import { describe, it, expect } from 'vitest';
import { createRequire } from 'node:module';
const { validateAds } = createRequire(import.meta.url)('../scripts/app-config.cjs');
describe('release guard', () => {
  it('forces test application in internal builds', () => expect(validateAds({ ADMOB_ANDROID_APP_ID:'live' })).toContain('3940256099942544'));
  it('blocks production without owner IDs', () => {
    expect(() => validateAds({ EAS_BUILD_PROFILE:'production' })).toThrow();
    expect(() => validateAds({ EAS_BUILD_PROFILE:'production', EXPO_PUBLIC_ADS_MODE:'production', ADMOB_ANDROID_APP_ID:'ca-app-pub-3940256099942544~3347511713' })).toThrow();
  });
});
