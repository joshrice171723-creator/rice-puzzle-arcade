# Continuous combat VFX — October 19, 2026

Historical record of the earlier effects-only pass. The subsequent live-combat changes, four-class coverage and current acceptance evidence are recorded in [Combat mechanics and presentation](COMBAT_MECHANICS_AND_PRESENTATION.md). The APK and performance values below identify that earlier build.

The generated Ember animation sheets were rejected because switching between inconsistent pictures read as a slideshow. The runtime now uses continuously deformed geometry and a procedural shader. No generated animation frames drive Ember Bolt, Frost Nova, spectral blades, wisps, stone lances, gravity, or ground magic.

## Rendering

`ember.gdshader` provides the shared material. Ordinary arena UVs pass through with their original color, texture and alpha. Procedural geometry uses reserved UV bands above 64 to identify its material; vertex color carries animation parameters. This allows the existing ordered arena draw stream to retain projectile/actor/altar depth order without a separate overlay viewport. Rendered pixel comparisons verify that ordinary textured and alpha-colored geometry is unchanged.

- Ember: a persistent deformed core, rolling surface channels, attached tapered ribbon meshes, moving sparks, continuously separating impact lobes and drifting smoke. All animation parameters come from the simulation clock and transient hit event age, never shader wall-clock TIME.
- Frost: an expanding frost front inside the actual radius, staggered faceted crystal growth, branching frost, breaking shards and material striations. Full-area contact illumination is immediate; visual growth does not delay damage.
- Blades: continuous rotation of a recognizable blade, guard, grip and pommel, with short curved magical trails. No alternating weapon pictures.
- Chain lightning: continuously moving irregular branches with a soft outer glow, white core and contact flash.
- Stone lance: pointed stone meshes along the instantaneous hit line, with tumbling fragments and mineral detail. Existing mechanics hit the line immediately; this remains a simultaneous impalement/eruption rather than falsely delaying damage behind a traveling spear.
- Wisps: continuously shaded magical bodies, attached flowing tails, actual orbital positions and contact pulses tied to recorded hit times.
- Ground magic: animated rune material with the original radius boundary.
- Gravity: inward flowing spirals and ribbons within the actual pull area. This distorts the effect itself, not the entire screen or enemy collision positions.

Transient meshes are retained until the next draw, then released. Effect storage remains bounded. Reduced Effects decreases secondary geometry, smoke and trails while retaining the core movement/contact information.

## Character motion

`hero_cast.gd` now builds a textured 2D mesh from one consistent pose for each currently rendered character (scavenger and engineer). Weighted deformation articulates the legs, shoulder/weapon, torso and coat. Stride follows actual distance traveled; start/stop blends smoothly; cast anticipation/release/recovery and dodge lean use simulation state. The old four-picture casting sequence is no longer used.

This is a 2D mesh rig, not a fully modeled 3D skeleton. It supports the existing left/right presentation; new directional silhouettes would require additional coherent source art or a 3D model. The shader volumes are procedural 2D geometry with dimensional shading, not a fluid simulation.

## Gameplay and evidence

Damage, cooldowns, collision, range, rewards, permanent experience and manual controls are unchanged. The only run-state additions are bounded, unsaved presentation events. Preview runs use a separate profile path and no campaign attempt. Tests cover actual impact damage/timing, unchanged RNG, pause/resume, cleanup, consecutive geometry motion, shader pixel changes at consecutive frames, shader freeze, and ordinary-material passthrough.

Verification artifacts are in `artifacts/nightfall-godot/continuous-vfx/` (ignored by Git). `continuous-gameplay.mp4` is an offline 60 FPS desktop capture, not a claim of live mobile performance. The preview uses stationary targets, actual attack logic, and eight simultaneous spell families—more than a normal loadout—to exercise overlap. The character moves through the normal movement input and performs one dodge. Stage 3 uses the engineer with Reduced Effects. Native measurements and final build identity are recorded below after installation.

## Visual acceptance

The user approved the continuous Ember direction and requested the same treatment for the remaining abilities and movement. The full extended pass still needs their visual judgment. The saved generated concept images remain targets; passing tests or measuring frame rate does not establish exact visual parity.

## Installed build and checks

- 32 regression suites: 7,682 checks, zero failures. A separate graphics test passes 13 checks, including material flow beyond one second on fixed geometry, exact pause freeze, unchanged ordinary pixels and clean effect removal.
- Eight ability families plus pistol render in normal/reduced and contact/late fixtures without runtime errors. Native log contains only the shader-cache recompilation warning, not a shader compilation failure.
- Desktop render fixture: 32 draw calls for 120 actors/40 pickups; 87 for Mission One's authored actors/pickups/12 hit labels. These are draw-call checks, not Android FPS claims.
- APK SHA-256: `FA17430B8C918F2678FD6800956F1F7A17C58384B7D0E4A6642D033C91888D71`.
- Installed on `emulator-5554`, Arcade_QA_API30 / Android 11, Godot 4.7.2 Compatibility, OpenGL ES 3 translator on Intel Iris Xe. Existing profile compared equal after the run. The disposable preview flag was removed and the ordinary game reopened.
- Native recording: `artifacts/nightfall-godot/continuous-vfx/nightfall-continuous-android.mp4`, recorded at normal simulation speed. The original includes startup; the presentation clip trims startup only. Frame sequences were inspected for visible effects, character alignment, pause and reduced mode.

| Native test, screen recording disabled | Mean frame time | P95 frame time | Mean FPS | P95 draw calls |
| --- | ---: | ---: | ---: | ---: |
| Ember only | 22.50 ms | 26.67 ms | 44.4 | 89 |
| Eight abilities, moving hero and dodge | 28.58 ms | 36.82 ms | 35.0 | 108 |
| Reduced Effects, engineer moving | 26.10 ms | 33.33 ms | 38.3 | 102 |

With Android screen recording enabled, these stages averaged 25.4 / 21.9 / 27.5 FPS. Capture overhead is substantial. Physical-phone performance remains unmeasured, and the 60 FPS target is not met on this emulator. Do not label this a completed mobile performance pass.
