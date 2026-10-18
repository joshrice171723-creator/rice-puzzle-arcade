# Rice Puzzle Arcade status

Updated October 18, 2026. Three playable games; no app is published or earning verified revenue.

- Implemented: fixed illustrated themes, game sprites, Grid drag/hover, phone-sized gameplay, pause/settings/tutorials, persistent normal/daily/journey saves, and native AdMob/UMP integration.
- Implemented: 32 journey stages (12 Grid, 8 Merge, 12 Cascade), varied skill goals, sequential unlocks, free retries, visible progress, results scores and next-goal previews.
- Implemented: optional one-per-run video boosts at crowded boards/low time, shared with the failed-run continue. Only an SDK earned callback grants the benefit. Difficulty and random generation do not depend on ads.
- Verified: 123 tests and TypeScript, including 29 ad-service/adapter tests and multi-seed gameplay/save-reload checks. Browser play covered early level wins, persistence, all three failure paths, pressure offers, unavailable-ad fallback and free retry. Inspected gameplay and result controls fit 320x568 and 390x844 phone viewports.
- Gameplay follow-up: goal-specific strategy tips across all 32 stages; all 12 Cascade stages have a scripted no-boost completion path. Cascade's final score target is now 13,000 after the baseline player fell short of the previous 15,500. Human difficulty and enjoyment remain provisional. Merge saves correctly include spawned tile milestones and recover older understated highest-tile values.
- Native: the previously disk-blocked ARM APK/AAB builds now succeed for all three games. A WHPX-accelerated Android 11 virtual phone is installed and booted. All three dual-ABI APKs installed and reported successful cold starts; Grid and Merge also logged React Native main running. No native ad display or earned-reward journey has been verified. See docs/TEST_RESULTS.md for the final artifact receipt and limitations.
- External: The owner's October 18 Dot handoff reports three AdMob app records and six ad units created, with account verification pending and app serving limited. Dot is handling account-side configuration; custom mediation, consent messages and app-ads.txt verification remain incomplete. Local access is still blocked by the home network. Website publication, store/signing approvals, audience/disclosures, actual retention measurement and paid serving remain release gates. Earlier account-status documents predate that handoff.

Preview URLs: Grid http://localhost:8081, Merge http://localhost:8082, Cascade http://localhost:8083. Launch with scripts/preview.ps1 -App <slug>. Browser ads are deliberately unavailable; test ad rendering requires the native APK.

The original brief is not fully release-complete. See docs/BLOCKERS.md, docs/ACCOUNT_SETUP_STATUS.md and docs/AD_INTEGRATION.md for the remaining gates.
