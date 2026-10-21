# Nightfall Gameplay Character Art Plan

**Status:** Recommended direction for the next character-art pass

**Date:** 2026-10-21
**Scope:** One playable character, then a reusable art standard for the roster. This is an art and production plan; it does not implement or replace game assets.

## Decision

Return to Nightfall's original chunky, richly illustrated action-game style for playable characters. Keep the class page's polished character art as identity and palette reference, but do not copy its tall, portrait-like proportions into the combat actor. The gameplay hero should feel like the character art Nightfall started with: compact, expressive, weighty, colorful, and readable among the game's large enemies and effects.

The production target is a **cohesive full-body 2D animation atlas**, with every frame drawn or rendered as one complete character. Do not animate a single portrait by warping it, assemble visible body parts like a paper puppet, or pass an unmodified generic model off as Nightfall art. This choice fits the existing 2D arena renderer and reuses the game's strongest character work.

## What the current project tells us

- `assets/actors.png` is the best quick reference for the original chunky illustrated language: bold silhouettes, substantial gear, warm material highlights, and a hero that belongs beside the chunky enemies.
- `assets/hero-cast/scavenger-casting.png` is the strongest animation benchmark. Its poses are complete character images, so the character remains a unified object as the action changes.
- `assets/actor-rigs/` and `hero_cast.gd` contain useful pose, equipment, and combat-state work, but the current layered deformation can distort limbs and make the actor feel assembled. Treat it as a source of game-state and attachment information, not the visual target.
- The actual arena is a custom 2D draw pipeline in `arena.gd`. Keep its movement, collision, combat, world sorting, and input behavior. Replace only the character-rendering path when the new atlas passes review.
- `assets/class-showcase/` is a separate presentation layer. Its tall character illustrations remain valuable on the Class page, but they are not combat sprites.

The existing [Scavenger character standard](SCAVENGER_CHARACTER_STANDARD.md) contains an older rule that gameplay must preserve the class-page adult silhouette. That rule is superseded for gameplay by this plan. Identity details may carry across, while playable proportions follow the original game actor style.

## Visual target

Use the original Scavenger and enemy art as the quality and proportion anchor, then design the Arcanist as a member of that same game world:

- Chunky, purposeful shapes with a clear head, torso, arms, legs, boots, and weapon. Slight exaggeration is welcome; chibi proportions, tiny legs, oversized hands, and oversized heads are not.
- Hand-painted-looking materials with controlled outlines, large value groups, warm highlights, and a small number of crisp details that survive the gameplay camera.
- A strong silhouette and readable wand pose at the actual combat size. The face, clothing, and crystal should still read when the full character is roughly 80 pixels tall.
- Arcanist identity comes from the purple/navy palette, distinctive hair, practical layered caster clothing, gold details, and crystal wand. Do not reproduce the class portrait's pose or its tall tailored silhouette.
- Match the lighting and contrast of the blackout map. The hero must separate from dark ground, blue spell effects, and enemy crowds without a permanent outline glow.

Avoid smooth mannequin bodies, clay-like shading, school-uniform styling, noisy micro-detail, excessive metallic trim, floating feet, and design details that disappear after downscaling.

## Production sequence

### 1. Lock a compact visual brief

Use the existing actor atlas, cast strip, enemy art, and the mission-one environment to create a one-page reference board. It should show the chosen palette, front/three-quarter/back silhouette, weapon scale, face style, and a native-size gameplay crop. Keep the class-page portrait in a separate reference column labeled “identity only.”

**Gate:** The actor reads as a Nightfall gameplay character next to the existing enemies and props, without needing the class page beside it to explain the style.

### 2. Make one Arcanist key-pose set

Create one consistent full-body source design with idle, walk contact, walk passing, cast anticipation, cast release, dodge, and hit poses. Keep the same body scale, face, hair, costume, lighting, and foot baseline in every pose. Design the hand around the wand grip instead of placing the wand afterward.

Create a single transparent test atlas at four times the target height (about 320 pixels tall for an 80-pixel in-game actor). Keep each frame on the same canvas and align it to one foot pivot. Preserve editable source files and record the source/license for every borrowed asset.

**Gate:** Review the atlas in the real arena, first as still frames. Do not animate or integrate a design that fails on silhouette, proportions, wand grip, or map contrast.

