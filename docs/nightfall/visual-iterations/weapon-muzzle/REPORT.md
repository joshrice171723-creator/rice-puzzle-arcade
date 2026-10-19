# Weapon muzzle launch alignment

`HeroCast.weapon_attachment()` now owns the shared deformed hand, body mirroring, forearm support, recoil and weapon mount transform. The held weapon renderer uses that helper; `HeroCast.muzzle_offset()` projects its actual authored weapon tip.

`Weapons.fire()` adds presentation-only `visual_launch` metadata to each shot: birth origin, central aim direction, class, facing, clock and expected contact distance. All previous gameplay values, including damage and the talent multiplier, remain unchanged. Scattergun pellets share one central muzzle while retaining their original spread velocities.

`CombatEffects.shot_visual_position()` begins the visible projectile at that weapon tip, then smoothly removes the launch correction over at most 80 world units. It converges to the existing collision path lifted to torso height. For a nearby target, convergence shortens to that target's existing collision boundary (17 units, or 32 for a boss). No visual teleport, beam stretch, damage, velocity, lifetime, range, projectile count or collision-origin change is introduced. Legacy projectiles without metadata retain their previous rendering. Sabre and spell projectiles remain outside this change.

Release projection uses the class's neutral release stance with its shared authored hand/weapon geometry. Walking cloth/body motion can move the displayed hand slightly around that release stance; this is a small animation detail rather than another feet-origin launch. No new simulation dependency on render frame timing was introduced.

## Verification

- `tests/weapon_muzzle_test.gd`: **5,458 checks, 0 failures**. Covers all four classes, four weapons, four cardinal aim directions, exact shared tip projection, continuous convergence, render immutability and close/overlapping target collisions compared with identical runs stripped of presentation metadata.
- Existing combat mechanics: **290 checks, 0 failures**.
- Existing equipped weapon geometry: **152 checks, 0 failures**.
- Actual Godot OpenGL compatibility render: `WEAPON_MUZZLE_RENDER_OK`. `muzzle-launch.png` and `muzzle-flight.png` show the four weapon families aiming right, left, up and down at release and after 65 milliseconds. Images were inspected. They are controlled render fixtures, not active gameplay screenshots.
- Focused diff check passed.

Only `hero_cast.gd`, `combat_effects.gd`, the approved presentation metadata lines in `weapons.gd`, focused tests and evidence were changed. No arena, run, projectile collision or Git changes were made by this task.
