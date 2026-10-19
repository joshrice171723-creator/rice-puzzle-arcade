# Nightfall engine proof verification

October 18, 2026. Joshua authorized implementation of the delivery plan with “ok start.” Android installation, native rendering, touch controls, background pause, and genuine Google sample-video earned callbacks now have emulator evidence. M0 remains provisional pending the remaining cancellation, sustained-performance, and physical-phone checks described below. Production ads and inventory rewards are not enabled by this diagnostic.

The evidence and hashes below describe the earlier M0 rendering/ad build. Subsequent M1 feature exports replace the local artifact filenames; their current hashes and acceptance are recorded in [combat slice verification](COMBAT_SLICE_QA.md). Existing bugs are now deferred at Joshua's request in the [bug log](KNOWN_ISSUES.md).

## Delivered

`apps/nightfall-godot/` contains an isolated Godot 4.7.2 Compatibility-renderer project. It has original Beaconbound prototype actor/floor artwork, movement, dodge, automatic projectiles, a pulse ability, experience pickups, three upgrade choices, escalating spawning, a four-minute wave timer followed by a mandatory boss, pause/background handling, and result/restart screens.

The boss is a functional test encounter using enlarged imp artwork, not the finished Breaker. No persistent progression, equipment, shrines, Haven construction, production ads, purchases, or telemetry integration is claimed. The old Expo prototype and the three puzzle games were not modified.

The Android Kotlin bridge compiles against Google Mobile Ads 25.5.0 and UMP 4.0.0, using only Google's sample app/ad identifiers. It gates initialization on consent eligibility and exposes a diagnostic earned-callback counter. No callback is simulated on desktop. It is not a production mediation integration.

## Verification results

| Check | Result | Scope |
|---|---|---|
| Gameplay rules | 17 checks passed | Pause; boss arrival at enemy cap; no boss deadline; victory/death precedence; dodge protection; contact damage interval; one-time upgrade; seeded reproducibility; bounded entities and movement |
| Layout geometry | 15 checks passed | Largest diagnostic menu, upgrade modal, and main controls at 320×568, 390×844, and 430×760 windows; logical canvas letterboxes |
| Rendering regression | Passed, 21 draw calls | Graphics-window check with 120 enemies plus 40 pickups; ceiling 60; rejects headless execution |
| Desktop visual inspection | Passed for prototype framing | Corrected unequal sprite-sheet row cropping, camera edge exposure, and modal overflow; final screenshot saved |
| Windows export | Passed | Standalone internal debug executable created |
| Android export | Passed | Signed internal debug APK, arm64 and x86_64, includes compiled native test-ad plugin |
| Android install and launch | Passed on both ad-enabled builds | Exact APKs installed; GLES 3 Compatibility rendering reached the actual game; latest hashes and captures below |
| Touch and lifecycle | Passed on emulator | Movement, dodge/pulse cooldowns, XP collection, level-up menu, and background return to explicit pause observed |
| Real test video and reward callback | Passed on both builds | Four completed placements on the first build; one additional placement on the optimized build; exactly one earned callback each; game remained paused |
| Network failure and recovery | Passed on emulator | Emulator-only Wi-Fi/data disable produced consent-request failure with unchanged counter; restoring network allowed a new video and callback |
| Early dismissal without reward | Still open | Back attempts during sample playback were ignored by the SDK creative; later completion is not cancellation evidence |
| Physical-phone performance / thermal / 15-minute soak | Not run | No physical-phone or sustained native acceptance claim |

Commands: `./scripts/nightfall-godot.ps1 -Action Test`, `-Action Windows`, and `-Action Android`. Source and asset provenance: [project README](../../apps/nightfall-godot/README.md), [asset prompts](../../apps/nightfall-godot/ASSET_SOURCES.md).

## Final desktop render samples

Windows, Intel Iris Xe, OpenGL Compatibility renderer, automated movement, real prototype textures. First three seconds excluded from frame samples. Firing was active; the instantaneous final shot count happened to be zero. These are crowd-load samples, not a maximum-projectile stress scenario or player-balance study.

