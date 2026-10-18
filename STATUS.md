# Rice Puzzle Arcade status

Updated October 18, 2026. Three playable games; no app is published or earning verified revenue.

- Implemented: fixed illustrated themes, game sprites, Grid drag/hover, phone-sized gameplay, pause/settings/tutorials, persistent normal/daily/journey saves, and native AdMob/UMP integration.
- Implemented: 10 named zones with 10 levels per game (300 total), sequential unlocks, zone selection, saved attempts, and zone-finale results.
- Implemented: journey completion requires three prior failed attempts at global levels divisible by seven, and an earned rewarded boost at stages eight and ten of each zone. Failed results offer a video continue or retry. Only an SDK earned callback grants credit; board RNG is unchanged.
- Verified: 215 tests and TypeScript, including zone boundaries, attempt persistence, earned-boost requirements and every-third-level interstitial eligibility. All three zone menus fit 320x568 browser viewports; last-zone navigation and resumed Merge gameplay were checked.
- Gameplay: 100 Cascade numeric objectives are reachable by the scripted baseline within the base timer. This checks the objective only; completion gates still apply. Human difficulty and enjoyment remain unmeasured. Existing normal/daily progress and unlocked levels are preserved.
- Native: the previously disk-blocked ARM APK/AAB builds now succeed for all three games. A WHPX-accelerated Android 11 virtual phone is installed and booted. All three dual-ABI APKs installed and reported successful cold starts; Grid and Merge also logged React Native main running. No native ad display or earned-reward journey has been verified. See docs/TEST_RESULTS.md for the final artifact receipt and limitations.
- External: The owner's October 18 Dot handoff reports three AdMob app records and six ad units created, with account verification pending and app serving limited. Dot is handling account-side configuration; custom mediation, consent messages and app-ads.txt verification remain incomplete. Host DNS remains filtered; the emulator now uses validated Google Private DNS and can resolve the ad server. Website publication, store/signing approvals, audience/disclosures, actual retention measurement and paid serving remain release gates. Earlier account-status documents predate that handoff.

Preview URLs: Grid http://localhost:8081, Merge http://localhost:8082, Cascade http://localhost:8083. Launch with scripts/preview.ps1 -App <slug>. Browser ads are deliberately unavailable; test ad rendering requires the native APK.

The original brief is not fully release-complete. See docs/BLOCKERS.md, docs/ACCOUNT_SETUP_STATUS.md and docs/AD_INTEGRATION.md for the remaining gates.
