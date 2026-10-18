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

