import { AdsService, type AdsAdapter } from './AdsService';
export * from './AdsService';

const adapter: AdsAdapter = {
  supported: false,
  gatherConsent: async () => ({ canRequestAds: false, privacyOptionsRequired: false }),
  privacyOptions: async () => ({ canRequestAds: false, privacyOptionsRequired: false }),
  initialize: async () => undefined,
  create: () => { throw new Error('Native ads are unavailable in a browser.'); },
  isForeground: () => true,
};

/** Browser previews provide full gameplay with no simulated ads or simulated rewards. */
export function createAdsService(_appKey: string): AdsService { return new AdsService(adapter); }
