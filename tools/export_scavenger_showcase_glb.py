"""Export the existing approved Scavenger Blender showcase rig for Godot."""

from __future__ import annotations

import argparse
import os
import sys

import bpy


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", required=True)
    args = parser.parse_args(argv)

    character = bpy.data.objects.get("Scavenger • 2.5D showcase rig")
    if character is None or character.type != "MESH" or character.data.shape_keys is None:
        raise RuntimeError("The existing Scavenger Blender showcase rig could not be found.")

    for material in character.data.materials:
        if material is None or not material.use_nodes:
            raise RuntimeError("The Scavenger artwork material has no editable image nodes.")
        source_image = next((node.image for node in material.node_tree.nodes if node.type == "TEX_IMAGE" and node.image), None)
        if source_image is None:
            raise RuntimeError("The Scavenger artwork texture is missing.")
        material.node_tree.nodes.clear()
        output = material.node_tree.nodes.new("ShaderNodeOutputMaterial")
        image_texture = material.node_tree.nodes.new("ShaderNodeTexImage")
        image_texture.image = source_image
        image_texture.interpolation = "Linear"
        image_texture.extension = "CLIP"
        surface = material.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
        material.node_tree.links.new(image_texture.outputs["Color"], surface.inputs["Base Color"])
        material.node_tree.links.new(image_texture.outputs["Alpha"], surface.inputs["Alpha"])
        emission = surface.inputs.get("Emission Color") or surface.inputs.get("Emission")
        if emission is not None:
            material.node_tree.links.new(image_texture.outputs["Color"], emission)
        strength = surface.inputs.get("Emission Strength")
        if strength is not None:
            strength.default_value = 1.0
        material.node_tree.links.new(surface.outputs["BSDF"], output.inputs["Surface"])
        if hasattr(material, "surface_render_method"):
            material.surface_render_method = "DITHERED"
        elif hasattr(material, "blend_method"):
            material.blend_method = "BLEND"

    os.makedirs(os.path.dirname(args.model), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    character.select_set(True)
    bpy.context.view_layer.objects.active = character
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(args.model),
        export_format="GLB",
        export_image_format="AUTO",
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_frame_range=True,
        export_frame_step=1,
        export_force_sampling=True,
        export_morph=True,
        export_morph_animation=True,
        export_cameras=False,
        export_lights=False,
        use_selection=True,
        export_extras=True,
    )
    print(f"Exported the existing Scavenger showcase rig to {args.model}.")


if __name__ == "__main__":
    main()
