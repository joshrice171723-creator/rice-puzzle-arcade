# AdMob implementation and verification

The three Android apps share `packages/ads/AdsService.ts`, a pure TypeScript controller, and `index.native.ts`, the React Native Google Mobile Ads 17.3.0 adapter. Metro selects `index.web.ts` for web previews. The browser adapter has no advertising SDK, invented ad presentation, or simulated rewards. All ordinary gameplay remains available when no ad loads.

## Configuration

| Build | SDK app ID | Rewarded / interstitial units |
| --- | --- | --- |
| Development / internal QA | Official Google sample application ID from app config | SDK `TestIds.REWARDED` / `TestIds.INTERSTITIAL` |
| Production | Owner's app-specific real application ID from AdMob | `EXPO_PUBLIC_ADMOB_REWARDED_ID` / `EXPO_PUBLIC_ADMOB_INTERSTITIAL_ID` |

Real ad units are selected only when all three conditions hold: a release JavaScript build (`!__DEV__`), `EXPO_PUBLIC_ADS_MODE=production`, and `EXPO_PUBLIC_BUILD_PROFILE=production`. Internal/dev profiles always use official sample units even if real unit environment variables exist. Real app IDs contain `~`; ad-unit IDs contain `/`. These identifiers are public configuration, not passwords. Never commit signing keys, account credentials, payment details, or identity documents.

Production profiles require the app-specific real values. Build validation must reject missing values or Google's demo publisher IDs before publication. The native adapter also refuses malformed/demo production ad units at request time. No real publisher IDs have been supplied or represented as configured.

## Consent and privacy

At each app/service launch, `initializeAfterConsent()` calls UMP `AdsConsent.gatherConsent()`, which refreshes consent information and shows the configured consent form when required. The adapter then reads `getConsentInfo().canRequestAds`. It initializes Mobile Ads and preloads inventory only when UMP permits requests. A network failure may use UMP's existing authorized consent, but unknown/unauthorized consent prevents all ad requests. Consent results are never persisted separately by the app.

The native Expo plugin delays app measurement until SDK initialization. AdMob Privacy & messaging still requires owner-side GDPR and applicable US-state message configuration and review. UMP's `canRequestAds` is the request permission supplied by Google; it is not a promise that a person consented to every processing purpose or personalized advertising.

Settings calls `showPrivacyOptions()`. The service removes cached inventory before presenting a required UMP privacy form, refreshes permission afterward, and blocks requests when permission is no longer available. A consent/privacy dialog sets the service's observable `busy` state so the game shell can pause foreground timers. No independent analytics SDK or remote analytics endpoint is added by this package.

## Placement and lifecycle

`createAdsService(appKey)` exposes `initializeAfterConsent()`, `preload()`, `isReady(format)`, `showRewardedIfReady(onRewardEarned)`, `showInterstitialAtNaturalBreak({atResults})`, `roundCompleted()`, `showPrivacyOptions()`, `getState()`, `subscribe(listener)`, and `dispose()`.

- Rewarded ads require a deliberate game-specific offer, at a failed result or a pressure point during play: Grid has at least 40 occupied cells; Merge has at most three empty spaces; Cascade has at most 15 seconds left. Opening the offer pauses play and explains the exact benefit. The game's callback applies its one-time revive/rescue/+20 seconds only upon the native `EARNED_REWARD` callback. Duplicate earned callbacks are ignored; dismissal, no-fill, offline, failure, and timeout grant no unearned reward. The game engine separately enforces one shared boost/continue benefit per run. A won journey level never offers a continue. Cascade adds 20 seconds to the remaining time; it does not replace it.
- Interstitials require `atResults: true`, a session strictly longer than 120 seconds, at least three completed full rounds, and at least 180 seconds since dismissal of any previous full-screen ad, including rewarded. At most one interstitial is attempted for a given completed-round transition. The shell must call `roundCompleted()` once per run and invoke the results transition only while that results screen remains current.
- SDK presentation is forbidden while the app is backgrounded. A shared busy lock prevents double taps, parallel formats, and privacy presentation during a video. Preloading coalesces existing loads and replaces inventory after 55 minutes as a conservative reload policy.
- Consent collection times out at 30 seconds, initialization and loading at 15 seconds, and full-screen presentation at 180 seconds. All registered ad listeners and load/show timers are removed on completion/disposal. A missing native dismissal disables further ads for that session because the actual full-screen state is unknown; the game can continue after the timeout without another ad being opened.
- Results include a typed `code` and `earned` flag: `ready`, `shown`, `rewarded`, `closed`, `not_ready`, `consent_required`, `busy`, `frequency_cap`, `invalid_transition`, `failed`, `timeout`, `disposed`, or `unsupported`. Only the earned callback changes a game reward.

