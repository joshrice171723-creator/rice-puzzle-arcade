import argparse
import math
import os
import sys

import bpy
from mathutils import Vector


def cli_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--character", required=True)
    parser.add_argument("--hall", required=True)
    parser.add_argument("--render", action="store_true")
    return parser.parse_args(argv)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for data in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for item in list(data):
            if item.users == 0:
                data.remove(item)


def image_material(name, image, alpha=False):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.clear()
    output = tree.nodes.new("ShaderNodeOutputMaterial")
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    texture.extension = "CLIP"
    emission = tree.nodes.new("ShaderNodeEmission")
    emission.inputs["Strength"].default_value = 1.0
    tree.links.new(texture.outputs["Color"], emission.inputs["Color"])
    if alpha:
        transparent = tree.nodes.new("ShaderNodeBsdfTransparent")
        mix = tree.nodes.new("ShaderNodeMixShader")
        tree.links.new(texture.outputs["Alpha"], mix.inputs[0])
        tree.links.new(transparent.outputs[0], mix.inputs[1])
        tree.links.new(emission.outputs[0], mix.inputs[2])
        tree.links.new(mix.outputs[0], output.inputs["Surface"])
        if hasattr(material, "surface_render_method"):
            material.surface_render_method = "DITHERED"
        elif hasattr(material, "blend_method"):
            material.blend_method = "BLEND"
    else:
        tree.links.new(emission.outputs[0], output.inputs["Surface"])
    return material


