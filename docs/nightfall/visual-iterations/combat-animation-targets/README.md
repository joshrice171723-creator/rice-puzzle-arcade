# Combat animation visual targets — October 19, 2026

User clarification: attacks need actual animation, not little dots, laser-like strokes, or ability icons moving around. The intended term is **animated combat VFX**, accompanied by character casting and hit reactions. The user requested images of how these attacks would look inside gameplay before further implementation.

These are generated concept images, not captures of the running game and not implemented animation frames. No gameplay code was changed during this visual exploration. Prompts use the user's supplied screenshot as a composition/scale reference. Generated with the built-in image-generation tool; final images are saved beside this document. Original source game assets have not been extracted or shipped as assets.

## Images

- `frost-and-ember.png`: same arena and camera showing Frost Nova at its brief peak, and an illustrative Ember Orbit concept. Orbit is a visual exploration, not an approved change to the existing Ember projectile mechanic. Keep the hero readable; large ice coverage must be brief.
- `ember-animation-stages.png`: Ember Bolt cast, travel, impact, and dissipation with different hero poses and localized light. This is a storyboard, not a ready-to-play sprite sheet. Production art needs aligned animation frames or animated meshes/particles.

## Implementation target

Give each attack a readable silhouette, cast anticipation, travel or expansion, contact response, and short dissipation. Fire has a solid bright core with asymmetric rolling flame, ice has distinct crystalline blades/shards, and physical stone lances travel as pointed objects instead of stretching into beams. Effects should follow actual positions, hit timing, and areas. Character animation needs cast/recoil motion as well as walking. Preserve accurate danger telegraphs and do not let bright effects hide enemies or the player.

The altar reference calls for steps, corner pillars, a floating crystal, and a charging ring grounded around its base. The hero, enemy, chest, altar, and floor tiles must share one coherent camera scale. In the generated concepts the altar is a landmark several times the chest height; it is not just an enlarged inventory icon.

## Generation prompts

Exact generation prompts are preserved in `PROMPTS.md`.
