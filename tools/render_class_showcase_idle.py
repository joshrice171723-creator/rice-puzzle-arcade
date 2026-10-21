"""Blender worker for the animated class-screen illustration rig."""

from __future__ import annotations

import argparse
import math
import os
import sys

import bpy


def arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--class-id", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--blend", required=True)
    return parser.parse_args(argv)


def gaussian(value: float, center: float, radius: float) -> float:
    return math.exp(-0.5 * ((value - center) / radius) ** 2)


def smoothstep(lo: float, hi: float, value: float) -> float:
    t = max(0.0, min(1.0, (value - lo) / (hi - lo)))
    return t * t * (3.0 - 2.0 * t)


def make_character_mesh(image: bpy.types.Image) -> bpy.types.Object:
    image_width, image_height = image.size
    aspect = image_width / max(1, image_height)
    height = 3.22
    width = height * aspect
    columns, rows = 42, 72
    vertices = []
    uvs = []
    for row in range(rows + 1):
        v = row / rows
        for column in range(columns + 1):
            u = column / columns
            vertices.append(((u - 0.5) * width, 0.0, 0.12 + v * height))
            uvs.append((u, v))

    faces = []
    for row in range(rows):
        for column in range(columns):
            a = row * (columns + 1) + column
            b = a + 1
            d = a + columns + 1
            faces.append((a, b, d + 1, d))

    mesh = bpy.data.meshes.new("Painted character deformation mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    for polygon in mesh.polygons:
        polygon.use_smooth = True
        for loop_index in polygon.loop_indices:
            vertex_index = mesh.loops[loop_index].vertex_index
            uv_layer.data[loop_index].uv = uvs[vertex_index]

    character = bpy.data.objects.new("Nightfall class character • 2.5D idle rig", mesh)
    bpy.context.collection.objects.link(character)
    character["asset_role"] = "Animated class showcase art; gameplay actor is separate"
    character["source_art"] = image.filepath
    character["motion"] = "slow breathing, balanced weight shift, soft hair and cloth drift"

    basis = character.shape_key_add(name="Basis", from_mix=False)
    keys = {
        name: character.shape_key_add(name=name, from_mix=False)
        for name in ("Breath", "Weight Shift", "Hair Sway", "Cape Sway", "Coat Hem")
    }
    for row in range(rows + 1):
        v = row / rows
        for column in range(columns + 1):
            u = column / columns
            index = row * (columns + 1) + column
            chest = gaussian(u, 0.5, 0.24) * gaussian(v, 0.66, 0.12) * smoothstep(0.53, 0.61, v) * (1.0 - smoothstep(0.76, 0.83, v))
            waist = smoothstep(0.43, 0.68, v)
            hair = gaussian(v, 0.93, 0.055) * gaussian(u, 0.51, 0.25)
            edge = max(gaussian(u, 0.06, 0.11), gaussian(u, 0.94, 0.11))
            cape = edge * gaussian(v, 0.48, 0.22)
            hem = edge * gaussian(v, 0.24, 0.16)

            breath = keys["Breath"].data[index].co
            breath.x += (u - 0.5) * chest * width * 0.016
            breath.z += chest * height * 0.003

            shift = keys["Weight Shift"].data[index].co
            shift.x += (u - 0.5) * waist * width * 0.011
            shift.z += waist * (v - 0.5) * height * 0.002

            hair_co = keys["Hair Sway"].data[index].co
            hair_co.x += (u - 0.5) * hair * width * 0.018
            hair_co.z += hair * height * 0.002

            cape_co = keys["Cape Sway"].data[index].co
            cape_co.x += (u - 0.5) * cape * width * 0.026
            cape_co.z += cape * (0.5 - v) * height * 0.012

            hem_co = keys["Coat Hem"].data[index].co
            hem_co.x += (-1.0 if u < 0.5 else 1.0) * hem * width * 0.02
            hem_co.z += hem * math.sin(u * math.pi * 3.0) * height * 0.01

    for key in keys.values():
        key.slider_min = -1.0
        key.slider_max = 1.0

    material = bpy.data.materials.new("Nightfall approved painted art")
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.clear()
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    texture.extension = "CLIP"
    principled = tree.nodes.new("ShaderNodeBsdfPrincipled")
    tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    tree.links.new(texture.outputs["Alpha"], principled.inputs["Alpha"])
    emission_color = principled.inputs.get("Emission Color") or principled.inputs.get("Emission")
    if emission_color is not None:
        tree.links.new(texture.outputs["Color"], emission_color)
    emission_strength = principled.inputs.get("Emission Strength")
    if emission_strength is not None:
        emission_strength.default_value = 1.0
    principled.inputs["Metallic"].default_value = 0.0
    principled.inputs["Roughness"].default_value = 1.0
    tree.links.new(principled.outputs["BSDF"], output.inputs["Surface"])
    if hasattr(material, "surface_render_method"):
        material.surface_render_method = "DITHERED"
    elif hasattr(material, "blend_method"):
        material.blend_method = "BLEND"
    image.pack()
    character.data.materials.append(material)
    character.show_in_front = True
    return character


def animate(character: bpy.types.Object) -> None:
    blocks = character.data.shape_keys.key_blocks
    scene = bpy.context.scene
    cycle_frames = 72
    key_values = {
        "Breath": [(1, 0.0), (19, 0.38), (37, 0.62), (55, 0.34), (73, 0.0)],
        "Weight Shift": [(1, 0.0), (19, 0.27), (37, 0.0), (55, -0.22), (73, 0.0)],
        "Hair Sway": [(1, 0.10), (19, 0.42), (37, 0.04), (55, -0.38), (73, 0.10)],
        "Cape Sway": [(1, 0.0), (19, 0.38), (37, -0.08), (55, -0.34), (73, 0.0)],
        "Coat Hem": [(1, 0.0), (19, 0.34), (37, -0.05), (55, -0.30), (73, 0.0)],
    }
    for name, values in key_values.items():
        block = blocks[name]
        for frame, value in values:
            block.value = value
            block.keyframe_insert(data_path="value", frame=frame)
    scene.frame_start = 1
    scene.frame_end = cycle_frames + 1
    scene.render.fps = 24
    scene.timeline_markers.new("Inhale", frame=19)
    scene.timeline_markers.new("Settle", frame=37)
    scene.timeline_markers.new("Cloth drift", frame=55)
    for action in bpy.data.actions:
        for curve in getattr(action, "fcurves", []):
            for point in curve.keyframe_points:
                point.interpolation = "BEZIER"
                point.handle_left_type = "AUTO_CLAMPED"
                point.handle_right_type = "AUTO_CLAMPED"


def build_stage() -> None:
    camera_data = bpy.data.cameras.new("Class showcase camera")
    camera = bpy.data.objects.new("Class showcase camera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (0.0, -7.0, 1.73)
    camera.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 3.52
    bpy.context.scene.camera = camera


def main() -> None:
    args = arguments()
    os.makedirs(os.path.dirname(args.model), exist_ok=True)
    os.makedirs(os.path.dirname(args.blend), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 280
    scene.render.resolution_y = 420
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.render.image_settings.compression = 12
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "Standard"
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 8

    image = bpy.data.images.load(os.path.abspath(args.image), check_existing=True)
    character = make_character_mesh(image)
    animate(character)
    build_stage()
    scene.frame_set(1)
    bpy.context.view_layer.objects.active = character
    bpy.ops.object.select_all(action="DESELECT")
    character.select_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.blend))
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
    print(f"Exported {args.class_id} idle rig to {args.model}.")


if __name__ == "__main__":
    main()
