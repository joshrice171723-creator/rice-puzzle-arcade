# Scavenger Character Standard

## Approved direction

The approved references are the [Beaconbound concept board](../../../docs/nightfall/art-concepts/nightfall-b-beaconbound.png)
and the [gameplay character sheet](../assets/hero-cast/equipment-bodies.png). The board sets the
Nightfall mood, environment, and combat framing; the gameplay sheet sets the
Scavenger's silhouette, proportions, outfit, palette, and rendering style.

The Scavenger is the chunky illustrated adventurer shown there: dark spiky
hair and goggles, white scarf, cobalt coat, bronze shoulder armor, heavy boots,
lantern, and a readable firearm. Preserve this identity while matching the
approved gameplay sheet's compact proportions and grounded pose.

## Runtime source

The game is a 2D arena. The Class page now uses the approved gameplay atlas;
the live arena still uses a legacy custom 2D part rig sourced from
`assets/actor-rigs/scavenger.png`. That rig is an implementation to replace,
not a visual reference. The new puppet must use approved artwork and preserve
the arena's current movement, combat, collision, and draw-order systems.
Class-page art and Blender studies are not character sources. Rejected covers
and experiments are archived under `prototypes/archive/rejected-scavenger-studies/`.

`assets/actors.png` and `assets/hero-cast/scavenger-casting.png` remain useful
action-pose references. Equipment variants should preserve the approved body
shape rather than stretching or replacing the full character with mismatched
parts.
