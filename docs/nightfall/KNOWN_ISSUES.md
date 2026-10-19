# Nightfall deferred bug log

October 18, 2026. Joshua requested that existing bugs be recorded and revisited during the cleanup pass while feature development continues. New-feature checks still run before delivery.

| ID | Issue | Evidence / reproduction | Status |
|---|---|---|---|
| NF-001 | Intermittent missing Pause/Pulse/Dodge lettering on Android | API 30 emulator, host GPU, Godot Compatibility. Appears in both crowd and ordinary survival, sometimes after ads or menu changes. Button shapes and input remain functional. `artifacts/nightfall-godot/survival-start.png` and prior `android-crowd120-moving.png`. Desktop focus-state probe did not reproduce it. Explicit per-frame button redraw did not fix it and was removed. | Deferred. Engine/emulator root cause unconfirmed; no physical-phone reproduction yet. |
| NF-002 | Character can move behind the top HUD near the northern arena boundary | `survival-late.png` shows the character partly obscured by the HUD. Camera clamps to the floor edge; upper world bounds currently permit this position. | Deferred camera/playfield-layout adjustment. |
| NF-003 | Android export helper can wait on a persistent Gradle daemon after export finishes | `[ DONE ] export` appears but the wrapper stays alive until `gradlew --stop`. A command-scoped `GRADLE_OPTS=-Dorg.gradle.daemon=false` export returned normally. | Deferred helper cleanup; use the scoped environment setting for subsequent builds. |
| NF-004 | Mirrored atlas art can be horizontally offset from its ground marker | `combat-native-boss.png` shows the large left-facing actor to the right of the shadow/slam center. Existing atlas mirroring needs review; the boss uses the existing renderer. | Deferred rendering cleanup; collision position and telegraph use the simulation position. |
| NF-005 | Boss result header falls back to the survival countdown after victory | `combat-native-result.png`: practice completes after 12 seconds but header reads 03:48. No boss deadline exists in simulation. | Deferred result-screen copy cleanup. |
| NF-006 | Headless UI test teardown reports 2–4 remaining ObjectDB instances after adding audio | `ui_test.gd` and `haven_ui_test.gd` finish all checks successfully, then Godot emits the shutdown warning. Explicit player stop/stream clearing did not remove it. | Deferred test/audio teardown investigation. No growing runtime leak or physical-device symptom established. |

Native early-ad-dismissal validation, physical-device performance, and longer soak testing are acceptance gaps, not confirmed bugs. The isolated ad diagnostic still counts sample callbacks. The October 18 feature session additionally wired token-bound campaign rescue to the native earned signal, with simulated-callback integration checks and a successful native export. Actual native rescue-video playback remains unverified; production mediation revenue is not established.

The pre-feature survival attempt ended in defeat at 217 seconds (223 kills, level 4). `artifacts/nightfall-godot/survival-defeat.png` is defeat evidence, not proof of a boss clear or balanced campaign difficulty.
