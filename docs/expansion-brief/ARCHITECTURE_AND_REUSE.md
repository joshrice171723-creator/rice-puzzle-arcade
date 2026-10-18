# Architecture / reuse decisions

## Existing baseline — inspect, don't assume
The original three games are reportedly Expo/React Native apps with shared ads, game utilities, UI and analytics. Do not force Godot into these apps without investigating packaging, asset pipeline, shared TypeScript logic, build maintenance and APK sizes.

## Architecture decision record (required)
Compare:
A. Expo/React Native + Skia/custom fixed timestep loop for lightweight 2D action.
B. Separate Godot Android games inside the existing monorepo with shared source assets/config/test harness and a native ad bridge (not automatically compatible with existing RN ads).
C. Alternative only if justified with measured constraints.
Assess 100+ enemies, collision, draw calls, profiling, Android APK/export, ad SDK consent, CI, maintainability, shared modules, effort. Pick based on prototype benchmarks, not preferences.

## Proposed logical modules
- `game-core`: deterministic simulation clock, collision, health, damage, save schema, seeded RNG.
- `arena`: player controller, obstacles, navigation, spawn director, wave state machine.
- `combat`: weapons, projectiles, status effects, targeting and upgrade registry.
- `defense`: placement grid, structures, pathing, economy and targeting rules.
- `content`: data-defined enemies, maps, weapons, tuning, visual skins.
- `platform`: lifecycle, touch input, audio, haptics, save adapter, consent/ads interface.
- `analytics`: privacy-aware event schema and optional collector adapter.
These are conceptual boundaries; adapt directory names to actual repo conventions.

## Game identity
Each title requires distinct app identifier, display name, icon, save namespace, analytics app key and (later, only if approved) its own AdMob app/ad units. Never reuse existing three games' production IDs for new apps.

## Reuse discipline
Shared assets: base animations, collision shapes, sound pipeline, AI behaviors, 2–4 map geometries. Distinct game design: objectives, weapons, upgrade interactions, obstacles, visual theme, progression and pacing. Do not publish reskins that differ only by color or name.

## Performance and reliability
Fixed timestep simulation where feasible; cap delta on resume; object pooling for projectiles/enemies; collision broad phase; enemy budget limits; avoid per-frame React state re-render; instrument frame times; handle pause, app background, screen resize, device rotation, no network.