| Crowd | Sample duration | Measured frames | Mean FPS | p95 frame time |
|---|---:|---:|---:|---:|
| 30 enemies | 20 seconds | 1689 | 99.30 | 10.0 ms |
| 60 enemies | 20 seconds | 1700 | 99.93 | 10.0 ms |
| 120 enemies | 30 seconds | 2685 | 99.43 | 10.0 ms |

Godot static memory was approximately 32.2–32.4 MB; this excludes total process/GPU memory. The initial 98.2 FPS result is superseded by the final samples above. Do not compare these desktop numbers directly with the older Expo emulator's 7–11 FPS.

Local evidence lives in the Git-ignored `artifacts/nightfall-godot/` directory: `desktop-final-30.json`, `desktop-final-60.json`, `desktop-final-120.json`, matching PNG captures, `android-verified.log`, `windows-final.log`, and emulator logs. The summary in this document is retained in Git; those local evidence files are not available merely by cloning the repository.

## Exact local build artifacts

| Artifact | SHA256 |
|---|---|
| `artifacts/nightfall-godot/nightfall-proof.apk` | `38C0884CE6D251975D8D492539B5BFFCF7B3A03CA899A1B70B353FFFF6A9C59A` |
| `artifacts/nightfall-godot/NightfallProof.exe` | `4BA51790095C75D7E5EEE1B8E8F46A0AF3DFEBAA447378DEA56D65059DEB3A78` |

Both are internal proof builds, not store releases. The Android package is `com.joshuarice.nightfallproof` and does not replace the existing Nightfall application.

## Environment repairs and historical blockers

- Installed portable Godot 4.7.2 and selected export templates from the official release, with SHA512 checks against its checksum manifest.
- Reused Android Studio's JBR, installed SDK platform 36 via the existing licensed Gradle workflow, and reused NDK 27.1.12297006 for packaging prebuilt Godot libraries.
- Updated the generated template's Kotlin compiler to 2.3.20 to read Ads 25.5.0 metadata. No metadata checks were disabled.
- Added `android/.gdignore` before template scanning. Removed 17 accidentally generated `.import` sidecars from Android resources after an initial resource merge failure.
- Limited Gradle to a 1536 MB heap, two workers, in-process Kotlin compilation, and stopped its daemon after export.
- The emulator's `-feature GLESDynamicVersion` flag changed reported `qemu.opengles.version` from 131072 to 196608. This fixes the advertised GLES level; successful game launch still needs validation.
- The final emulator startup refused to proceed with approximately 0.45 GB free on C:. Docker shutdown improved memory but did not solve storage exhaustion.
- Automatic approval review rejected removal of `apps/nightfall-godot/android/build/build` as “blocked by policy.” That generated folder remains. The redundant downloaded engine ZIP was removed separately after checksum verification and extraction. No user files were deleted.

## Initial resume order (historical; current results below)

1. Obtain at least 3 GB working disk headroom without deleting project source or the final artifacts.
2. Start the existing QA emulator with `-gpu host -feature GLESDynamicVersion`, no snapshots, and wait for boot completion. Keep compilation and emulator work sequential.
3. Install the exact final APK and launch its exported `com.godot.game.GodotAppLauncher` activity.
4. Validate actual touch movement, release over buttons, dodge, pulse, pause/background, and every native menu at the emulator viewport.
5. Open the sample-ad diagnostic. Observe a real video and exactly one earned callback; separately test early close and load failure. Record actual errors instead of claiming a reward from dismissal.
6. Run sustained native crowd scenarios, then physical-phone acceptance when available. Keep engine adoption provisional until the native evidence is credible.

No changes to router settings, publisher accounts, production ad IDs, or the hosted studio were made in this implementation pass.

## Android retry and rendering repair — October 18

The user freed disk space, leaving approximately 3.5 GiB at retry. The existing `Arcade_QA_API30` emulator booted with `-gpu host -feature GLESDynamicVersion`. The original ad-enabled APK (SHA256 `FC2C974BA048FC8899AA09B39728E79AFF81A4F4D502C39D6281C73593956B57`) installed successfully and rendered the complete 1080×1920 game menu. The emulator was subsequently opened as a visible window at the user's request.

