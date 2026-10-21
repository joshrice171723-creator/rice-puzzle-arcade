# Arcanist quality and mobile pipeline research

## What fits this game

Nightfall's live arena uses a custom 2D renderer and a portrait camera, so a high-resolution, full-pose sprite atlas is the least disruptive path for this character. Godot officially supports both individual animation frames and sprite sheets through `AnimatedSprite2D` or `AnimationPlayer`; the current project draws frames through its existing renderer instead of replacing that architecture. A layered `Skeleton2D`/`Polygon2D` rig is also possible, but it requires cleanly separated artwork, correct pivots, mesh topology, and painted bone weights. That is a separate art-production step, not a shortcut from a flattened illustration.

A GDC case study from Hypersect describes a more ambitious alternative: fully modeled 3D characters rendered with a hand-drawn sprite look, skeletal animation, dynamic lighting, clothing, and weapons. The talk describes a custom-engine production pipeline. It proves that the visual blend can be achieved, but it does not make that result a drop-in Godot feature or remove the need for a strong model, rig, materials, animation, and camera direction.

## Mobile constraints that affect the art

- Review and gameplay now use the same 80-pixel actor size, so visual feedback reflects real mobile readability and transparent overdraw. The prior 3x image remains only as a close-up reference; it is not the active review scale.
- The current atlas has a 1254-pixel source width divided into four columns, giving roughly 313 pixels per pose cell. The 80-pixel gameplay draw size downsamples each cell; judge the result at the phone viewport before changing atlas or import settings.
- Godot recommends lossless image import for 2D by default; VRAM compression can introduce visible artifacts, while mipmaps add memory and only help 2D art when the camera zoom makes them useful. Keep the authored PNG as the source and compare Android import settings on the real target device before optimizing.
- Mobile quality must be judged at the actual portrait viewport and gameplay scale. Close-ups can reveal anatomy and edge defects, but they do not predict how readable the silhouette is at 80 pixels.

## Quality pipeline for the next art pass

1. Lock one approved master design: adult proportions, leg length, face, hair silhouette, navy-and-gold outfit, wand grip, and palette. Use this as the identity reference for every pose.
2. Improve the current sprite source before adding effects: clean alpha edges, consistent camera angle and feet anchor, separated hands/wand silhouette, and poses that show anticipation, contact, and follow-through. Generate or revise one pose at a time against the master reference, then assemble a sheet; do not trust a dense multi-frame sheet until the frames have been checked individually.
3. Make directional coverage deliberate. The current renderer mirrors a front-facing pose, which can reverse asymmetric clothing or the wand hand. Create authored left/right and useful diagonal views, or use a rig only after proper layered source art exists.
4. Inspect the character at normal size in the arena for silhouette and combat readability, then on a real Android device for final scaling, texture quality, and frame-time checks. Use a close-up only to diagnose individual drawing defects, not to judge gameplay fit. Record screenshots and the exact asset revision at each gate.
5. Add modular equipment after the base motion reads well. That will require separated equipment artwork or authored outfit variants; the current single-piece atlas cannot swap armor convincingly.

Codex is most useful here as the pipeline coordinator: keep the design constraints and acceptance criteria explicit, use the available image-generation/editing tool to produce reference-led art, import and animate it in the actual project, and compare captured results against those criteria. OpenAI's Codex workflow guidance recommends staged outcomes, scoped build phases, and human review gates; image guidance likewise calls for checking identity, local-edit fidelity, and actual alpha transparency before accepting an asset.

## Sources

- Godot 2D sprite animation: <https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html>
- Godot 2D skeletons: <https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html> (the page currently flags that it may be outdated for Godot 4.7)
- Godot image import and compression: <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>
- Godot GPU optimization: <https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html>
- Godot mobile resolutions and scaling: <https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html>
- GDC Vault, “How We Draw a 3D Sprite World: The Stylized Art of ‘Never's End’”: <https://gdcvault.com/play/1035701/How-We-Draw-a-3D>
- Hypersect's GDC talk slides: <https://blog.hypersect.com/how-we-draw-a-3d-sprite-world-gdc2026/>
- OpenAI Codex iterative workflow guidance: <https://developers.openai.com/cookbook/examples/codex/iterating-development-workflows-with-codex>
- OpenAI image prompting guide: <https://developers.openai.com/api/docs/guides/image-prompting>
