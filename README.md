# Rice Puzzle Arcade

Three separate offline Android puzzle games built with React Native and Expo 58:

| App | Play | Android package (provisional until Play registration) |
| --- | --- | --- |
| Grid Foundry | Place shapes on an 8×8 grid; clear rows and columns | `com.joshuarice.gridfoundry` |
| Merge Drift | Swipe a 4×4 board; combine equal numbers | `com.joshuarice.mergedrift` |
| Color Cascade | Tap connected groups; score within 90 active seconds | `com.joshuarice.colorcascade` |

## Run

Use Node 24 and pnpm 11.25.0. From the repository root:

```sh
pnpm install
pnpm test
pnpm typecheck
pnpm --filter @arcade/grid-foundry web
pnpm --filter @arcade/merge-drift web
pnpm --filter @arcade/color-cascade web
```

Browser builds run the actual shared gameplay and persistence, with advertising disabled. Native AdMob needs a development or internal Android build, not Expo Go. See `docs/BUILD.md` for installable artifacts and native build commands.

## Layout

- `apps/*/game.ts`: pure, seeded, separately tested engines
- `apps/*/GameScreen.tsx`: distinct touch controls, animation and visual design
- `packages/ui`: shared launch, pause, tutorial, preferences and results flow
- `packages/game-utils`: versioned local saves and statistics
- `packages/ads`: native UMP/AdMob adapter and tested advertisement lifecycle
- `website`: publisher site source; account setup and publication are deferred

Each app saves progress on-device. Daily challenges derive a seed from the local calendar date and app name. Randomness and game difficulty never read advertising or consent data.

## Advertising and publishing

Development/internal builds use official Google sample IDs. An optional earned reward can revive a run once; dismissal or failure cannot award it. Interstitials are limited to end-of-run transitions with session, round-count and cooldown requirements. Web never simulates a successful ad.

Production configuration is deliberately blocked until real owner IDs and audience/privacy review are supplied. No store release, paid serving, publisher approval or earnings are represented as verified. See `STATUS.md` and `docs/BLOCKERS.md`.

No signing credentials belong in Git. Android native directories are generated from the reviewed app configurations; package IDs and target API are verified during prebuild/CI.
