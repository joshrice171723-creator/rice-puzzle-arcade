import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import type { AdsAdapter } from './AdsService';

const sdk = vi.hoisted(() => ({
  adapter: null as AdsAdapter | null,
  consent: vi.fn(), gather: vi.fn(), privacy: vi.fn(), initialize: vi.fn(),
  requests: [] as string[], events: [] as string[], remove: vi.fn(), destroy: vi.fn(),
}));
vi.mock('react-native', () => ({ AppState: { currentState: 'active' } }));
vi.mock('./AdsService', () => ({ AdsService: class { constructor(adapter: AdsAdapter) { sdk.adapter = adapter; } } }));
vi.mock('react-native-google-mobile-ads', () => {
  class InterstitialAd {
    static createForAdRequest(id: string) { sdk.requests.push(id); return new this(); }
    addAdEventListener(event: string) { sdk.events.push(event); return sdk.remove; }
    load() {}
    async show() {}
    destroy() { sdk.destroy(); }
  }
  class RewardedAd extends InterstitialAd {}
  return {
    default: () => ({ initialize: sdk.initialize }), InterstitialAd, RewardedAd,
    AdsConsent: { getConsentInfo: sdk.consent, gatherConsent: sdk.gather, showPrivacyOptionsForm: sdk.privacy },
    AdsConsentPrivacyOptionsRequirementStatus: { REQUIRED: 'required' },
    AdEventType: { LOADED: 'loaded', OPENED: 'opened', CLOSED: 'closed', ERROR: 'error' },
    RewardedAdEventType: { LOADED: 'rewarded_loaded', EARNED_REWARD: 'earned_reward' },
    TestIds: { REWARDED: 'test-rewarded', INTERSTITIAL: 'test-interstitial' },
  };
});
import { createAdsService } from './index.native';

beforeEach(() => {
  vi.clearAllMocks(); sdk.requests.length = 0; sdk.events.length = 0;
  vi.stubGlobal('__DEV__', false);
  vi.stubEnv('EXPO_PUBLIC_ADS_MODE', 'test');
  vi.stubEnv('EXPO_PUBLIC_BUILD_PROFILE', 'internal');
  sdk.consent.mockResolvedValue({ canRequestAds: false, privacyOptionsRequirementStatus: 'required' });
  sdk.gather.mockResolvedValue(undefined);
});
afterEach(() => { vi.unstubAllEnvs(); vi.unstubAllGlobals(); });

it.each(['grid-foundry', 'merge-drift', 'color-cascade'])('%s requests sample units during QA despite real IDs in the environment', slug => {
  vi.stubEnv('EXPO_PUBLIC_ADMOB_REWARDED_ID', 'ca-app-pub-8089701632338419/6032869882');
  createAdsService(slug);
  sdk.adapter!.create('rewarded'); sdk.adapter!.create('interstitial');
  expect(sdk.requests).toEqual(['test-rewarded', 'test-interstitial']);
});

it('keeps debug builds on test units even with production flags', () => {
  vi.stubGlobal('__DEV__', true);
  vi.stubEnv('EXPO_PUBLIC_ADS_MODE', 'production');
  vi.stubEnv('EXPO_PUBLIC_BUILD_PROFILE', 'production');
  createAdsService('grid-foundry');
  sdk.adapter!.create('rewarded'); sdk.adapter!.create('interstitial');
  expect(sdk.requests).toEqual(['test-rewarded', 'test-interstitial']);
});

it('maps reward loading and earning to the SDK-specific events, never dismissal', () => {
  createAdsService('grid-foundry');
  const ad = sdk.adapter!.create('rewarded');
  for (const event of ['loaded', 'earned', 'closed'] as const) ad.on(event, () => {});
  expect(sdk.events).toEqual(['rewarded_loaded', 'earned_reward', 'closed']);
  ad.destroy(); expect(sdk.remove).toHaveBeenCalled(); expect(sdk.destroy).toHaveBeenCalledOnce();
});

it('does not register an earned-reward callback for interstitials', () => {
  createAdsService('merge-drift');
  const ad = sdk.adapter!.create('interstitial');
  ad.on('earned', () => {}); ad.on('loaded', () => {});
  expect(sdk.events).toEqual(['loaded']);
});

it('preserves denied consent when the consent form request fails', async () => {
  sdk.gather.mockRejectedValue(new Error('offline'));
  createAdsService('color-cascade');
  expect(await sdk.adapter!.gatherConsent()).toEqual({ canRequestAds: false, privacyOptionsRequired: true });
  expect(sdk.initialize).not.toHaveBeenCalled();
});

it('refuses unknown production games', () => {
  vi.stubEnv('EXPO_PUBLIC_ADS_MODE', 'production');
  vi.stubEnv('EXPO_PUBLIC_BUILD_PROFILE', 'production');
  createAdsService('unknown');
  expect(() => sdk.adapter!.create('rewarded')).toThrow('Production ad-unit configuration');
  expect(sdk.requests).toEqual([]);
});

it.each([
  ['grid-foundry', '6032869882', '8613047170'],
  ['merge-drift', '1964887506', '7762999931'],
  ['color-cascade', '6449918267', '3549431914'],
])('%s uses its own production units', (slug, rewarded, interstitial) => {
  vi.stubEnv('EXPO_PUBLIC_ADS_MODE', 'production');
  vi.stubEnv('EXPO_PUBLIC_BUILD_PROFILE', 'production');
  createAdsService(slug);
  sdk.adapter!.create('rewarded'); sdk.adapter!.create('interstitial');
  expect(sdk.requests).toEqual([rewarded, interstitial].map(id => 'ca-app-pub-8089701632338419/' + id));
});
