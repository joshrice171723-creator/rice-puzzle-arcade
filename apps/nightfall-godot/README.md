# Nightfall Godot engine proof

Isolated, playable technical prototype using Godot **4.7.2 stable**, Compatibility rendering, and typed GDScript. The existing Expo Nightfall and three puzzle games are untouched. See [delivery plan](../../docs/nightfall/BUILD_PLAN.md) for the full product scope.

This is the M0 engine evaluation plus the first M1 combat feature increment. It is not the first production zone. No persistent progress, real purchases, production publisher IDs, mediation, telemetry upload, or earned loot economy is enabled. See [combat slice verification](../../docs/nightfall/COMBAT_SLICE_QA.md) and the [deferred bug log](../../docs/nightfall/KNOWN_ISSUES.md).

## Play

From the repository root in PowerShell:

```powershell
./scripts/nightfall-godot.ps1 -Action Play
```

The helper defaults to the locally installed portable executable under `%LOCALAPPDATA%/NightfallTools/Godot-4.7.2/`. Pass `-Godot` to use another installation of the same version. Godot is not committed to Git. No Docker or Node server is required.

- WASD/arrows or drag the left side to move. Automatic fire targets nearby enemies.
- Space / Dodge: short invulnerable movement, three-second cooldown.
- E / Pulse: area damage and knockback, eight-second cooldown.
- Escape / pause button: pause. Backgrounding also pauses; resume is explicit.
- Collect violet experience drops to choose a temporary upgrade.
- Learn Ember Bolt, Frost Ring, or Chain Spark at the first level-up. Later choices upgrade spells to rank three, improve the pistol, or restore missing health. Spells cast automatically while enemies are in range.
- Four wave phases introduce Drifters, fast Rift Runners, and ranged Ash Spitters. Spitter aim lines lock before firing, leaving time to move away.
- Four minutes of waves, then a mandatory boss kill. Boss fight has no time limit.
- The Breaker marks a charge lane, slams the ground around itself, and throws three projectiles. Its attack interval shortens below half health. A gold HUD bar tracks its health.
- **Practice The Breaker** starts a separate no-reward fight with three rank-one spells; it does not skip or complete a campaign mission.
- The pause menu's 30/60/120-foe buttons are **invulnerable diagnostic modes**, not balanced missions.

Android has a separate **Test rewarded video** diagnostic in the pause menu. It uses Google sample identifiers and shows an earned-callback counter. It does not grant inventory or imply production revenue. Consent/network failures appear in the diagnostic; they never manufacture a reward. Desktop has no simulated ad-success fallback.

## Verify and export

```powershell
./scripts/nightfall-godot.ps1 -Action Test
./scripts/nightfall-godot.ps1 -Action Windows
./scripts/nightfall-godot.ps1 -Action Android
```

The graphical batching regression runs with a window, not headless:

```powershell
& "$env:LOCALAPPDATA/NightfallTools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" --path apps/nightfall-godot --script tests/render_test.gd
```

It exercises 120 enemies and 40 experience pickups with a 60-draw-call ceiling. Shadows and pickups share small textures; actors remain depth-sorted, with health bars drawn afterward. Ordinary play no longer retains an unbounded frame-history array; detailed frame samples are collected only during explicitly timed benchmarks.

Exports land in `artifacts/nightfall-godot/`, excluded from Git. Use internal debug builds only. Android package: `com.joshuarice.nightfallproof`, deliberately distinct from the older prototype.

Prerequisites: matching official Godot export templates, Android SDK platform 36, build tools 36.1.0, installed NDK 27.1.12297006, and Android Studio's JBR. The helper extracts the matching Android template, copies the Kotlin bridge, and pins Kotlin 2.3.20 because Ads 25.5.0 requires newer metadata than the template's compiler. Gradle uses two workers and a 1536 MB heap to limit workstation pressure. Native compilation runs before emulator QA.

Install the portable engine and templates from the [official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable); verify against that release's SHA512-SUMS.txt. The proof uses Android debug/release templates, Android source, and Windows x86_64 templates only. Keep the Android build directory ignored by Godot with `android/.gdignore`; the helper creates this before export.

Android v2 plugin metadata and SDK dependencies come from `addons/nightfall_ads/export_plugin.gd`. The bridge source is `native/NightfallAds.kt`; the helper copies it into the generated Android template. This source-in-template packaging is deliberate for the isolated proof, not a published reusable AAR plugin.

## Reproducible render sample

```powershell
& "$env:LOCALAPPDATA/NightfallTools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" `
  --path apps/nightfall-godot -- --crowd=120 --autoplay --seconds=30 `
  --report=C:/absolute/output/desktop-120.json --capture=C:/absolute/output/desktop-120.png
```

Create the output directory first. The first three seconds are excluded from timing samples. Reports identify the engine, operating system, renderer, crowd size, frame count, mean FPS, p95 frame time, and Godot static memory. Static memory is not total process memory. Automated movement is diagnostic, not a skilled-player model. Desktop/emulator measurements do not establish physical-phone performance.

## Known scope limits

- AI-generated four-frame, one-view walking art uses mirrored horizontal facing. It is an animation/layout sample, not the planned eight-direction production rig.
- One floor texture; walkable bounds are explicit and tall environmental collisions/occlusion are not implemented.
- Enemy variants currently reuse tinted/scaled atlas artwork and small shape markers. The boss also uses enlarged enemy artwork; production silhouettes and animation remain unfinished.
- No shrines, Haven, field building, equipment, classes, stash, saves, or sound yet. These remain subsequent milestones.
- Entity caps: 120 enemies, 64 shots, 40 pickups. Dense crowds overlap; separation/pathing still needs production work.
- All HUD controls fit a 430×760 logical canvas; differing aspect ratios letterbox rather than introduce scrolling. Physical safe-area and accessibility acceptance remains separate.

Godot and third-party notices must accompany a distributable release; see [Godot license requirements](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html). This proof is not approved for store distribution.
