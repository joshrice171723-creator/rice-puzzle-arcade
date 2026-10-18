# Nightfall Arena slice acceptance

Date: 2026-10-18. Branch: `codex/arena-expansion`. Gameplay implementation: `df0fc2e`.

## Source and automated checks

- `pnpm typecheck`: passed.
- `pnpm test`: 15 files / 241 tests passed, including the original 231 tests and 10 new simulation tests.
- New coverage: deterministic replay/save continuation, normalized input and timestep caps, wall sliding/bounds, contact damage/invulnerability/loss, capped reusable slots, bullet hits/cover/piercing, all three upgrade milestones, five-minute completion, one-use earned defense, shelter healing, damaged-save rejection.
- `node scripts/nightfall-benchmark.mjs`: 18,000 fixed steps at a maintained 120-enemy load. Local Node p50 0.082 ms, p95 0.386 ms, p99 3.138 ms under concurrent Android compilation. Not device rendering/FPS measurements. Slots remained bounded: 120 enemies, 3 shots, 27 pickups in this run.
- Twenty deterministic, unassisted scripted-route balance runs: 2 wins at 300 seconds; 18 losses at 211–277 seconds. The bot does not avoid individual enemies or optimize shelter usage. These runs prove both completion and failure are reachable; they are not a human difficulty or retention study. The stress benchmark alone uses invulnerability to maintain load; the twenty balance runs do not.

## Browser acceptance

In-app Chromium at `http://localhost:8084/`:

- Fresh start → tutorial → gameplay, auto-fire, enemies, scoring, damage, loss → restart.
- A joystick hold moved the player from x=200 to x≈352 and releasing stopped that input. Save/reload restored its position and elapsed time. Paused time did not advance.
- 320 × 568 and 390 × 844: complete arena, health, score, countdown, joystick, and defense control stay within the viewport. Home/continue, pause, upgrade, and result panels were checked without page/panel scrolling at 320 × 568. Canvas keeps its 400:560 aspect ratio.
- Synthetic saved-state fixture: Field medic upgraded max health 100→125 and healed 65→105, then continued shelter healing. Only one upgrade was recorded.
- Synthetic 120-enemy scene ran approximately 68 seconds: displayed 60 fps / 17 ms frame-time p95; 120 enemies remained active. Screenshot: `artifacts/nightfall/browser-stress-120.png`. This was desktop Chromium, not Android hardware.
- In that fixture, the earned-defense button consumed its availability, cleared nearby enemies, awarded their normal scrap/score, and became disabled as “Used this run.”
- Synthetic QA state was removed and the prior normal run restored. No production test switch or hidden difficulty override was added.

## Native acceptance

Internal x86_64 APK and AAB built successfully. API 30 emulator launch, tutorial, joystick input, auto-fire, scoring, background pause and force-stop recovery were exercised. Offline recovery restored 0:34 and score 365. The initial native soak measured only 7–11 fps (p95 200–383 ms); performance is not accepted. A retry with explicit GPU acceleration was stopped for owner design review. The full 15-minute soak and physical-device acceptance remain incomplete. Emulator networking was restored.

## Remaining product scope

This milestone contains one map, two enemy archetypes, one automatic weapon, eight upgrade definitions, three choices per run, a moving healing shelter, and a one-use scrap defense. It is not the later full MVP. Further maps, bosses, weapon choices, sound/haptics, progression, ad integration, publishing, and the other three games remain outside this slice.

No ads were requested by this tested build. Subsequent desktop-dashboard work adds optional gameplay telemetry; that source change is not included in the APK described above. No production ad units were created or reused. Physical-device frame rate, thermals, battery drain, and real-player difficulty/retention remain unverified.
