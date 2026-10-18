# QA, analytics, ads, release gates

## Existing ads: preserve safety
Existing handoff reports AdMob app/unit IDs for Grid Foundry, Merge Drift and Color Cascade stored in `packages/ads/publisher.json`; internal builds use Google test IDs and consent gating. `PUBLISHER_RELEASE_APPROVED=false` is the safe default. Verify all of this against current code. Do not copy real IDs into new games. No real ad clicks during testing. No claim of working mediation, paid events, or real-device ad rendering until proven.

## Future ads for new games
- Rewarded: optional revive, extra reward, reroll; grant reward only on validated earned-reward callback.
- Interstitial: only natural transitions, rate limited; never mid-combat.
- Offline, no fill, denied consent and failed ads must not block gameplay.
- Ask owner before creating new AdMob app/ad units, enabling live serving, linking stores, or changing privacy declarations.
- Investigate Play Families, GDPR/EEA consent, U.S. state privacy, age rating and SDK disclosures when preparing release; do not invent declarations.

## Tests
- Unit: spawn budgeting, damage/armor, upgrade stacking, collision, tower targeting, currency invariants, save migration, deterministic seeds.
- Integration: navigation, input, pause/resume, background/foreground, sound toggles, low-memory behavior, local persistence, offline.
- Regression: all three existing games and ad gates unaffected.
- Device: Android debug APK installed; FPS/frame time, memory, battery, responsiveness, crash logs, 15-minute soak.
- Security/privacy: no PII in analytics, consent honored, opt-out respected, no secret tokens in repo.

## Analytics events (privacy-minimal)
`game_start`, `tutorial_complete`, `run_start`, `run_end`, `wave_start`, `wave_end`, `upgrade_selected`, `player_death`, `ad_offer_shown`, `reward_earned`, `crash_reported` (where lawful/consented). No fabricated retention or revenue metrics. Existing collector endpoint is a reported config target, not verified deployed.

## Milestone exit gates
M0 audit: repository facts + green existing tests/builds or documented blockers.
M1 architecture: written decision with measured prototype.
M2 slice: real Android build and recorded video/screenshots.
M3 first alpha: full 5-minute playable run, local progression, device QA.
M4 game 2: mechanically distinct, shared code proven.
M5 game 3: distinct combat and objectives, regression green.
M6 hybrid defense: strategic build phase and balance tested.

## Market validation later
No Play Store payment required now. When publishing is possible, test store listing/search, installs, D1/D7 retention, crash-free sessions, sessions/user and ad metrics. No revenue promises. Google Play policy and developer testing requirements must be rechecked at release time.