def make_image_plane(name, image, width, height, y, z_bottom, material, x_segments=1, z_segments=1):
    vertices = []
    uvs = []
    for row in range(z_segments + 1):
        v = row / z_segments
        for col in range(x_segments + 1):
            u = col / x_segments
            vertices.append(((u - 0.5) * width, y, z_bottom + v * height))
            uvs.append((u, v))
    faces = []
    for row in range(z_segments):
        for col in range(x_segments):
            a = row * (x_segments + 1) + col
            b = a + 1
            d = a + x_segments + 1
            c = d + 1
            faces.append((a, b, c, d))
    mesh = bpy.data.meshes.new(name + " Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            vertex_index = mesh.loops[loop_index].vertex_index
            uv_layer.data[loop_index].uv = uvs[vertex_index]
        polygon.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    image.pack()
    return obj


def gauss(value, center, radius):
    return math.exp(-0.5 * ((value - center) / radius) ** 2)


def smoothstep(lo, hi, value):
    t = max(0.0, min(1.0, (value - lo) / (hi - lo)))
    return t * t * (3.0 - 2.0 * t)


def add_shape_keys(character, width, height, columns, rows):
    character.shape_key_add(name="Basis", from_mix=False)
    keys = {}
    for name in ("Breath • Ribcage", "Weight Shift • Spine", "Hair • Soft Sway", "Scarf • Drift", "Coat • Hem Sway"):
        keys[name] = character.shape_key_add(name=name, from_mix=False)

    for row in range(rows + 1):
        v = row / rows
        for col in range(columns + 1):
            u = col / columns
            index = row * (columns + 1) + col
            base = character.data.shape_keys.reference_key.data[index].co
            x, y, z = base
            # Subtle deformation keeps the supplied painted silhouette readable.
            chest = gauss(u, 0.50, 0.23) * gauss(v, 0.68, 0.13) * smoothstep(0.54, 0.62, v) * (1.0 - smoothstep(0.77, 0.84, v))
            keys["Breath • Ribcage"].data[index].co.x += (u - 0.5) * chest * width * 0.018
            keys["Breath • Ribcage"].data[index].co.z += chest * height * 0.0025

            upper = smoothstep(0.48, 0.68, v)
            spine = keys["Weight Shift • Spine"].data[index].co
            spine.x += upper * width * 0.010
            spine.z += upper * (v - 0.5) * height * 0.003

            hair = gauss(v, 0.94, 0.06) * gauss(u, 0.53, 0.24)
            keys["Hair • Soft Sway"].data[index].co.x += (u - 0.46) * hair * width * 0.014
            keys["Hair • Soft Sway"].data[index].co.z += hair * height * 0.003

            scarf = gauss(v, 0.70, 0.12) * smoothstep(0.66, 0.78, u) * (1.0 - smoothstep(0.98, 1.0, u))
            keys["Scarf • Drift"].data[index].co.x += scarf * width * 0.018
            keys["Scarf • Drift"].data[index].co.z += scarf * (u - 0.66) * height * 0.022

            edge = max(gauss(u, 0.12, 0.12), gauss(u, 0.88, 0.12))
            hem = edge * gauss(v, 0.39, 0.18)
            direction = -1.0 if u < 0.5 else 1.0
            keys["Coat • Hem Sway"].data[index].co.x += direction * hem * width * 0.012
            keys["Coat • Hem Sway"].data[index].co.z += hem * math.sin(u * math.pi * 4.0) * height * 0.006

    for key in keys.values():
        key.slider_min = -1.0
        key.slider_max = 1.0
    return keys


def animate_keys(keys, scene):
    # A six-second, three-breath loop. The same pose lands at both ends.
    frames = [1, 25, 49, 73, 97, 121, 145]
    breath_values = [0.0, 0.62, 0.0, 0.58, 0.0, 0.64, 0.0]
    for frame, value in zip(frames, breath_values):
        keys["Breath • Ribcage"].value = value
        keys["Breath • Ribcage"].keyframe_insert(data_path="value", frame=frame)

    for frame, value in zip([1, 37, 73, 109, 145], [0.0, 0.55, 0.0, -0.42, 0.0]):
        keys["Weight Shift • Spine"].value = value
        keys["Weight Shift • Spine"].keyframe_insert(data_path="value", frame=frame)

    for frame, value in zip([1, 37, 73, 109, 145], [0.1, 0.52, 0.0, -0.44, 0.1]):
        keys["Hair • Soft Sway"].value = value
        keys["Hair • Soft Sway"].keyframe_insert(data_path="value", frame=frame)

    for frame, value in zip([1, 37, 73, 109, 145], [0.0, 0.55, 0.0, -0.52, 0.0]):
        keys["Scarf • Drift"].value = value
        keys["Scarf • Drift"].keyframe_insert(data_path="value", frame=frame)
        keys["Coat • Hem Sway"].value = value * 0.60
        keys["Coat • Hem Sway"].keyframe_insert(data_path="value", frame=frame)

    # Blender 5 uses layered actions; inserted shape-key keys default to smooth Bezier.
    scene.frame_start = 1
    scene.frame_end = 145
    scene.render.fps = 24
    for label, frame in (("Inhale", 25), ("Settle", 49), ("Weight shift", 73), ("Loop", 145)):
        scene.timeline_markers.new(label, frame=frame)


def setup_camera(scene):
    bpy.ops.object.camera_add(location=(0.0, -8.0, 2.25))
    camera = bpy.context.object
    camera.name = "Showcase Camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.60
    camera.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    camera.data.lens = 50
    scene.camera = camera
    return camera


def prepare_ui(character):
    bpy.context.view_layer.objects.active = character
    bpy.ops.object.select_all(action="DESELECT")
    character.select_set(True)
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.region_3d.view_perspective = "CAMERA"
                area.spaces.active.shading.type = "MATERIAL"


def main():
    args = cli_args()
    output = os.path.abspath(args.output)
    os.makedirs(output, exist_ok=True)
    clear_scene()

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.015, 0.025, 0.07)
    scene.view_settings.view_transform = "Standard"
    scene.render.image_settings.color_mode = "RGBA"

    character_image = bpy.data.images.load(os.path.abspath(args.character), check_existing=True)
    hall_image = bpy.data.images.load(os.path.abspath(args.hall), check_existing=True)
    character_material = image_material("Scavenger • painted artwork", character_image, alpha=True)
    hall_material = image_material("Class Hall • original background", hall_image, alpha=False)

    # Cropped portrait frame over the same class-hall art used in the UI.
    make_image_plane("Class Hall Background", hall_image, 4.5, 4.5, 0.45, 0.0, hall_material)
    width = 2.78 * character_image.size[0] / character_image.size[1]
    height = 2.78
    columns, rows = 40, 70
    character = make_image_plane(
        "Scavenger • 2.5D showcase rig", character_image,
        width, height, -0.04, 0.90, character_material, columns, rows
    )
    character.show_in_front = True
    character["asset_role"] = "Class showcase idle art; not the gameplay mesh"
    character["motion_notes"] = "Breathing, spine weight shift, subtle hair/scarf/coat hem drift"
    keys = add_shape_keys(character, width, height, columns, rows)
    animate_keys(keys, scene)
    setup_camera(scene)
    scene.frame_set(1)

    scene.render.filepath = os.path.join(output, "scavenger_idle_still.png")
    scene.render.image_settings.file_format = "PNG"
    scene.render.resolution_percentage = 100
    prepare_ui(character)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(output, "scavenger_idle.blend"))

    if args.render:
        bpy.context.scene.frame_set(1)
        bpy.ops.render.render(write_still=True)
        frames_dir = os.path.join(output, "preview_frames_12fps")
        os.makedirs(frames_dir, exist_ok=True)
        scene.render.filepath = os.path.join(frames_dir, "scavenger_")
        scene.render.image_settings.file_format = "PNG"
        scene.render.resolution_percentage = 65
        # Half-rate render keeps preview time practical; ffmpeg interpolates the subtle idle motion.
        for output_index, frame in enumerate(range(1, 74, 2), start=1):
            scene.frame_set(frame)
            scene.render.filepath = os.path.join(frames_dir, f"scavenger_{output_index:04d}.png")
            bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
