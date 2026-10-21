# Animated class showcase characters

The class page uses the approved Nightfall character illustrations with a subtle, looping idle. The artwork stays recognizable while small shape-key deformations add breathing and soft hair or clothing movement. These are lightweight 2.5D class showcases, not the separate gameplay characters.

- Scavenger reuses the existing editable Blender rig at `prototypes/scavenger_idle_blender/scavenger_idle.blend`.
- Warden, Arcanist, and Engineer use editable Blender scenes in `blends/` and crops of the approved source art in `source/`.
- Godot loads the animated `.glb` files in `assets/class-showcase/idle_models/` into a supersampled transparent viewport. Reduced Effects keeps the static illustrations.

Rebuild with `python tools/build_class_showcase_animations.py`. The build exports the existing Scavenger rig instead of replacing it with a newly generated version.
