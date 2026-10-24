import bpy
import os
import sys
from mathutils import Matrix, Vector


args = sys.argv[sys.argv.index("--") + 1:]
source_blend, output_dir = args
os.makedirs(output_dir, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=source_blend)

rig = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")


def point_bone_down(name, direction):
    bpy.context.view_layer.update()
    bone = rig.pose.bones[name]
    head = bone.head.copy()
    rotation = Vector(direction).normalized().to_track_quat("Y", "Z")
    mat = rotation.to_matrix().to_4x4()
    mat.translation = head
    bone.matrix = mat
    bpy.context.view_layer.update()


# Relax the source T-pose into a compact, readable idle; keep the pistol hand forward.
for name, direction in [
    ("upperarm.l", (0.22, 0.0, -0.975)),
    ("upperarm.r", (-0.32, 0.0, -0.948)),
    ("lowerarm.l", (0.12, -0.06, -0.99)),
    ("lowerarm.r", (-0.12, -0.30, -0.946)),
    ("wrist.l", (0.0, -0.18, -0.984)),
    ("wrist.r", (0.0, -0.65, -0.76)),
    ("hand.l", (0.0, -0.28, -0.96)),
    ("hand.r", (0.0, -1.0, 0.0)),
]:
    if name in rig.pose.bones:
        point_bone_down(name, direction)

bpy.context.view_layer.update()

# The source pauldron curves made shoulder-sized hoops when the T-pose was relaxed.
for obj in list(bpy.context.scene.objects):
    if "pauldron" in obj.name.lower():
        bpy.data.objects.remove(obj, do_unlink=True)

bronze = bpy.data.materials["Nightfall - shoulder bronze"]
shoulder = rig.pose.bones["upperarm.l"].head.copy()
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1, location=shoulder + Vector((0, -.035, -.015)))
pauldron = bpy.context.object
pauldron.name = "Nightfall single bronze shoulder plate"
pauldron.data.name = "Nightfall single bronze shoulder plate mesh"
pauldron.scale = (.15, .11, .095)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
pauldron.data.materials.append(bronze)
world = pauldron.matrix_world.copy()
pauldron.parent = rig
pauldron.parent_type = "BONE"
pauldron.parent_bone = "upperarm.l"
pauldron.matrix_parent_inverse = (rig.matrix_world @ rig.pose.bones["upperarm.l"].matrix).inverted()
pauldron.matrix_world = world

# Lower the custom swept locks so they read as messy hair rather than horns.
for obj in bpy.context.scene.objects:
    if obj.type == "MESH" and obj.name.startswith("Hair -"):
        for vert in obj.data.vertices:
            vert.co.x *= .82
            vert.co.y *= .82
            vert.co.z = 1.35 + (vert.co.z - 1.35) * .76

# Slightly reduce the oversized head without changing its facial features.
for obj in bpy.context.scene.objects:
    if obj.type == "MESH" and obj.name == "Rogue_Head":
        pivot = Vector((0, 0, 1.31))
        for vert in obj.data.vertices:
            vert.co = pivot + (vert.co - pivot) * .92
    if obj.type == "MESH" and obj.name.startswith("Hair -"):
        pivot = Vector((0, 0, 1.35))
        for vert in obj.data.vertices:
            vert.co = pivot + (vert.co - pivot) * .92

for mat in bpy.data.materials:
    name = mat.name.lower()
    if "ink-black hair" in name or "hair shadow" in name:
        mat.diffuse_color = (.012, .006, .015, 1)
        bsdf = mat.node_tree.nodes.get("Principled BSDF") if mat.use_nodes else None
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (.012, .006, .015, 1)
    elif "hair sheen" in name:
        mat.diffuse_color = (.035, .014, .025, 1)
        bsdf = mat.node_tree.nodes.get("Principled BSDF") if mat.use_nodes else None
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (.035, .014, .025, 1)

