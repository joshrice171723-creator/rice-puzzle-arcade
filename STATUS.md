# Rice Puzzle Arcade status

Updated October 18, 2026. Three playable games; no app is published or earning verified revenue.

- Implemented: fixed illustrated themes, game sprites, Grid drag/hover, phone-sized gameplay, pause/settings/tutorials, persistent normal/daily/journey saves, and native AdMob/UMP integration.
- Implemented: 32 journey stages (12 Grid, 8 Merge, 12 Cascade), varied skill goals, sequential unlocks, free retries, visible progress, results scores and next-goal previews.
- Implemented: optional one-per-run video boosts at crowded boards/low time, shared with the failed-run continue. Only an SDK earned callback grants the benefit. Difficulty and random generation do not depend on ads.
- Verified: 98 logic tests and TypeScript. Browser play covered early level wins, persistence, all three failure paths, pressure offers, unavailable-ad fallback and free retry. All boards and controls fit 320x568 and 390x844 phone viewports.
- Native: Grid's first Android release APK compilation succeeded after repairing stale dependency resolution and Windows native object paths. The final reproducible APK/AAB build is being verified; see docs/TEST_RESULTS.md for artifact receipts. No device installation or test-ad rendering is claimed.
- External: AdMob account creation remains blocked by DNSFilter for apps.admob.com. The owner authorized Gmail account setup, but no publisher account or real ad units were created. Website publication, store/signing approvals, audience/disclosures, actual retention measurement and paid serving remain release gates.

Preview URLs: Grid http://localhost:8081, Merge http://localhost:8082, Cascade http://localhost:8083. Launch with scripts/preview.ps1 -App <slug>. Browser ads are deliberately unavailable; test ad rendering requires the native APK.

The original brief is not fully release-complete. See docs/BLOCKERS.md, docs/ACCOUNT_SETUP_STATUS.md and docs/AD_INTEGRATION.md for the remaining gates.
