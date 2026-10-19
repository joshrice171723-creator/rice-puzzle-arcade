# Illustrated field choices and spell presentation

The Artificer's Shrine now offers three illustrated trait cards. Twinflame Shrine offers two illustrated relic cards. Each includes a name, distinct artwork, effect, rank/type, and a selection or purchase button. Scrap prices use the parts icon. Unaffordable and maxed traits remain disabled; rerolls retain their original cost and limit.

Level-up and specialization choices use the same cards with existing spell artwork or a relevant passive icon. Long descriptions scroll inside their card so exact numbers, limits and tradeoffs remain available without moving the entire popup off a small phone screen. They are not truncated. Choosing a card still calls the existing Run/Field action; no combat, price, XP or inventory values changed.

World shrines render at 132×150 logical units; closed/open chests at 56×53. This makes shrines about 2.8 times the chest height. Existing 60-unit proximity radius, charge times, progress rings and reward limits remain unchanged.

Combat now uses a separate transparent painted VFX atlas for firebolts and impacts, frost bursts, chain lightning, orbiting wisps, stone lances, spectral blades, consecrated ground and gravity vortices. These world effects replace the previous enlarged ability icons and simple placeholder attack strokes. The HUD still uses its normal ability icons. Enemy danger telegraphs and structure effects retain their existing ownership.

## Verification

- 29 regression suites / 7,579 checks passed after integrating the cards and renderer. The new card suite covers 430×760 and 320×568, correct selection, exact trait costs, disabled prices, popup containment and actual artwork.
- Card captures: `artifacts/nightfall-godot/shrine-cards/traits-430.png`, `relics-430.png`, `powers-320.png`.
- Dedicated spell rendering fixtures passed 42 checks across all eight spell families in normal and Reduced Effects modes and assert unchanged simulation snapshots. The final card graphics run passed 47 checks with captures.
- Full-crowd graphics fixture remains at 89 draw calls against a budget of 100. This fixture is a crowd/effect regression check, not a claim about sustained mobile FPS with every spell active.
- Independent review found a missing “per rank” qualifier on Vitality; it was restored. No other concrete issue was reported.

Art prompts and provenance are beside this note and in the combat VFX documentation. Generated artwork lives in the repository, not an external temporary folder.

## Android installation

Exported and installed `nightfall-proof.apk` on `emulator-5554` on October 19, 2026. SHA-256: `9AAE81AE16A35661CC4F810E43241B43CE5AB4BFA5FF25CC3047B9E00AFD965D`. The app launched to Expedition and was brought to the foreground. The complete player save matched before and after installation. Native launch capture: `artifacts/nightfall-godot/shrine-cards/android-installed.png`. Cards and all spell families were exercised in dedicated desktop graphics fixtures; this installation check was not a full native combat playthrough.
