# Nightfall Arena — playable slice

A portrait, five-minute survival game in a walled industrial courtyard. Move with the thumb stick; the weapon targets enemies automatically. Walkers and faster runners approach from the edges. Cover blocks movement and shots. A green shelter changes position with each wave and restores health. Every third defeated enemy drops scrap; eight scrap powers one defensive pulse per run.

Supply drops at 1:15, 2:30, and 3:45 pause the action for a choice of three seeded upgrades. Survive 5:00 to win, or lose when health reaches zero. Difficulty depends on elapsed game time, never ads, earnings, personal information, or past failures.

## Run

From the repository root:

```powershell
pnpm install --frozen-lockfile
powershell -ExecutionPolicy Bypass -File scripts/preview.ps1 -App nightfall-arena
```

Open http://localhost:8084. Use WASD/arrow keys or drag the joystick. Space activates an available pulse. Escape/P pauses. Direction buttons are available in the pause menu. The full board and controls scale to portrait screens, including 320 × 568.

```powershell
pnpm typecheck
pnpm test
node scripts/nightfall-benchmark.mjs
powershell -ExecutionPolicy Bypass -File scripts/build-android.ps1 -App nightfall-arena -Architectures x86_64
```

Use `-Architectures arm64-v8a` for a physical Android phone. `all` retains the original three puzzle games; request this prototype explicitly. Internal APKs use development signing and are not store releases.

## Ownership and persistence

- Android package: `com.joshuarice.nightfallarena`.
- Save key: `rice-arcade:nightfall-arena:v1`, independent of all puzzle saves.
- Native AsyncStorage owns best score, longest survival, control preference, tutorial completion, and the current deterministic simulation snapshot.
- Save every five seconds and on pause, background, upgrade, defense, and run completion. Abrupt termination can lose at most the unsaved interval. Return to the home screen before resuming a restored run.
- Seeded, fixed 60 Hz simulation; long frames are capped at six steps. Background time does not become game time.
- Enemy/projectile/pickup caps: 120 / 64 / 40. Projectile collisions use 40-unit spatial bins.
- Canvas rendering is local and offline. All art is original procedural/vector work; regenerate the app icons with `node scripts/nightfall-assets.mjs`.
- No account, analytics upload, ad request, or rewarded benefit in this slice. The shared native template contains the dormant Google SDK with the official sample manifest ID. A production profile is blocked until a distinct publisher mapping exists.

## Scope

This is the first reviewable milestone in the expansion brief, not the complete Nightfall MVP. Further maps, weapons, enemies, bosses, sound/haptics, progression, monetization, and the three other planned games follow after playtest feedback. Physical-device performance and battery life require device testing. See `docs/ADR_001_ARENA_RENDERING.md` for the provisional renderer decision and `docs/EXPANSION_QA.md` for measured acceptance.
