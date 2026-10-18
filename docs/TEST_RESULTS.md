# Verified checks — October 17, 2026

Recovery run: `node node_modules/typescript/bin/tsc --noEmit` exited 0. `node node_modules/vitest/vitest.mjs run` reported 6 files passed, 86 tests passed (1.38s).

| Area | Evidence |
| --- | --- |
| Grid Foundry | 22 mechanics tests; browser square placement changed four cells and score 0 to 40 |
| Merge Drift | 16 mechanics tests; browser left move spawned a tile; up merged two 2 tiles and score became 4 |
| Color Cascade | 18 mechanics tests; browser six-symbol group scored 360, gravity/refill updated board, pause froze controls and timer |
| Advertising | 21 mocked-adapter tests; native SDK compilation/rendering and UMP dialogs NOT verified |
| Persistence | 7 schema, daily seed, statistics and serialized write tests |
| Release config | 2 production-ID guard tests |

Grid Android prebuild succeeded after recovery, recreating removed generated files. This is not an APK build. Native installation, gestures on a phone, test-ad labels, privacy dialog behavior, production signing and Play acceptance remain unverified.

Browser previews run the production game engines and React Native Web screens; they do not simulate ad rewards. Core move smoke checks are not complete end-to-end native acceptance.

Disk-full failure recovery: restored truncated Grid screen from retained source, confirmed its nonzero length and TypeScript validity, repaired dependency installation and regenerated native files. Expo cache writes may still warn while C: remains full. Use the headless single-worker preview script to avoid debugger downloads.

## Theme update - October 17, 2026
- Added three palettes per game, friendly home mascots, and rounded/square tile preferences. Existing saves migrate without losing runs or scores.
- TypeScript passed; 87 tests passed, including old-save migration and theme preference persistence.
- Browser: all three home screens and saved boards rendered; Grid theme and tile shape survived reload; light and evening theme picker inspected. No gameplay rules changed.
- App tsconfigs now resolve the hoisted Expo base explicitly, fixing the test transform resolver failure.
- Native Android/theme rendering and live ads remain unverified.


## Fixed artwork update - October 17, 2026
- Removed player theme and tile-style controls. Each game now uses one fixed identity; old appearance preferences are ignored without invalidating existing saves.
- Added original generated workshop/ocean/garden scene backgrounds and transparent wood, sea-glass, and candy sprites. Candy atlas frames exclude neighboring pieces. Decorative images do not intercept input.
- Browser verified all three saved boards with new graphics and settings without appearance choices. Color Cascade inspected at 390px viewport; override reset afterward.
- TypeScript and all 87 tests pass. Android device rendering remains unverified.


## Grid Foundry drag and hover - October 18, 2026
- Added board-sized floating pieces, tray hover lift, legal/blocked cell previews, and safe outside-board cancellation. Tap/keyboard selection remains available; native touch drags lift the piece above the finger.
- Fixed browser page-versus-window coordinate mismatch after scrolling. Preview and drop share the same placement calculation.
- Browser: selected-piece hover; held drag with floating artwork; valid drop to the previewed four cells (+40); occupied-cell rejection and outside-board cancellation preserved score and tray. Verification used the daily run, preserving the normal run.
- Added two placement geometry tests. TypeScript passed. Native Android touch behavior still requires device verification.


## Grid Foundry fitted gameplay - October 18, 2026
- Active play now uses the available viewport, measured board sizing, compact header and a side-by-side landscape layout. Results use a dialog so controls cannot push the board offscreen.
- Background images now explicitly fill their container; their intrinsic 1536x1024 dimensions previously caused document overflow.
- Browser: 390x667 board bottom 540 / tray bottom 643; 320x568 board bottom 441 / tray bottom 544; 844x390 board bottom 366 / tray bottom 339. Document height equaled viewport height and scrollY was zero in each check. Emulation restored afterward.
- Verified placement, +10 score, progress update and three-piece tray refill. Added true best-score/500-point goals, earned milestone messages and a reduced-motion-aware score pulse. No urgency, penalties for leaving, or ad-pressure changes.
- TypeScript and all 90 tests pass. Native device layout and touch remain unverified.


## Journeys, pressure boosts and phone QA — October 18, 2026

