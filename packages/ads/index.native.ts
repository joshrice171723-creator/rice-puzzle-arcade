import { AppState } from 'react-native';
import mobileAds, {
  AdsConsent,
  AdsConsentPrivacyOptionsRequirementStatus,
  AdEventType,
  InterstitialAd,
  RewardedAd,
  RewardedAdEventType,
  TestIds,
} from 'react-native-google-mobile-ads';
import { AdsService, type AdHandle, type AdsAdapter, type AdEvent, type ConsentInfo } from './AdsService';
export * from './AdsService';

async function consentInfo(): Promise<ConsentInfo> {
  const info = await AdsConsent.getConsentInfo();
  return {
    canRequestAds: info.canRequestAds,
    privacyOptionsRequired: info.privacyOptionsRequirementStatus === AdsConsentPrivacyOptionsRequirementStatus.REQUIRED,
  };
}

export function createAdsService(_appKey: string): AdsService {
  const live = !__DEV__ && process.env.EXPO_PUBLIC_ADS_MODE === 'production' &&
    process.env.EXPO_PUBLIC_BUILD_PROFILE === 'production';
  const ids = {
    rewarded: live ? process.env.EXPO_PUBLIC_ADMOB_REWARDED_ID : TestIds.REWARDED,
    interstitial: live ? process.env.EXPO_PUBLIC_ADMOB_INTERSTITIAL_ID : TestIds.INTERSTITIAL,
  };
  const adapter: AdsAdapter = {
    supported: true,
    async gatherConsent() {
      try { await AdsConsent.gatherConsent(); } catch {
        // UMP may authorize cached consent offline; an unknown/unauthorized state still blocks requests.
      }
      return consentInfo();
    },
    async privacyOptions() {
      const info = await consentInfo();
      if (info.privacyOptionsRequired) await AdsConsent.showPrivacyOptionsForm();
      else await AdsConsent.gatherConsent();
      return consentInfo();
    },
    initialize: () => mobileAds().initialize(),
    isForeground: () => AppState.currentState === 'active',
    create(format): AdHandle {
      const id = ids[format];
      if (!id || (live && (!/^ca-app-pub-\d{16}\/\d{10}$/.test(id) || id.includes('3940256099942544')))) {
        throw new Error('Production ad-unit configuration is missing or uses a demonstration ID.');
      }
      const rewarded = format === 'rewarded';
      const ad = rewarded ? RewardedAd.createForAdRequest(id) : InterstitialAd.createForAdRequest(id);
      const eventNames = {
        loaded: AdEventType.LOADED,
        opened: AdEventType.OPENED,
        closed: AdEventType.CLOSED,
        earned: AdEventType.CLOSED,
        error: AdEventType.ERROR,
      };
      const unsubscribers = new Set<() => void>();
      return {
        on(event: AdEvent, callback) {
          if (event === 'earned' && !rewarded) return () => undefined;
          const unsubscribe = ad instanceof RewardedAd
            ? ad.addAdEventListener(event === 'loaded' ? RewardedAdEventType.LOADED : event === 'earned' ? RewardedAdEventType.EARNED_REWARD : eventNames[event], callback)
            : ad.addAdEventListener(eventNames[event], callback);
          unsubscribers.add(unsubscribe);
          return () => { unsubscribe(); unsubscribers.delete(unsubscribe); };
        },
        load: () => ad.load(),
        show: () => ad.show(),
        destroy() {
          for (const unsubscribe of unsubscribers) unsubscribe();
          unsubscribers.clear();
          // v17 adds explicit destruction; removing listeners is the v16 cleanup contract.
          if ('destroy' in ad && typeof ad.destroy === 'function') ad.destroy();
        },
      };
    },
  };
  return new AdsService(adapter);
}
