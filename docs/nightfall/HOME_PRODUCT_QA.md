# Nightfall home product — October 18, 2026

## Delivered

- Five fixed destinations: Shop, Gear, **Expedition** in the middle, Base, Class.
- Illustrated Haven with the selected character, Workshop, Infirmary, Storehouse, Training, Arcanum and Expedition entrances. Facility upgrades retain their real effects and costs.
- Eight equipped slots, including Ring and Pants; five-column inventory scrolls vertically independently of the character and navigation. Item details support equip, upgrade, promotion and confirmed salvage.
- Version-1 saves migrate to eight slots without discarding wallet, existing item IDs/upgrades or active expedition checkpoints. The starter budget remains 40 Power, 210 HP, 35 Armor.
- Shop supports chest categories, confirmed earned-currency purchases, and two optional rewarded-video supply keys per UTC day. The token-bound earned callback grants a key once; dismissal alone grants nothing. Failed save attempts retain the earned reward for retry.
- Expedition shows the first zone's five missions and mastery/reward entrance. Twenty-zone overview preserves planned names; unbuilt zones remain locked. No new combat mechanics were added in this delivery.
- Class roster supports actual unlocked selections and mastery; future Warden/Arcanist previews remain locked.

## Visual direction

The initial implementation was too flat and dark compared with the selected concept. The revision uses a cobalt illustrated backdrop, crescent Nightfall identity, Cinzel headings, compact Barlow text, upright menu character portraits, colorful equipment art and rarity borders. Wallet and key combat stats use images with numbers. Base rank badges replace large building labels. Expedition uses its own illustrated Outskirts island. Inventory entries always represent owned items; the app does not populate decorative fake loot.

Runtime assets live in `apps/nightfall-godot/assets/`. Exact built-in image-generation prompts are preserved in `art-concepts/HOME_ASSET_PROMPTS.md` and `art-concepts/MENU_POLISH_PROMPTS.md`. Fonts include their SIL Open Font License files. The menu character portrait is class artwork, not a dynamically composited representation of every equipped item.

## Verification

- Full Godot suite passed: 2,499 checks at the initial visual revision, including 1,675 layout checks. Subsequent final menu layout checks: 1,672 passed; home product: 103 passed plus five screenshot captures (108 total). Count changes reflect different visible controls, not removed viewport coverage.
- Layout coverage: 320×568, 390×844, 430×760; main pages, facilities, item details and all four class previews. Inventory fixture contains 50 items and verifies scrolling to the last item while the hero stays fixed.
- Product checks cover legacy migration, persistent purchases, write-failure rollback, stale/duplicate/missing reward callbacks, daily cap, retry after an earned reward save fails, controller callback routing, facility upgrades, sorting and navigation.
- Rendered desktop captures: `artifacts/nightfall-godot/home-review/{gear,haven,mission,shop,class}.png`. These use disposable test profiles, not the player's save.
- Native touch emulation is enabled only while home is visible and restored on return to combat. Native acceptance is recorded below after installation.

## Android installation and screen review

The menu/ad acceptance APK exported successfully and was installed with `adb install -r` on the API 30 emulator. Package: `com.joshuarice.nightfallproof`. Acceptance SHA-256: `77D41B0D6EECE88ECC869832555391ED03CFA67A116E5B0E61822C33DB2A70A0`.

Native captures in `artifacts/nightfall-godot/home-review/android-{expedition,gear,base,class,shop}.png` verify all five destinations on the installed build. Actual pointer taps changed tabs; captures must wait for the next rendered frame. Existing zero balances, eight items, and the saved active expedition were preserved. The protected loadout correctly remains locked during that expedition.

Shop rewarded-video acceptance: Google's sample Flood-It ad loaded, displayed the **Test Ad** and **Reward granted** indicators, and was dismissed through its close button. The Shop then showed one supply key, one of two daily videos remaining, and `Supply key saved.` Evidence: `android-shop-video.png` and `android-shop-earned.png`. No advertiser installation or production ad click was performed. This confirms the new Shop reward flow on the emulator, not campaign rescue or production revenue.

The app was force-stopped and relaunched after the ad. Shop still showed one supply key and one remaining claim (`android-shop-restart.png`), confirming persistence through a native process restart. A subsequent label-only adjustment changes the receipt summary to `Keys · 1` to avoid singular/plural wording.

The label-adjusted delivery APK was also exported, installed and launched successfully: SHA-256 `03A2AA330DC7A605A565971407E33E7CBC302C0C722A86EE481633629D2C6338`. Its persisted native profile was read back: version 2, one key, one video used, eight items, active attempt 1. Gear is left open for visual review. Ad completion was not repeated after this text-only adjustment.

## Remaining boundaries

Google sample rewarded ads are wired, not production monetization. Real-money billing and production mediation revenue are not established by these tests. Local currency and daily limits are prototype state, not a server-authoritative commerce service. Zones 2–20 remain future content. Physical-phone performance and long-session acceptance remain open. Known fixture teardown warnings are tracked as NF-006; Android helper waiting is NF-003.
