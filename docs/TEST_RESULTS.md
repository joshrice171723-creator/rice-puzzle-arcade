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