- 32 stages: Grid 12 score/line/multi-line goals; Merge 8 tile goals through 2048; Cascade 12 score/group-size/group-count goals. Unlocked stages can be retried; the same level uses a repeatable seed. Progress persists independently of normal/daily games.
- Optional boosts: Grid from 40 occupied cells, Merge with at most three empty cells, Cascade with 15 seconds remaining. One shared boost/continue per run; scores are unchanged by board relief and Cascade adds 20 seconds. No inventory, revenue or consent information enters the engine.
- Full suite: 97 tests across 10 files; TypeScript passes. Tests include threshold boundaries, once-only benefits, goal metric selection, stage unlock deduplication, old-save migration and original mechanics. Test discovery now excludes preserved dependency backups under artifacts.
- Browser wins: Grid stage 1 at 420 points; stage 2 at four lines/820 points. Merge stage 1 reached 16, stage 2 reached 32/132 points. Cascade stage 1 reached 1250; revised stage 2 cleared a group of five and unlocked stage 3.
- Browser failures: Grid stage 3 ended at 730 with no remaining shape fitting; Merge ended at 908 on a full board with no adjacent equal tiles; Cascade timed out and offered free retry. These are actual UI runs, not injected saves.
- Pressure offers: Grid's offer appeared at 41 occupied cells/410 points, Merge at 13 occupied cells, Cascade at 15 seconds. Opening the offer paused controls/time. Cascade remained at 15 seconds while its dialog was open. No-fill messaging did not grant a reward or block play/retry.
- Layout: all three games visually inspected at 320x568, including Grid/Merge with the boost footer visible. At 390x844, document dimensions were exactly 390x844 and scrollY=0 for all three. Lowest controls were Grid 824px, Merge 724px and Cascade 683px. These are browser viewport checks, not native touch acceptance.
- Local screenshots: artifacts/themes/{grid,merge,cascade}-320-final.png, {grid,merge,cascade}-390-final.png, grid-pressure-320.png, merge-pressure-320.png, cascade-boost-unavailable.png.
- Cleared a zero-byte generated Cascade favicon from the active cache by preserving it under artifacts; source artwork was valid. This repaired a leftover disk-full cache error.
- Difficulty tuning is provisional: early-stage playability and real losses were observed, but no human retention, revenue or full 32-stage balance study is claimed.


## No-scroll home and menu verification (October 18)

The shared shell now fills the viewport on home and during play. Hero art has explicit bounds instead of relying on intrinsic image/aspect-ratio sizing. Home actions use a compact row, level selection has three entries per page, and privacy information has four short pages. Dialogs no longer use scrolling containers.

Browser checks at 320x568: Merge and Cascade home buttons end at y=548; Merge gameplay arrows end at y=542; Cascade board ends at y=500. Document height equals viewport height, with zero scrollable overflow containers. Level pagination, settings, tutorial and the longest privacy page were checked with every control inside the viewport. Screenshots: artifacts/themes/{merge,cascade}-{home,play}-no-scroll.png. Temporary device overrides were removed; the normal 912x884 preview also fits.

Final logic validation: 98 tests in 10 files passed; TypeScript passed. Preview startup now prefers IPv4 localhost, matching the desktop browser proxy, and Metro excludes generated native outputs and preserved dependency backups.

Disk cleanup: npm's disposable cache was cleared (about 1.09 GB before cleanup). The requested 100 GB was not recovered. Docker/Ubuntu virtual disks total about 129 GB, but their contents were not established as disposable; no virtual disk was deleted. Automatic approval review blocked deleting an old Android Studio installer. No connected Android device or usable emulator was available, so native test-ad display remains unverified.

Native receipt: Grid APK and AAB completed successfully (651 Gradle tasks, 7m18s); artifacts/android/grid-foundry contains both installers, Gradle log and SHA256SUMS. APK manifest verified package com.joshuarice.gridfoundry, min SDK 24, target SDK 36, arm64-v8a, Google's sample application ID and delayed ad measurement. These artifacts have not been installed or shown a test ad. A subsequent all-app build includes explicit shared-source bundle invalidation and disables shrinking for internal iteration; its outcome is not yet verified (artifacts/all-games-native-final.log).

## Gameplay reliability follow-up — October 18, 2026