No gameplay engine receives consent choices, inventory, bid values, revenue, ad history, or predicted user value. There are no banners, app-open ads, mediation, forced reward videos, paid coins, or ad-triggered difficulty changes.

## Evidence and remaining acceptance

`pnpm exec vitest run packages/ads/AdsService.test.ts`: **21 tests passed** on October 17, 2026. Coverage includes consent denied/pending/failure/timeout, initialization failure, load failure/no-fill/timeout, explicit retry, privacy revocation, stale inventory, zero-ad browser behavior, exact-once reward callback, dismissal without reward, show rejection, background guard, overlapping requests, disposal, missing close callback quarantine, minimum duration/rounds, rewarded cooldown, and transition deduplication.

October 18: the full suite includes four boost tests covering thresholds, unchanged scores, additive time, and one benefit shared by boost and continue. Browser verification covered the pressure offer, paused timer, unavailable inventory, declining the offer, and free retry after failure. Web previews intentionally have no SDK and cannot prove ad rendering.

The adapter compiles against the installed SDK type declarations. These tests use a mocked native adapter and prove controller behavior; **native SDK ad rendering, the TEST AD label, actual UMP dialogs on a device, offline device behavior, SDK revenue callbacks, real ad requests, paid impressions, and revenue have not yet been device verified**. Verify those separately in a native development/internal APK, with UMP debug geography restricted to registered test devices and with developer devices excluded from live traffic. Google's [sample app and ad unit IDs](https://codelabs.developers.google.com/codelabs/admob-inline-ads-in-flutter) support integration testing without creating monetized app records. Publisher setup and actual UMP configuration remain separate gates.

No AdMob account approval, individual app readiness approval, store linking, publisher verification, payment eligibility, or live monetization is claimed by this code. Owner-created AdMob app records, real app/ad-unit IDs, UMP message configuration, verified root `app-ads.txt`, supported-store links, and account/app reviews remain external gates.

## Official references checked

- [Invertase UMP consent integration](https://docs.page/invertase/react-native-google-mobile-ads/european-user-consent)
- [Rewarded SDK events and callbacks](https://docs.page/invertase/react-native-google-mobile-ads/ad-formats/rewarded)
- [Interstitial presentation and native lifecycle](https://docs.page/invertase/react-native-google-mobile-ads/ad-formats/interstitial)
- [Consent and format loading guidance](https://docs.page/invertase/react-native-google-mobile-ads/ad-formats)

The SDK integration was checked against these official package documents and installed 17.3.0 declarations. Native acceptance must use the exact built APK/AAB and account configuration intended for release.

Ad initialization now retries on foreground/resume and when starting a run; the optional-boost dialog also offers a retry after a native load failure. Browser previews explicitly explain that video rewards require the Android app. A regression test covers recovery after a temporary consent-network failure (22 AdsService tests; 98 total). Consent failure still blocks requests; retries do not grant rewards or permission. Google's demo units are used for internal builds: https://developers.google.com/admob/android/test-ads . UMP/sample-app configuration and actual SDK display still need an Android device check.
