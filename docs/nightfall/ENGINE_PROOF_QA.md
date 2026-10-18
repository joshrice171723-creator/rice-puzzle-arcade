# Nightfall engine proof verification

October 18, 2026. Joshua authorized implementation of the delivery plan with “ok start.” M0 is **partially verified**, not complete: desktop rendering, game rules, phone-layout geometry, Windows export, and native Android compilation pass; Android runtime, touch, actual rewarded video, and device performance are still open.

## Delivered

`apps/nightfall-godot/` contains an isolated Godot 4.7.2 Compatibility-renderer project. It has original Beaconbound prototype actor/floor artwork, movement, dodge, automatic projectiles, a pulse ability, experience pickups, three upgrade choices, escalating spawning, a four-minute wave timer followed by a mandatory boss, pause/background handling, and result/restart screens.

The boss is a functional test encounter using enlarged imp artwork, not the finished Breaker. No persistent progression, equipment, shrines, Haven construction, production ads, purchases, or telemetry integration is claimed. The old Expo prototype and the three puzzle games were not modified.

The Android Kotlin bridge compiles against Google Mobile Ads 25.5.0 and UMP 4.0.0, using only Google's sample app/ad identifiers. It gates initialization on consent eligibility and exposes a diagnostic earned-callback counter. No callback is simulated on desktop. It is not a production mediation integration.

## Verification results

| Check | Result | Scope |
|---|---|---|
| Gameplay rules | 17 checks passed | Pause; boss arrival at enemy cap; no boss deadline; victory/death precedence; dodge protection; contact damage interval; one-time upgrade; seeded reproducibility; bounded entities and movement |
| Layout geometry | 15 checks passed | Largest diagnostic menu, upgrade modal, and main controls at 320×568, 390×844, and 430×760 windows; logical canvas letterboxes |
| Desktop visual inspection | Passed for prototype framing | Corrected unequal sprite-sheet row cropping, camera edge exposure, and modal overflow; final screenshot saved |
| Windows export | Passed | Standalone internal debug executable created |
| Android export | Passed | Signed internal debug APK, arm64 and x86_64, includes compiled native test-ad plugin |
| Android install | Earlier basic APK installed | This predates the final ad-enabled APK; do not treat it as final-build installation proof |
| Android launch | Not accepted | Earlier emulator advertised only GLES 2 and crashed before gameplay; corrected launch flags advertise GLES 3, but final launch is blocked by host disk space |
| Real test video and reward callback | Not verified | Native compilation is evidence of integration buildability, not ad delivery |
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
| `artifacts/nightfall-godot/nightfall-proof.apk` | `FC2C974BA048FC8899AA09B39728E79AFF81A4F4D502C39D6281C73593956B57` |
| `artifacts/nightfall-godot/NightfallProof.exe` | `B9882B79D16F096153F48C69A5C608118FF204F5AF8F9D83907C8DD434033280` |

Both are internal proof builds, not store releases. The Android package is `com.joshuarice.nightfallproof` and does not replace the existing Nightfall application.

## Environment repairs and remaining blocker

- Installed portable Godot 4.7.2 and selected export templates from the official release, with SHA512 checks against its checksum manifest.
- Reused Android Studio's JBR, installed SDK platform 36 via the existing licensed Gradle workflow, and reused NDK 27.1.12297006 for packaging prebuilt Godot libraries.
- Updated the generated template's Kotlin compiler to 2.3.20 to read Ads 25.5.0 metadata. No metadata checks were disabled.
- Added `android/.gdignore` before template scanning. Removed 17 accidentally generated `.import` sidecars from Android resources after an initial resource merge failure.
- Limited Gradle to a 1536 MB heap, two workers, in-process Kotlin compilation, and stopped its daemon after export.
- The emulator's `-feature GLESDynamicVersion` flag changed reported `qemu.opengles.version` from 131072 to 196608. This fixes the advertised GLES level; successful game launch still needs validation.
- The final emulator startup refused to proceed with approximately 0.45 GB free on C:. Docker shutdown improved memory but did not solve storage exhaustion.
- Automatic approval review rejected removal of `apps/nightfall-godot/android/build/build` as “blocked by policy.” That generated folder remains. The redundant downloaded engine ZIP was removed separately after checksum verification and extraction. No user files were deleted.

## Resume order

1. Obtain at least 3 GB working disk headroom without deleting project source or the final artifacts.
2. Start the existing QA emulator with `-gpu host -feature GLESDynamicVersion`, no snapshots, and wait for boot completion. Keep compilation and emulator work sequential.
3. Install the exact final APK and launch its exported `com.godot.game.GodotAppLauncher` activity.
4. Validate actual touch movement, release over buttons, dodge, pulse, pause/background, and every native menu at the emulator viewport.
5. Open the sample-ad diagnostic. Observe a real video and exactly one earned callback; separately test early close and load failure. Record actual errors instead of claiming a reward from dismissal.
6. Run sustained native crowd scenarios, then physical-phone acceptance when available. Keep engine adoption provisional until the native evidence is credible.

No changes to router settings, publisher accounts, production ad IDs, or the hosted studio were made in this implementation pass.