- Reproduced and fixed Merge's spawned-4 milestone bug: an early non-merging swipe could leave highestTile=2 with a 4 on the board, causing restoreGame to reject its own save. Milestones now include spawned tiles; otherwise valid older saves recover their highest tile from the board without changing score or RNG.
- Regression failed before the fix (expected 4, received 2). Final validation: 103 tests in 11 files pass; TypeScript passes. Added multi-seed sequences for Grid (20 seeds, up to 100 placements), Merge (30 seeds, up to 200 swipes), and Cascade (20 seeds, 90 timed clears), checking save/reload and engine invariants after moves. These are correctness checks, not a human difficulty or retention study.
- Browser: Grid resumed at 580 and accepted a three-cell placement to reach 610. Merge retained its moved board across reload on the refreshed preview. Cascade cleared six symbols for 360 points, held at 86 seconds while paused, and restored the same board/score/time after home and reload.
- At 320x568 all three inspected gameplay states had document dimensions 320x568 and no buttons outside the viewport (Cascade's pause dialog included). Device overrides were cleared afterward. Screenshot: artifacts/themes/merge-resume-qa.png.
- Native blocker confirmed: artifacts/all-games-native-final.log contains disk-full D8 errors. About 1.9 GB remains free; adb devices is empty. No new native build or actual-device acceptance is claimed.
- Dot's user-supplied handoff reports account-side AdMob records now exist. Ads configuration remains with Dot; this pass changed gameplay reliability and verification only.

## Native adapter and level readiness — October 18, 2026

- 123 tests in 13 files pass; TypeScript passes. Seven new native-adapter contract tests verify all three app keys use sample units during QA, rewarded-specific loaded/earned event mapping, no interstitial reward handler, denied consent preservation after form failure, cleanup, and missing-production-ID rejection. These mock the SDK boundary and do not prove live ad delivery.
- Every level now starts with a short strategy matched to its goal. The goal label can wrap without pushing numeric progress outside the phone width.
- All 12 Cascade seeded levels have a scripted completion path without boosts, choosing the largest available group once per second. The old final target of 15,500 exceeded this baseline's 13,920; it is now 13,000, still above the previous 11,200-point score goal. This is a reachability check, not proof of human enjoyment or universal solvability for arbitrary play.
- Browser play completed Cascade level 3 at 2,450 points / 12 groups with 69 seconds remaining. The next-level action and result dialog fit at 320x568. All three level-three gameplay states had matching document/viewport dimensions at 320x568 and 390x844, with no offscreen buttons at the smaller size. Screenshots: artifacts/themes/{grid,merge}-strategy-phone.png and cascade-level3-phone.png. Temporary viewport overrides were removed.
- The formerly disk-blocked ARM build completed APK and AAB for all three games (artifacts/native-readiness-followup.log). A subsequent dual-ABI build includes the committed strategy/balance changes (e0dcdab). See the final receipt below for its outcome.
- Android Emulator was already installed; the official command-line tools and Google APIs Android 11/API 30 x86_64 image were installed from dl.google.com. Arcade_QA_API30 uses the Pixel 2 profile and WHPX acceleration. The emulator boots successfully. Grid's dual-ABI APK installed and reported a successful cold start; its process logged ReactNativeJS Running main and its activity became foreground. This is startup evidence, not visual or ad acceptance.
- No physical phone is connected, per the owner's decision. The emulator still shares the host network. Actual rewarded-video display, earned/dismissed reward journeys, interstitial display and consent-message behavior remain unverified. Windows Computer Use was attempted through the documented @oai/sky entry point, but node_repl failed before initialization with "failed to write kernel assets: The system cannot find the path specified. (os error 3)". Resetting the kernel and retrying returned the same error. Native interactive acceptance needs that runtime repaired or owner interaction.

### Final emulator artifact receipt

All three dual-ABI APK/AAB builds succeeded from gameplay commit e0dcdab (arm64-v8a and x86_64). All three APKs installed successfully on emulator-5554, Android 11/API 30 x86_64, and `am start -W` reported Status: ok / LaunchState: COLD. Cascade's cold start took 3,796 ms. Build log: artifacts/native-emulator-build.log; each artifacts/android/<app>/ directory contains APK, AAB, Gradle log and SHA256SUMS.

APK SHA-256:
- Grid: fcbb15e29f18c543de433d039c9aa75a2389356d0d56e0c60eb0ded092a367d9
- Merge: 3d0edee385c291f49549558016d47ad34a0118396fb33c86714dc5518c09840b
- Cascade: ec10a2c53f9831e3d0dea7016fd403a2863de3c2507f9491857930f6d43d57ed

These are internal Google test-ad builds. Successful installation and startup do not establish that an ad loaded, displayed, or awarded its benefit. No production serving or mediation acceptance is claimed. Gameplay generation does not receive best score or ad availability, and no near-high-score forced-loss mechanic was added.
