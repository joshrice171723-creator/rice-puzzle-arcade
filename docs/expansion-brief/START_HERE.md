# Rice Arcade — Codex Expansion Handoff (2026-10-18)

## Mission
Extend the EXISTING three-game Android studio with original arena-survival and tower-defense games. Do not rebuild the three existing games or replace the technology stack without a documented technical decision. Work incrementally, keep test ads and existing games working, and ship runnable local builds without requiring Google Play registration.

## Existing verified handoff context (not a fresh checkout)
- Repository: `joshrice171723-creator/rice-puzzle-arcade` (private); reported local workspace: `C:\Users\joshr\Documents\ChatGPT\games`.
- Existing games: Grid Foundry, Merge Drift, Color Cascade.
- Existing implementation uses Expo / React Native, not Godot: reported Expo ~58, React Native 0.88, `react-native-google-mobile-ads` 17.3.0. Verify against current repo before proceeding.
- Shared packages reportedly include `packages/ads`, `packages/game-utils`, `packages/ui`, and analytics. Native ad implementation, consent, and ad guards exist.
- AdMob app/unit mappings already exist in `packages/ads/publisher.json` as of reported commit `8d8a481...`. **Never recreate existing apps or ad units**; never expose production ad mode in internal builds.
- Latest handoff documents report unverified real-device ad display, no confirmed third-party mediation adapters, and no verified paid-event callback. Do not mark these as complete.
- Original ZIP named `outputs/Three_Games_Agent_Handoff_2026-10-18.zip` was referenced by the owner but was not available for direct inspection in this package. Inspect it locally if present; it overrides assumptions only where supported by actual current code.

## Immediate instructions to Codex
1. Inspect `git status`, current branch/HEAD, README, STATUS, package manifests, `apps/*`, `packages/*`, `docs/*`, scripts, and the local handoff ZIP if present. Preserve uncommitted work. Never reset, force-push, or overwrite.
2. Produce `docs/EXPANSION_AUDIT.md`: factual inventory, current build/test commands, dependencies, reusable modules, ad safety state, unknowns, and technical options.
3. Select the smallest compatible architecture for real-time games. **Do not assume the existing React Native UI layer is suitable for 60fps sprite-heavy action.** Evaluate Skia/React Native game loop vs a separate Godot/other engine app sharing tooling/assets/specs. Document trade-offs and get owner approval before major migration/new engine.
4. Implement one vertical slice (one arena, player movement, 2 enemy types, collision/damage, auto-attack, wave loop, pause/resume, local save, game-over). No ad integration needed for the first slice; preserve existing ads.
5. After slice is playable on Android, generalize only demonstrated shared components and implement distinctive games iteratively.

## Product goals
- Zero paid software/services required for development; Android sideload testing and optionally web previews. No Play Console account needed to test locally.
- Portrait-first and one-hand controls unless playtesting demonstrates otherwise.
- Clear readable stylized 2D/2.5D visuals, consistent performance on modest Android hardware. Do not claim that 2D/3D style statistically wins without controlled data.
- Short replayable sessions, upgrades, varied runs, strong retention hooks, original assets and titles.
- Reuse 2–4 foundational maps and 3–6 base enemy archetypes, **but make released games substantively different** in mechanics, level design, visuals, and player experience to avoid repetitive-content concerns.
- No copied game code, art, UI, branding, titles, sound, or misleading store metadata.

## Working titles (trademark/search clearance required)
1. **Nightfall Arena** — enclosed-map zombie survival; movement + auto-attack + pickups + escalating waves.
2. **Arcane Run** — magic survival; spell synergies, elemental status effects, different enemy behavior and objectives.
3. **Bullet Rush Arena** — shooter survival; ammo/reload or heat, destructible cover, weapon trade-offs, different win conditions.
4. **Last Stand Workshop** — hybrid arena defense; run around building/upgrading turrets, walls and traps between waves.
5. **Kingdom Path Defense** (later) — classic path-based tower defense; tower placement, targeting priorities, waves, economy.
Titles are placeholders and should NOT borrow distinctive competitor marks like Undead Night, Magic Archer, or Crazy Gunner.

## Definition of success
- Existing three games build and test exactly as before.
- Each new game has an independently installable debug APK, unique package ID, separate save namespace, and reproducible build steps.
- Game logic is deterministic/testable where practical; FPS and crashes measured on a physical Android device.
- No live ads in dev/QA; rewards only after native earned-reward callback; no forced ad engagement.
- No new account registrations, spending, publishing, live ad enablement, or legal agreement acceptance without explicit owner authorization.
- Progress is documented with evidence, screenshots, tests, build paths, and honest blockers.

## Execution cadence
Implement sequentially in small PRs/commits: audit → architecture decision → arena vertical slice → Nightfall Arena alpha → shared enemy/weapon framework → Arcane Run alpha → Bullet Rush alpha → hybrid tower defense prototype. Pause for owner review on architecture changes and before any production release configuration.

Read `GAME_DESIGNS.md`, `ARCHITECTURE_AND_REUSE.md`, `QA_MONETIZATION.md`, and `CODEX_KICKOFF_PROMPT.txt` next.
