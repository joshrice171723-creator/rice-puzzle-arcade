# Release gates

Use one receipt per app and exact version/commit. Empty boxes mean pending, not failure. Read current `STATUS.md` / `TEST_RESULTS.md` for work completed after this checklist was written.

## Software and artifact gates

- [ ] Three distinct packages, original icons, launch flows, help/settings, local persistence and daily mode verified.
- [ ] Engine tests cover rules, random seed reproducibility, rewards, timeout and no-op/illegal actions.
- [ ] Ad callback tests verify zero unearned benefits, duplicate-reward handling, failure/offline behavior, concurrency and full-screen cooldowns.
- [ ] Final native manifests target Android API 36 or higher, verified from built artifacts.
- [ ] Native SDK/Expo compatibility proved by actual build and install; Expo Go is not sufficient.
- [ ] Signed APK and AAB for each app; record absolute paths, package/version and SHA-256.
- [ ] Native cold start, replay, save/relaunch, pause/background/resume and process interruption smoke tests.
- [ ] Small/large displays, text scaling, symbol contrast, screen reader labels and motion preferences checked.
- [ ] Test ads show official test labeling on configured test devices; zero live-ad testing.
- [ ] Consent refresh, privacy choices, denied/pending state and network failures leave ordinary gameplay usable.
- [ ] All production profiles reject demo/missing publisher IDs when production advertising is intended.

## Publisher and store gates

- [ ] Owner completes Play/AdMob legal, identity, device, fee, tax/payout steps that are actually required.
- [ ] Confirm name/identifier conflicts before permanent app records; confirm support email and targeted audience.
- [ ] Six publisher routes publicly accessible at verified owner-domain; privacy reconciled with final SDK inventory.
- [ ] Exact real app-ads.txt record returns at domain root; AdMob records verification.
- [ ] Separate AdMob app + rewarded/interstitial units for each game; distinct App ID and ad-unit ID mapping.
- [ ] Five real native screenshots, original icon, feature graphic, and three real gameplay clips per app.
- [ ] Listing drafts verified against final build; no unavailable feature or public-release claim.
- [ ] Play ads declaration, content rating, audience, app access, Advertising ID and Data safety forms match actual build.
- [ ] Internal test upload/install, pre-launch report and crash findings reviewed.
- [ ] Closed testing completed where required; genuine feedback, continuous enrollment and per-app eligibility receipts.
- [ ] Owner-authorized production submission, Google review outcome and public listing each recorded separately.
- [ ] Public store linking and AdMob readiness/serving limits verified per app.
- [ ] Real earnings distinguished from estimates and test impressions; no invented revenue.

## Per-app release receipt

| App | Commit/version | APK + hash | AAB + hash | Native device/test | Play state | AdMob state |
| --- | --- | --- | --- | --- | --- | --- |
| Grid Foundry | Pending | Pending | Pending | Not verified here | Not verified | Not verified |
| Merge Drift | Pending | Pending | Pending | Not verified here | Not verified | Not verified |
| Color Cascade | Pending | Pending | Pending | Not verified here | Not verified | Not verified |

Update with actual evidence only. No policy checklist or web screenshot proves an installed native release.

## Current official policy checks

Verified October 17, 2026: [new phone apps/updates target API 36 from August 31, 2026](https://support.google.com/googleplay/android-developer/answer/11926878). [Qualifying new personal accounts require at least 12 opted-in testers for 14 continuous days before production access application](https://support.google.com/googleplay/android-developer/answer/14151465). [SDK data disclosure guidance](https://developers.google.com/admob/android/privacy/play-data-disclosure) must be matched to the resolved SDK. Recheck at submission, since requirements can change.
