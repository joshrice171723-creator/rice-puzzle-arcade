# Rewarded video validation — October 18, 2026

Result: all three installed Android internal-test apps played an actual Google test rewarded video and applied the expected gameplay benefit once. No source fix was needed.

Environment: Android 11 / API 30 x86_64 emulator, `emulator-5554`, AVD `Arcade_QA_API30`. Games were operated through Android UIAutomator accessibility observations and ADB input/screenshot commands after the Windows computer-use helper failed to initialize. Only normal UI moves and clicks were used: no save injection, reward simulation, SDK callback injection, or ad destination clicks.

## Observed results

| Game | Before watching | After completed video | Verification |
| --- | --- | --- | --- |
| Grid Foundry | 42 occupied cells; optional two-row boost available | 28 occupied cells; rows 1 and 2 cleared; fresh tray | Exact 8×8 board comparison matches clearing only the two busiest rows. Boost offer removed. |
| Merge Drift | 13 occupied cells; optional two-space boost available | 11 occupied cells; two smallest cubes (2 and 2) removed | Exact 16-cell comparison matches removing only those two cubes. Boost offer removed. |
| Color Cascade | Timer expired; game-over dialog; score 0 | Timer restored to 0:20; “20 seconds added.” | Resumed and cleared three symbols for 90 points. After the bonus time expired, results showed score 90 and no second rewarded-continue offer. |

Each ad displayed the Google “Test Ad” label and reached “Reward granted.” The close control was used only after that indication. Games returned paused; Resume continued gameplay. Color Cascade's test creative contained two ads in its rewarded sequence; the game granted one boost for the completed sequence.

The live studio report was checked against a saved pre-test baseline. Each game independently added exactly:

- `ad_shown`: 1
- `boost_request`: 1
- `boost_earned`: 1

The matching engine/service regression suites passed: **91 tests across five files**. These cover duplicate SDK reward callbacks, closing without earning, load/show failures, and once-per-run engine rewards. Cancellation/error scenarios in this pass were automated tests; they were not additional manually interrupted native video sessions.

## Installed APK identities

| App | SHA-256 |
| --- | --- |
| Grid Foundry | `072ce071b973d8eb4d16a84c2206a52c808eeeffa6346d24a2fb1c5794718abc` |
| Merge Drift | `175ccea1661a6fb64e2fbc09ec9844d13f442de519e037e932c20897629d25f4` |
| Color Cascade | `3f45570c84eebc5a3f761847469b64e174ce25d679dedba2141aa4a9e1ac2823` |

## Local evidence

Evidence is retained in the workspace's ignored `artifacts/` folder:

- `grid-video.png`, `grid-video-complete.png`, `grid-reward-applied.png`, `grid-before-reward.json`, `grid-reward-proof.json`
- `merge-video.png`, `merge-video-complete.png`, `merge-reward-applied.png`, `merge-before-reward.json`, `merge-reward-proof.json`
- `cascade-before-reward.png`, `cascade-video.png`, `cascade-video-progress.png`, `cascade-reward-paused.png`, `cascade-reward-applied.png`, `cascade-reward-playable.png`
- `reward-baseline.json`, `reward-live-proof.json`

Scope: actual test-video playback and reward delivery in free-play mode, including an in-round boost in Grid/Merge and an expired-round continue in Cascade. This does not verify paid production inventory, mediation bidding, production revenue, or every journey-level configuration.
