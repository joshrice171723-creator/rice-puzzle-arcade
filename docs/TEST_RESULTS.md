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
