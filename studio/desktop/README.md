# Game Studio desktop

Windows x64 Electron app. The packaged interface runs locally; reports are fetched over HTTPS from the existing authenticated collector at aimetaclinic.com. No public inbound port, local database server, or always-on laptop is required. Dashboard refreshes every 30 seconds while visible. Offline failures retain the last on-screen report with an explicit stale timestamp; a fresh offline launch cannot fetch a report.

The first launch asks for the existing Game Studio username and password. Credentials are encrypted by Electron safeStorage (Windows DPAPI) in the current Windows user's application-data directory. They are never sent to the renderer, bundled, or committed. Sign out removes the saved credential. The fixed report destination cannot be changed by the renderer. Local content uses a sandbox, context isolation, no Node integration, a content security policy, blocked external navigation and denied permission requests. TLS errors are not bypassed.

Build with Node 24:

```powershell
cd studio/desktop
npm ci
npm run package
powershell -ExecutionPolicy Bypass -File install.ps1 -Launch
```

The installer copies the packaged application into `%LOCALAPPDATA%/Programs/GameStudio/0.1.0` and adds Desktop and Start menu shortcuts. It does not require administrator access. Close the app before rebuilding/reinstalling. Builds are unsigned private owner builds, not a signed public distribution, and updates are manual. Keep Electron current before distribution.

All eight games are listed in `studio/catalog.json`. Planned games have no executable or telemetry yet. The four implemented games share the collector, with production analytics opt-in. The original three games also report SDK ad events; Nightfall does not request ads. AdMob revenue reporting is not connected.
