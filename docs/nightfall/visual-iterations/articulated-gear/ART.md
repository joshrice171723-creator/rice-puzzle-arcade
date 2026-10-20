# Articulated wearable armor

Original built-in imagegen artwork, 19 October 2026. Production transparent 1254 by 1254 PNG atlases, preserved alpha. No Python image modifications. JSON region metadata selects independent cape, torso, empty-face helmet, upper arm, forearm with glove, thigh, shin and boot.

Sources under `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/`: Outrider `exec-38b0f934-11ce-4144-be7e-52a9604aaa05.png`; corrected empty hood `exec-010151e6-ca4f-41b5-9a26-2a115ce1411c.png`; Ironwatch `exec-6a588c3d-80bd-422c-bc26-b0a032bfaa6c.png`; Riftweaver `exec-5206aa21-8271-4928-8a13-b251e83cbd76.png`.

Saved production atlases: `apps/nightfall-godot/assets/actor-parts/gear/outrider-open.png`, `ironwatch.png`, `riftweaver.png`. The first Outrider is preserved as `outrider.png` but unused because its face opening was opaque. A targeted built-in edit removed only the face-hole fill; no head, skin or face is present in any production helmet. Verified alpha0 within all three face openings and alpha0..255 in every atlas.

Manifests: `apps/nightfall-godot/assets/actor-rigs/gear_outrider.json`, `gear_ironwatch.json`, `gear_riftweaver.json`. Region/pivot/end values are in those machine-readable manifests. Upper-arm regions begin below shoulder armor because the torso owns the fixed shoulder plate. This prevents duplicate floating shoulder pads. Forearms include gloves, matching the existing hero schema. Pants/shin perpendicular width is widened 1.35 for the game's compact sturdy proportions.

Full rig composition and actual equipped render review are performed by the renderer integration agent; source generation/import alone is not whole-app acceptance.
