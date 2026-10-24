# Nightfall Scavenger 2D Puppet Plan

**Decision:** Build the Scavenger as a painted 2D cutout puppet for the real
Godot game. Blender and 3D model exports are out of this character pipeline.

## Approved visual target

- `docs/nightfall/art-concepts/nightfall-b-beaconbound.png` sets the Nightfall
  mood, base, combat framing, and overall palette.
- `assets/hero-cast/equipment-bodies.png` sets the approved Scavenger body,
  outfit, facial style, and chunky illustrated proportions.
- `assets/hero-cast/scavenger-casting.png` is an animation-pose reference.
- The rejected Scavenger Class cover and its derived experiments are excluded.

Keep the recognizable blue coat, white scarf, bronze armor, dark spiky hair,
goggles, belt lantern, and firearm. Match the approved body's compact adult
proportions and readable silhouette. Do not use the discarded long-coat Class
portrait, Blender candidates, or the old mixed-style parts atlas as reference.

## Fit the existing game

The arena is a custom 2D draw pipeline. `Run` already owns movement, combat,
input, and collisions; `arena.gd` calls `HeroCast.draw_motion()` to render the
player. Keep that ownership. Do not create a second `CharacterBody2D` that can
drift from the real player state.

The current Scavenger renderer is already a 2D jointed puppet, but it uses the
legacy `assets/actor-rigs/scavenger.png` parts sheet and mesh-deformation path.
The Class page now displays the approved body atlas, and the old Scavenger
cover/model are being removed from active references. Replace the legacy
gameplay art only after new parts pass the acceptance gates below.

## Asset and rig pipeline

1. Extract individual transparent parts from the approved Scavenger artwork:
   torso/coat, head and hair, scarf, upper and lower arms, hands, thighs,
   shins/boots, coat tails, lantern, and firearm. Keep source art and masks
   editable. Extend hidden pixels under shoulders, elbows, hips, and knees so
   ordinary rotation cannot reveal gaps.
2. Place pivots at anatomical joints. Use a 2D bone hierarchy for pelvis,
   spine, neck/head, shoulders/elbows/wrists, and hips/knees/ankles. Parent
   rigid sprite pieces to their controlling bones; use weighted polygons only
   where a cloth piece needs gentle bending.
3. Keep the current arena's sorting: pass bone transforms and draw each
   separated piece in `HeroCast.draw_motion()` order so scenery and enemies
   can still appear in front of or behind the hero. The standalone puppet
   preview may use Godot `Skeleton2D`, `Bone2D`, `Sprite2D`, and `AnimationPlayer`;
   it must share the same art and joint positions as the arena renderer.
4. Drive gameplay poses from existing run state: breathing idle, planted-foot
   walk, start/stop, turns, automatic weapon attacks, manual dodge, hit recoil,
   and defeat. Keep the pistol grip, lantern anchor, and weapon flash attached
   to the correct joints.
5. Apply visible equipment through compatible overlays after the base puppet
   passes. Preserve existing combat values, pickup range, controls, collision,
   and mobile performance.

The pasted setup sketch suggested `RemoteTransform2D` links between bones and
sprites. Directly parenting rigid sprites to their `Bone2D` is simpler and
avoids remote-path bookkeeping. The arena should continue to use its existing
player state rather than gaining a parallel movement controller.

## Review gates

- Inspect each source part on its own and in the assembled neutral pose before
  adding animation. Verify edge masks, overlap, pivots, and draw order.
- Check the full figure at normal gameplay size against the approved art and
  Nightfall map; reject visible gaps, doubled anatomy, short legs, stretched
  parts, floating props, or class-portrait styling.
- Test idle, all movement directions, turn, stop, automatic attack, dodge, hit,
  and defeat through the actual arena camera. Check the gun grip and lantern.
- Compare before/after captures with the same camera, zoom, and scale. Run the
  existing Scavenger and combat tests before replacing the current actor.

Do not call the new puppet ready because a standalone preview looks good. It
must pass the real arena review without breaking movement, combat, depth sort,
or mobile frame time.