# Recolor the back half of the original atlas hair while preserving the face front.
head_mesh = bpy.data.objects.get("Rogue_Head")
if head_mesh:
    dark_slot = next((i for i, m in enumerate(head_mesh.data.materials) if m and "ink-black hair" in m.name.lower()), None)
    if dark_slot is not None:
        for poly in head_mesh.data.polygons:
            if poly.material_index != 0:
                continue
            center = sum((head_mesh.data.vertices[i].co for i in poly.vertices), Vector()) / len(poly.vertices)
            if center.y > .08 or (abs(center.x) > .33 and center.y > -.12 and center.z > 1.18):
                poly.material_index = dark_slot

# Replace the previous unrecognizable sidearm with a compact, readable pistol prop.
for obj in list(bpy.context.scene.objects):
    if "sidearm" in obj.name.lower():
        bpy.data.objects.remove(obj, do_unlink=True)

def attach_to_hand(obj):
    world = obj.matrix_world.copy()
    obj.parent = rig
    obj.parent_type = "BONE"
    obj.parent_bone = "hand.r"
    obj.matrix_parent_inverse = (rig.matrix_world @ rig.pose.bones["hand.r"].matrix).inverted()
    obj.matrix_world = world

def prop_box(name, location, dimensions, mat, bevel):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Soft manufactured edge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    attach_to_hand(obj)
    return obj

def prop_cylinder(name, location, radius, depth, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=depth,
                                        location=location, rotation=(1.5708, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    attach_to_hand(obj)
    return obj

if "hand.r" in rig.pose.bones:
    hand = rig.pose.bones["hand.r"].head.copy()
    gun = hand + Vector((0, -.105, .025))
    steel = bpy.data.materials["Nightfall - blued pistol steel"]
    bronze = bpy.data.materials["Nightfall - aged bronze trim"]
    amber = bpy.data.materials["Nightfall - lantern glow"]
    prop_box("Nightfall sidearm | receiver", gun, (.075, .16, .06), steel, .012)
    prop_box("Nightfall sidearm | top rail", gun + Vector((0, 0, .038)), (.065, .12, .014), bronze, .004)
    prop_cylinder("Nightfall sidearm | barrel", gun + Vector((0, -.115, .008)), .022, .10, bronze)
    prop_cylinder("Nightfall sidearm | muzzle", gun + Vector((0, -.17, .008)), .026, .022, steel)
    prop_box("Nightfall sidearm | amber chamber", gun + Vector((0, -.025, .04)), (.026, .055, .018), amber, .004)
    prop_box("Nightfall sidearm | grip", gun + Vector((0, .035, -.075)), (.055, .07, .10), bronze, .008)

# Show the entire figure at review scale and use a clean blue-black studio stage.

# Show the entire figure at review scale and use a clean blue-black studio stage.
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.eevee.taa_render_samples = 64
scene.render.resolution_x = 1100
scene.render.resolution_y = 1500
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
scene.render.filepath = os.path.join(output_dir, "Nightfall_Scavenger_Chunky_Preview.png")

for obj in bpy.context.scene.objects:
    if obj.type == "CAMERA" and obj.name == "Nightfall Scavenger Review Camera":
        camera = obj
        break
else:
    camera_data = bpy.data.cameras.new("Nightfall Scavenger Review Camera")
    camera = bpy.data.objects.new("Nightfall Scavenger Review Camera", camera_data)
    scene.collection.objects.link(camera)
scene.camera = camera
camera.location = (-2.15, -4.8, 2.05)
camera.rotation_euler = (Vector((0, -0.02, 0.78)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 2.55
camera.data.shift_x = 0
camera.data.shift_y = 0

out_blend = os.path.join(output_dir, "Nightfall_Scavenger_Chunky.blend")
out_glb = os.path.join(output_dir, "Nightfall_Scavenger_Chunky.glb")
bpy.ops.wm.save_as_mainfile(filepath=out_blend)
bpy.ops.render.render(write_still=True)

bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    if obj.type in {"MESH", "ARMATURE"} and obj.name != "Preview floor":
        obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=out_glb, export_format="GLB", use_selection=True,
                          export_apply=True, export_skins=True, export_animations=False)
print("SCAVENGER_REVIEW", out_blend, out_glb, scene.render.filepath)
