# ADR 001: isolated canvas arena inside existing Expo app

Status: provisional for the vertical slice, pending Android measurements. No migration of the existing apps.

October 18 update: Joshua authorized the [Nightfall delivery plan](nightfall/BUILD_PLAN.md), including an isolated Godot evaluation. `apps/nightfall-godot/` now exists alongside the original prototype. Its [verification report](nightfall/ENGINE_PROOF_QA.md) records passing desktop and export checks, with native runtime/ad acceptance blocked by disk space. The original prototype is preserved; the evaluation has not yet established a production renderer decision.

| Option | Rendering / 100+ enemies | Android / ads | Cost and risk |
| --- | --- | --- | --- |
| RN + Skia | GPU canvas; good candidate for larger sprite scenes, fixed-step TS simulation | Extra native dependency plus CanvasKit setup on web; existing RN platform services remain available | Additional native binary/build dependency; performance still needs measurement |
| Separate Godot | Purpose-built 2D renderer, physics and editor | Separate export/signing pipeline and ad/consent bridge; existing RN bridge cannot be reused | Major engine addition requiring owner review; not justified by the first slice |
| Expo DOM + Canvas2D | Immediate canvas drawing, no per-frame React renders or native bridge calls; fixed-step TS simulation | Built-in @expo/dom-webview 58.0.2, packaged offline DOM bundles, AsyncStorage via low-frequency native actions | Smallest isolated experiment; WebView memory and mobile GPU performance must be measured; not assumed equivalent to native Skia |

Choose option C for the prototype: one canvas owns simulation and drawing. React handles menus, results and upgrade choices only. Native shell owns local persistence and app lifecycle. Clamp frame gaps, bounded catch-up, cap enemies/projectiles, reuse dead slots, use spatial bins for projectile queries. Report observed frame time and capped simulation load; no unsupported claim of 60fps on physical devices. Escalate to Skia if measured render/input budget fails; a separate Godot migration requires a new owner decision.

Sources checked: https://docs.expo.dev/guides/dom-components/ ; https://docs.expo.dev/versions/latest/sdk/skia/ . Expo's existing DOM webview removes the need for a new rendering engine and its docs support bundled offline assets. @expo/metro-runtime is the only missing recommended runtime dependency.

Acceptance: Android install and ordinary touch input, pause/background persistence, crash check, measured 100-enemy rendering, deterministic simulation tests, 5-minute run simulation and 15-minute emulator soak. Emulator evidence cannot establish physical-device FPS, battery or thermal behavior. Final measured results will be added to EXPANSION_QA.md.
