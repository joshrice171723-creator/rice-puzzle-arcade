# Studio desktop delivery — October 18, 2026

## Delivered

- Windows x64 desktop application with Desktop and Start menu shortcuts. Installed to `%LOCALAPPDATA%/Programs/GameStudio/0.1.0`.
- Local packaged dashboard; authenticated HTTPS reports from aimetaclinic.com. Saved login encrypted using Windows DPAPI through Electron safeStorage. No credential is shipped in the app or committed.
- Shared eight-game catalog, including Kingdom Path Defense. Three puzzles marked playable, Nightfall marked prototype, four games marked planned. Planned games are not claimed implemented.
- Existing SQLite collector expanded without changing schema. New run IDs are aggregated within installation scope. Invalid numeric telemetry is rejected before it can break aggregation.
- Nightfall sends optional run/resume/progress/end/exit, active play, wave and upgrade events through the existing persistent outbox. Production defaults off. A separate Privacy screen preserves small-phone layout.
- Online database backups made before the versioned service updates. `/opt/game-studio/previous` retains rollback source. Clinic services and nginx authentication configuration were not changed.

## Evidence

- `pnpm test`: 16 files, 243 tests passed. `pnpm typecheck`: passed.
- Python collector: 6 tests passed locally and on the deployment host. Covers deduplication, test/production separation, revived-run final outcomes, all eight catalog entries, invalid numeric fields and installation-scoped run IDs.
- Packaged executable started successfully, imported the existing owner login once, then reopened from its installed directory using the encrypted saved login.
- Packaged renderer inspection: all eight game headings present; authenticated connected report; no Node `require` available in the renderer. Actual screenshot at `artifacts/studio/desktop.png`.
- Actual Nightfall browser play delivered one installation/session, resumed run, one minute of active time, wave transition, score 570 and run exit to the online collector. This was test activity, not a production player.
- Browser report filters: production showed zero installations/runs/boosts; test showed existing test activity plus Nightfall. Nightfall level filter correctly had no puzzle-level attempts.
- Browser connection-loss test retained all eight cards with an explicit offline/last-report timestamp; connectivity restored afterward.
- Nightfall home/continue/privacy button fit 320×568: page height 568; panel client/scroll heights both 520. Temporary viewport overrides removed afterward.

## Limits

This is an unsigned private Windows build with manual updates. Revenue is not connected; SDK ad lifecycle events do not establish paid impressions or earnings. New Nightfall instrumentation was verified in the browser; its earlier installed Android APK predates this change and must be rebuilt before claiming native telemetry acceptance. Four planned games cannot send gameplay until implemented. Native Nightfall performance acceptance remains incomplete (see EXPANSION_QA.md). Reports cover received events, not guaranteed complete activity or verified unique people.
