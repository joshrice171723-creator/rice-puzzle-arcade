# Rice Puzzle Arcade status

Updated October 18, 2026. Three playable games; no app is published or earning verified revenue.

- Implemented: fixed illustrated themes, game sprites, Grid drag/hover, phone-sized gameplay, pause/settings/tutorials, persistent normal/daily/journey saves, and native AdMob/UMP integration.
- Implemented: 32 journey stages (12 Grid, 8 Merge, 12 Cascade), varied skill goals, sequential unlocks, free retries, visible progress, results scores and next-goal previews.
- Implemented: optional one-per-run video boosts at crowded boards/low time, shared with the failed-run continue. Only an SDK earned callback grants the benefit. Difficulty and random generation do not depend on ads.
- Verified: 98 logic tests and TypeScript. Browser play covered early level wins, persistence, all three failure paths, pressure offers, unavailable-ad fallback and free retry. All boards and controls fit 320x568 and 390x844 phone viewports.
- Reliability follow-up: 103 tests and TypeScript pass, including multi-seed gameplay/save-reload checks for all three engines. Merge now records spawned tile milestones correctly and recovers older saves with an understated highest tile.
- Native: Grid's first Android release APK compilation succeeded after repairing stale dependency resolution and Windows native object paths. Grid APK/AAB artifacts are available under artifacts/android/grid-foundry. The subsequent all-app build failed with disk-full errors (artifacts/all-games-native-final.log). About 1.9 GB is free and no Android device is connected at this check. Current source changes are not verified in an APK; no device installation or test-ad rendering is claimed.
- External: The owner's October 18 Dot handoff reports three AdMob app records and six ad units created, with account verification pending and app serving limited. Dot is handling account-side configuration; custom mediation, consent messages and app-ads.txt verification remain incomplete. Local access is still blocked by the home network. Website publication, store/signing approvals, audience/disclosures, actual retention measurement and paid serving remain release gates. Earlier account-status documents predate that handoff.

Preview URLs: Grid http://localhost:8081, Merge http://localhost:8082, Cascade http://localhost:8083. Launch with scripts/preview.ps1 -App <slug>. Browser ads are deliberately unavailable; test ad rendering requires the native APK.

The original brief is not fully release-complete. See docs/BLOCKERS.md, docs/ACCOUNT_SETUP_STATUS.md and docs/AD_INTEGRATION.md for the remaining gates.