### 3. Produce complete-frame animation

For the first playable pass, create these loops and action clips:

| Clip | Initial frame target | Review focus |
|---|---:|---|
| Idle | 6–8 | Calm breathing and cloth/hair settling without floating feet |
| Walk | 8 | Clear foot plants, weight transfer, and no sliding |
| Turn/start/stop | 3–4 each | Motion eases in and settles instead of snapping |
| Wand cast | 6–8 | Anticipation, readable release, and recovery; hand stays connected to wand |
| Dodge | 5–6 | Compact, fast, directional movement with a grounded landing |
| Hit | 2–3 | Fast readable flinch that does not break body proportions |
| Defeat | 8–10 | Controlled collapse and a clear final pose |

Frame counts are starting targets, not a substitute for visual review. Keep any small continuous effects, such as crystal glow and cast sparks, separate from the body atlas. The hero itself should remain a complete moving figure.

### 4. Integrate through the existing arena

Use the current run state to select the full-body frame and animation timing at the existing `HeroCast.draw_motion` boundary. Preserve `Run` state, movement, WASD/arrow controls, touch controls, attack timings, equipment stats, collision, and world-depth sorting. Keep the existing ground shadow and weapon/effect timing aligned to the new full-frame art.

Start with one fixed combat outfit so the character can pass visual review. Add visible armor variants only after the base character is accepted. Later gear can use authored full-frame outfit variants or a carefully tested accessory overlay; do not reintroduce a deforming paper-doll body to satisfy equipment slots.

Godot supports frame-based 2D animation through `AnimatedSprite2D` and `SpriteFrames`; the current arena has its own draw ordering, so the implementation should use the same frame data at the existing custom-draw boundary instead of replacing the arena architecture. See the [Godot 2D sprite animation guide](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html) and [AnimatedSprite2D reference](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html).

### 5. Test in the actual Nightfall camera

Run mission one and review the actor at native resolution, then at common Android scaling. Capture idle, walk, stop, turn, dodge, hit, and cast while enemies, loot, shrines, and attacks are on screen. Also test WASD and arrow movement so the art change cannot regress controls.

Check the same capture with damage numbers and effects enabled. Confirm that the hero stays visible without overpowering the combat, the feet stay attached to the ground plane, the weapon hand does not drift, and world sorting puts scenery and enemies in front or behind correctly.

## Acceptance bar

The pilot is accepted only when all of these are true in the real game build:

1. At gameplay size it reads immediately as Nightfall's chunky illustrated style, not as class-page portrait art, a generic avatar, or a placeholder.
2. The head, torso, arms, and legs have balanced, intentional proportions. No tiny/short legs, duplicate feet, broken joints, or unstable body scale appear in any frame.
3. Every animation keeps a stable face, outfit, lighting, pivot, and silhouette; there are no visible cut seams, frame-to-frame costume changes, or foot sliding.
4. The wand has a natural grip and its crystal remains readable during idle and cast.
5. The hero separates from the real map and stays recognizable amid the intended enemy density and VFX.
6. The animation does not harm arena sorting, combat state, input, or target mobile performance.

Any visible “clay,” “stitched,” “rag-doll,” or generic-avatar quality is a failed gate. Do not rename it, hide it with glow/shader effects, or expand the roster until it is fixed.

## Risks and honest limits

- The project has high-quality reference illustrations, but a reference image is not automatically a consistent animation source. Full-frame motion requires coherent authored poses and cleanup; changing random generated pictures into a sequence can change the face, outfit, or proportions between frames.
- Previously inspected no-cost 3D candidates did not match the game's style. Do not restart the generic-model/recolor loop. If the existing art plus a carefully controlled sprite workflow cannot pass the gates, stop and report the missing production-art capability instead of calling a weak asset finished.
- No paid asset purchase is part of this plan. Record licenses for any external no-cost material before it enters the game.

## Scope order

1. One Arcanist gameplay actor and its animation atlas.
2. The base Scavenger and equipment variants, reusing the accepted frame pipeline.
3. Remaining classes, then enemy animation cleanup.

Do not build a new roster, replace the class-showcase artwork, or start a new 3D character experiment until the Arcanist passes the in-game acceptance bar.
