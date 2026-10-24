# Nightfall Scavenger — Blender Character Study

This is a separate rigged 3D character study for Scavenger. It is **not integrated as a playable actor**: the current Nightfall arena is a 2D `Node2D` scene, and its hero is drawn by the 2D `hero_cast.gd` path. The GLB has not been tested in the live game camera.

## Files

- `Nightfall_Scavenger_Polished.blend` — editable Blender source with packed base textures, a 65-bone humanoid rig, materials, studio lights, and review cameras.
- `Nightfall_Scavenger_Polished.glb` — exported glTF 2.0 binary with embedded textures and skinning.
- `Scavenger_ThreeQuarter.png`, `Scavenger_Front.png`, `Scavenger_Side.png`, `Scavenger_Back.png` — current Blender renders used for silhouette review.
- `Scavenger_FourView_ContactSheet.png` — labeled four-angle review sheet.
- `tools/build_nightfall_scavenger_polished.py` — reproducible builder.

## Design and provenance

The design references are `apps/nightfall-godot/assets/class-showcase/scavenger.png` and `apps/nightfall-godot/prototypes/scavenger_blender/modular_rebuild/source/scavenger-parts-reference.png`. The parts sheet informed colors and gear only; it was not mapped onto the character.

The editable body, head, face texture, hair, and 65-bone rig are adapted from **Young Warrior (Rigged Stylized Humanoid Character Base)** by Girush, licensed CC0. The source license is included at `apps/nightfall-godot/prototypes/arcanist_cc0/source/readme.txt`. The build changes its rest pose and hand proportions, adds weighted coat/pants/gloves, and authors the scarf, asymmetrical shoulder plates, boots, harness, belt gear, goggles, pistol, lantern, and back detailing. It is a modified licensed base, not a ground-up original sculpt. No third-party model beyond that CC0 source was added.

## Validation

Built with Blender 5.2.2. The builder rendered all four views, saved the editable `.blend`, and exported the `.glb`. The GLB was re-imported into Blender: **1 armature, 65 bones, 90 mesh objects, 8 skinned meshes, 25 materials, and 55,998 triangles after export modifiers**. The source materials and textures are packed in the Blender file; the GLB embeds its texture data.

Rebuild from the repository root:

```powershell
& .\tools\blender-portable\blender-5.2.2-windows-x64\blender.exe --background --python .\tools\build_nightfall_scavenger_polished.py
```

## Still needed before production use

- The head, face, and hair still read as the licensed source character; they need a bespoke Scavenger sculpt and paint pass to match the approved art more closely.
- The outfit now has a readable silhouette and gear placement, but the coat and glove surfaces remain simple, the holstered pistol is not hand-held, and the back/side views need more authored tailoring detail.
- This asset has no authored idle, walk, turn, or combat animation. Its rig and prop placement have not been tested in Godot.
- The GLB's 55,998-triangle count, 90 mesh objects, and 25 materials need an LOD/merge/material-atlas pass before broad mobile use.
- No gameplay integration, mobile performance test, or runtime animation test was done; the arena currently uses 2D rendering.