Sample-ad evidence: `android-ad-show.png`, `android-ad-complete.png`, `android-reward-verified.png`, `android-offline.png`, `android-ad-repeat.log`, and `android-ad-recovery.log`. The first earned callback was at 18:25:54 in emulator log time, and dismissal at 18:26:35 reported `Closed • reward verified`. The offline request kept the count at 2; recovery took approximately 37 seconds to show its video and then earned callback 3. A fourth placement completed afterward. Only Google sample IDs were used. No inventory benefit, production mediation fill, or revenue is implied.

Gameplay evidence: `android-touch-abilities.png` shows both cooldowns after touch actions; `android-background-paused.png` and `android-paused-stable.png` show the timer held at 03:41; `android-upgrade-check.png` shows the level-2 choice menu after collecting XP. No AndroidRuntime exception or Godot script error appeared in the filtered log during these checks.

The first crowd pass exposed a rendering problem: the HUD snapshot showed 13 FPS / 113.5 ms p95 at 120 enemies, versus 38 FPS / 30.5 ms at 30 enemies. These are rolling HUD snapshots, not whole-run averages. Physics peak was only 1.10 ms in the 120-enemy capture. A desktop rendering probe measured 265 draw calls for 120 actors. Grouping actors and shadows reduced that to 145; replacing individual shadow polygons with a shared texture reduced it to 25 in the same probe. Experience pickups used the same per-object polygon pattern and were converted to a shared texture as well. The deterministic graphics regression with 120 actors and 40 pickups now measures 21 calls. Actors remain depth-sorted; shadows are below the actor layer, and health bars are above it.

The frame-history array is now populated only for explicitly timed benchmarks, avoiding unbounded growth during normal play. Gameplay rules were unchanged. All 17 rule and 15 layout checks were rerun successfully, and both export artifacts were regenerated; hashes above identify the new rendering build. The Android export completed, but its console wrapper held an inherited Gradle pipe until a separate `gradlew --stop` call released it. This build-tool process-lifetime issue is distinct from gameplay and remains a helper-workflow limitation.

### Optimized-build acceptance

The APK identified above was installed over the first proof and launched in the visible emulator. `android-crowd120-after20.png`, `android-crowd120-moving.png`, and `android-crowd120-label-check.png` each show 60 FPS / 16.7 ms rolling p95 with 120 enemies. The moving capture includes touch movement, dodge, pulse, and a drag released over the dodge button; the stick returned to neutral. These are short sampled checks across a few minutes, not a 15-minute soak or a whole-run statistical benchmark. Crowd mode is explicitly invulnerable and does not prove mission balance.

The final APK requested a test video at 18:42:19, showed it at 18:42:29, and received one earned callback at 18:42:38 (emulator log time). `android-final-ad.png` shows the SDK's Test Ad / Reward granted state; `android-final-reward.png` shows the paused game with one earned callback. The full filtered trace is `android-final-ad.log`. A new survival run then responded to touch movement and both abilities; `android-final-survival.png` shows 59 FPS / 16.7 ms p95. `nightfall-android-gameplay.mp4` is a 25-second recording from the visible emulator, not a rendered concept video.

An intermittent display defect remains: some crowd screenshots omit static button lettering, especially the pause bars, while the button shapes and hit targets remain functional. A later capture restores Pulse/Dodge text but still omits the pause glyph. Normal-survival and menu captures display the labels. Root cause has not been isolated; do not mark complete visual acceptance from the frame-rate improvement alone. The updated build also logged one cached-shader recompile warning at startup, then rendered successfully; this is not established as the cause.

Remaining acceptance: investigate that control-label artifact, verify an actual early dismissal without an earned callback using a cancellable test creative, complete sustained native and physical-phone performance checks, and test a full boss win/loss journey. Inventory rewards, production IDs/mediation, and purchases remain later milestones. No network/router configuration was changed; emulator Wi-Fi/data were restored after the offline test.
