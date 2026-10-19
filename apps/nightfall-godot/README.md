# Nightfall Godot engine proof

Isolated, playable technical prototype using Godot **4.7.2 stable**, Compatibility rendering, and typed GDScript. The existing Expo Nightfall and three puzzle games are untouched. See [delivery plan](../../docs/nightfall/BUILD_PLAN.md) for the full product scope.

The current feature build implements the first five-mission Outskirts zone, local Haven progression, scavenging/shrines, construction, eight branching spell families, earned loot/chests, boss practice and Salvage Contracts. It is still an internal prototype: production purchases, publisher IDs/mediation, telemetry upload, physical-phone acceptance and a balanced full campaign remain unfinished. See the [feature-session record](../../docs/nightfall/FEATURE_BUILD_SESSION.md) and [deferred bug log](../../docs/nightfall/KNOWN_ISSUES.md).

## Play

From the repository root in PowerShell:

```powershell
./scripts/nightfall-godot.ps1 -Action Play
```

The helper defaults to the locally installed portable executable under `%LOCALAPPDATA%/NightfallTools/Godot-4.7.2/`. Pass `-Godot` to use another installation of the same version. Godot is not committed to Git. No Docker or Node server is required.

- WASD/arrows or drag the left side to move. Automatic fire targets nearby enemies.
- Space / Dodge: short invulnerable movement, three-second cooldown.
- All weapons, spells and class support powers activate automatically. Dodge is the only manual combat ability. E/Q no longer trigger attacks.
- Escape / pause button: pause. Progress shows live bonus-medal or contract requirements; How to play holds instructions. Backgrounding also pauses; resume is explicit.
- Collect violet experience drops to choose a temporary upgrade.
- Learn Ember Bolt, Frost Ring, or Chain Spark at the first level-up. Later choices include Orbiting Wisp, Stone Lance, Consecrated Ground, Spectral Blades and Gravity Knot. Three attack slots and three passive types support different builds. Rank two chooses one of two specializations; rank three plus its paired passive evolves the attack. The Arcanum previews every path.
- Four wave phases introduce Drifters, fast Rift Runners, and ranged Ash Spitters. Spitter aim lines lock before firing, leaving time to move away.
- Four minutes of waves, then a mandatory boss kill. Boss fight has no time limit.
- Garage Mauler, Fence Runner, Porchcaller, Scrapback and The Breaker have distinct attack combinations and boss artwork. Thin boss health appears below XP. Ordinary player health follows the hero; the opaque header and default help card have been removed.
- **Training Yard** unlocks each boss when encountered, even after defeat. Choose one of three spell presets with your equipped gear. No campaign rewards or progression are granted.
- **Salvage Contracts** unlock after mission one: open three caches, wait for the 90-second beacon, then hold its ring for three seconds before the three-minute deadline. Choose a targeted equipment slot. Every third clear earns a supply key.
- Tab / Pack protects up to two starting loot bundles; B / Build opens field construction. Victory banks all carried loot. Defeat retains protected bundles, Credits and earned permanent XP.
- Haven offers equipment upgrades/promotion/salvage, earned chests, facilities, class selection and mastery. Scavenger starts unlocked; Engineer unlocks after mission four. Their mastery perks unlock at levels 5/10/15/20. Warden and Arcanist remain future campaign unlocks.
- Settings contains separate internal diagnostic tools. Its 30/60/120-foe controls are invulnerable performance fixtures, not ordinary missions.

Android uses Google sample identifiers. A native earned callback can grant one expedition rescue at 50% HP; request tokens prevent duplicate/stale rewards. Expired contracts cannot request an unusable rescue. Internal ad diagnostics are separate from the ordinary Pause menu. Desktop has no simulated ad-success fallback. Automated tests simulate callbacks explicitly; they do not prove actual video delivery or production revenue.

`user://haven.json` stores the local profile and active expedition checkpoint with atomic replacement and a backup. Returning to Haven or backgrounding checkpoints the run. Resume is explicitly paused. Original music/effects and audio/accessibility preferences are saved. This local profile is not a secure ledger for paid currency.

## Verify and export

```powershell
./scripts/nightfall-godot.ps1 -Action Test
./scripts/nightfall-godot.ps1 -Action Windows
$env:GRADLE_OPTS = '-Dorg.gradle.daemon=false'
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

- Scavenger and Engineer use separate AI-generated four-frame, one-view walking atlases with mirrored horizontal facing. These are animation/layout samples, not the planned eight-direction production rigs.
- One floor texture; walkable bounds are explicit and tall environmental collisions/occlusion are not implemented.
- Ordinary enemy variants reuse tinted/scaled atlas artwork and small shape markers. Five bosses have distinct neutral/wind-up poses; full directional production animation remains unfinished.
- Five missions in one zone are implemented, not the planned twenty zones/one hundred missions. Equipment upgrades currently stop at level five; promotion stops at Rare, while earned chests can roll Epic. Later rarity progression, the remaining classes/facilities/modes and production commerce remain future scope.
- Rule tests and static layout fixtures establish bounded behavior, not whether the game is fun or appropriately difficult. Human balance passes and native soak tests remain necessary.
- Entity caps: 120 enemies, 64 shots, 40 pickups. Dense crowds overlap; separation/pathing still needs production work.
- All HUD controls fit a 430×760 logical canvas; differing aspect ratios letterbox rather than introduce scrolling. Physical safe-area and accessibility acceptance remains separate.

Godot and third-party notices must accompany a distributable release; see [Godot license requirements](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html). This proof is not approved for store distribution.
