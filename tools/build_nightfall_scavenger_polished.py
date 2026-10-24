"""Build a Blender-first Scavenger character study from the project's CC0 rigged base.

Run with:
  blender --background --python tools/build_nightfall_scavenger_polished.py

The source mesh remains editable and rigged. Clothing is fitted from its weighted
surface topology; armor, scarf, hair accents, goggles, pistol, and lantern are authored
as separate volumetric meshes. This creates a Blender asset, not a claim of 3D gameplay
integration (Nightfall's arena renderer is 2D).
"""

from __future__ import annotations

import math
import os
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "apps" / "nightfall-godot"
SOURCE_DIR = PROJECT / "prototypes" / "arcanist_cc0" / "source"
SOURCE_BLEND = SOURCE_DIR / "young_warrior_base.blend"
OUT = PROJECT / "prototypes" / "scavenger_blender" / "scavenger_polished"
OUT.mkdir(parents=True, exist_ok=True)

BLEND_OUT = OUT / "Nightfall_Scavenger_Polished.blend"
GLB_OUT = OUT / "Nightfall_Scavenger_Polished.glb"
VIEWS = {
    "threequarter": OUT / "Scavenger_ThreeQuarter.png",
    "front": OUT / "Scavenger_Front.png",
    "side": OUT / "Scavenger_Side.png",
    "back": OUT / "Scavenger_Back.png",
}


def rgba(rgb, alpha=1.0):
    return (rgb[0], rgb[1], rgb[2], alpha)


def mat(name, color, metallic=0.0, roughness=0.7, noise=0.0, emission=0.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = rgba(color)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    links = material.node_tree.links
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = rgba(color)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if "Emission Color" in shader.inputs:
        shader.inputs["Emission Color"].default_value = rgba(color)
        shader.inputs["Emission Strength"].default_value = emission
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    if noise:
        tex = nodes.new("ShaderNodeTexNoise")
        tex.inputs["Scale"].default_value = 32.0
        tex.inputs["Detail"].default_value = 2.0
        ramp = nodes.new("ShaderNodeValToRGB")
        low = tuple(c * (1.0 - noise) for c in color) + (1.0,)
        high = tuple(min(1.0, c * (1.0 + noise)) for c in color) + (1.0,)
        ramp.color_ramp.elements[0].position = 0.22
        ramp.color_ramp.elements[0].color = low
        ramp.color_ramp.elements[1].position = 0.78
        ramp.color_ramp.elements[1].color = high
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.025 if metallic < 0.3 else 0.018
        bump.inputs["Distance"].default_value = 0.025
        links.new(tex.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
        links.new(tex.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return material


def image_material(name, image_path, roughness=0.84):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    material.diffuse_color = (0.62, 0.42, 0.31, 1)
    nodes = material.node_tree.nodes
    nodes.clear()
    links = material.node_tree.links
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Roughness"].default_value = roughness
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = bpy.data.images.load(str(image_path), check_existing=True)
    texture.image.pack()
    texture.label = image_path.name
    links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return material


def smoothstep(value):
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def apply_rest_pose(body, armature):
    """Turn the inherited T-pose into a relaxed A-pose while keeping skin weights."""
    mesh = body.data
    for vertex in mesh.vertices:
        x, z = vertex.co.x, vertex.co.z
        if 108.0 < z < 156.0 and abs(x) < 18.0:
            vertex.co.x *= 1.1
            vertex.co.y *= 1.06
            x = vertex.co.x
        if abs(x) <= 13.0 or z < 116.0:
            continue
        sign = 1.0 if x > 0 else -1.0
        influence = smoothstep((abs(x) - 13.0) / 7.0)
        angle = math.radians(58.0) * sign * influence
        pivot = Vector((sign * 16.4, 5.5, 151.3))
        offset = vertex.co - pivot
        co, si = math.cos(angle), math.sin(angle)
        vertex.co = Vector((pivot.x + co * offset.x + si * offset.z,
                            offset.y,
                            pivot.z - si * offset.x + co * offset.z))
    mesh.update()

    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    edit_bones = armature.data.edit_bones
    for side in ("L", "R"):
        root_bone = edit_bones.get(f"Humerus.{side}")
        sign = 1.0 if root_bone.head.x > 0.0 else -1.0
        pivot = root_bone.head.copy()
        rotation = Matrix.Rotation(math.radians(58.0) * sign, 4, "Y")
        descendants = []
        for bone in list(edit_bones):
            parent = bone
            while parent:
                if parent == root_bone:
                    descendants.append(bone)
                    break
                parent = parent.parent
        connected = {bone.name: bone.use_connect for bone in descendants}
        for bone in descendants:
            bone.use_connect = False
        for bone in descendants:
            bone.head = pivot + rotation.to_3x3() @ (bone.head - pivot)
            bone.tail = pivot + rotation.to_3x3() @ (bone.tail - pivot)
        for bone in descendants:
            if connected[bone.name] and bone.parent and (bone.head - bone.parent.tail).length < 1e-4:
                bone.use_connect = True

    # The source hands were oversized for Nightfall's adult, mobile-action silhouette.
    hand_pivots = {}
    for side in ("L", "R"):
        root_bone = edit_bones.get(f"hand001.{side}")
        if root_bone is None:
            continue
        pivot = root_bone.head.copy()
        hand_pivots[side] = pivot.copy()
        descendants = []
        for bone in list(edit_bones):
            parent = bone
            while parent:
                if parent == root_bone:
                    descendants.append(bone)
                    break
                parent = parent.parent
        connected = {bone.name: bone.use_connect for bone in descendants}
        for bone in descendants:
            bone.use_connect = False
            bone.head = pivot + (bone.head - pivot) * 0.80
            bone.tail = pivot + (bone.tail - pivot) * 0.80
        for bone in descendants:
            if connected[bone.name] and bone.parent and (bone.head - bone.parent.tail).length < 1e-4:
                bone.use_connect = True
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()

    hand_group_sides = {}
    for group in body.vertex_groups:
        for side in ("L", "R"):
            if group.name.startswith("hand") and group.name.endswith(f".{side}"):
                hand_group_sides[group.index] = side
    for vertex in mesh.vertices:
        influence_by_side = {"L": 0.0, "R": 0.0}
        for membership in vertex.groups:
            side = hand_group_sides.get(membership.group)
            if side:
                influence_by_side[side] += membership.weight
        for side, influence in influence_by_side.items():
            pivot = hand_pivots.get(side)
            if pivot is not None and influence > 0.0:
                factor = 1.0 - 0.20 * min(1.0, influence)
                vertex.co = pivot + (vertex.co - pivot) * factor
    mesh.update()


def assign_body_materials(body, slots):
    mesh = body.data
    mesh.materials.clear()
    for material in slots:
        mesh.materials.append(material)
    for polygon in mesh.polygons:
        center = sum((mesh.vertices[i].co for i in polygon.vertices), Vector()) / len(polygon.vertices)
        x, z = abs(center.x), center.z
        index = 0  # exposed skin
        if z < 108.0 and x < 30.0:
            index = 3  # fitted charcoal trousers
        if z < 48.0 and x < 27.0:
            index = 4  # boot upper
        if 106.0 < z < 158.0 and x < 29.0:
            index = 1  # tailored coat body
        if 116.0 < z < 160.0 and 18.0 < x < 69.0:
            index = 2  # blue sleeves
        if x > 65.0 and z < 138.0:
            index = 5  # dark gloves
        polygon.material_index = index


def weighted_surface_shell(source, name, material_indices, armature, offset=1.7, thickness=1.25):
    source_mesh = source.data
    polygons = [p for p in source_mesh.polygons if p.material_index in material_indices]
    if not polygons:
        raise RuntimeError(f"No weighted source faces for {name}")
    used = sorted({vertex for polygon in polygons for vertex in polygon.vertices})
    remap = {old: new for new, old in enumerate(used)}
    coords = []
    for old in used:
        vertex = source_mesh.vertices[old]
        normal = vertex.normal.normalized() if vertex.normal.length else Vector((0, 0, 1))
        coords.append(tuple(vertex.co + normal * offset))
    faces = [tuple(remap[i] for i in polygon.vertices) for polygon in polygons]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(coords, [], faces)
    mesh.update()
    for material in source_mesh.materials:
        mesh.materials.append(material)
    for new_polygon, source_polygon in zip(mesh.polygons, polygons):
        new_polygon.material_index = source_polygon.material_index
        new_polygon.use_smooth = True
    if source_mesh.uv_layers:
        src_uv = source_mesh.uv_layers.active.data
        dst_uv = mesh.uv_layers.new(name="ScavengerClothUV")
        for new_polygon, source_polygon in zip(mesh.polygons, polygons):
            for new_loop, old_loop in zip(new_polygon.loop_indices, source_polygon.loop_indices):
                dst_uv.data[new_loop].uv = src_uv[old_loop].uv
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.matrix_world = source.matrix_world.copy()
    groups = [obj.vertex_groups.new(name=group.name) for group in source.vertex_groups]
    for old_index, new_index in remap.items():
        for weight in source_mesh.vertices[old_index].groups:
            groups[weight.group].add([new_index], weight.weight, "REPLACE")
    modifier = obj.modifiers.new("Scavenger weighted garment", "ARMATURE")
    modifier.object = armature
    modifier.use_vertex_groups = True
    solid = obj.modifiers.new("Fabric edge thickness", "SOLIDIFY")
    solid.thickness = thickness
    solid.offset = 0.8
    solid.use_rim = True
    bevel = obj.modifiers.new("Soft cloth edge", "BEVEL")
    bevel.width = 0.35
    bevel.segments = 2
    bevel.limit_method = "ANGLE"
    normal = obj.modifiers.new("Clean garment normals", "WEIGHTED_NORMAL")
    normal.keep_sharp = True
    return obj


def mesh_object(name, vertices, faces, material, smooth=True):
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = smooth
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def ellipsoid(name, center, radii, material, segments=24, rings=14):
    cx, cy, cz = center
    rx, ry, rz = radii
    vertices = []
    faces = []
    for row in range(rings + 1):
        phi = -math.pi / 2 + math.pi * row / rings
        for col in range(segments):
            theta = 2 * math.pi * col / segments
            vertices.append((cx + rx * math.cos(phi) * math.cos(theta),
                             cy + ry * math.cos(phi) * math.sin(theta),
                             cz + rz * math.sin(phi)))
    for row in range(rings):
        for col in range(segments):
            a = row * segments + col
            b = row * segments + (col + 1) % segments
            c = (row + 1) * segments + (col + 1) % segments
            d = (row + 1) * segments + col
            faces.append((a, b, c, d))
    obj = mesh_object(name, vertices, faces, material)
    return obj


def loft_z(name, rings, material, segments=16):
    """Custom tapered boot/armor shell from authored elliptical cross-sections."""
    vertices = []
    faces = []
    for z, cx, cy, rx, ry in rings:
        for i in range(segments):
            theta = 2 * math.pi * i / segments
            vertices.append((cx + rx * math.cos(theta), cy + ry * math.sin(theta), z))
    for row in range(len(rings) - 1):
        for i in range(segments):
            a = row * segments + i
            b = row * segments + (i + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    faces.append(tuple(reversed(range(segments))))
    faces.append(tuple((len(rings) - 1) * segments + i for i in range(segments)))
    return mesh_object(name, vertices, faces, material)


def curve_object(name, points, radius, material, cyclic=False, resolution=3):
    data = bpy.data.curves.new(name + "Curve", "CURVE")
    data.dimensions = "3D"
    data.resolution_u = 12
    data.bevel_depth = radius
    data.bevel_resolution = resolution
    spline = data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1.0)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    return obj


def ring_front(name, center, major_radius, tube_radius, material, segments=28, sides=8):
    """A real toroidal lens frame whose ring plane faces the character's front (-Y)."""
    cx, cy, cz = center
    vertices, faces = [], []
    for i in range(segments):
        theta = 2 * math.pi * i / segments
        for j in range(sides):
            phi = 2 * math.pi * j / sides
            radial = major_radius + tube_radius * math.cos(phi)
            vertices.append((cx + radial * math.cos(theta),
                             cy + tube_radius * math.sin(phi),
                             cz + radial * math.sin(theta)))
    for i in range(segments):
        for j in range(sides):
            a = i * sides + j
            b = i * sides + (j + 1) % sides
            c = ((i + 1) % segments) * sides + (j + 1) % sides
            d = ((i + 1) % segments) * sides + j
            faces.append((a, b, c, d))
    return mesh_object(name, vertices, faces, material)


def domed_pauldron(name, center, rx, rz, material):
    """Hand-shaped convex shoulder plate with a shallow, armored crown."""
    cx, cy, cz = center
    outline = [(-0.82, -0.28), (-0.88, 0.18), (-0.56, 0.66), (-0.12, 0.88),
               (0.42, 0.74), (0.86, 0.36), (1.0, -0.08), (0.62, -0.66),
               (0.05, -0.92), (-0.50, -0.70)]
    rings = (0.28, 0.58, 0.82, 1.0)
    vertices = [(cx, cy - 2.6, cz)]
    for radius in rings:
        for px, pz in outline:
            vertices.append((cx + rx * radius * px,
                             cy - 2.6 * (1.0 - radius * radius),
                             cz + rz * radius * pz))
    sides = len(outline)
    faces = []
    first = 1
    for i in range(sides):
        faces.append((0, first + i, first + (i + 1) % sides))
    for ring_index in range(len(rings) - 1):
        low = 1 + ring_index * sides
        high = low + sides
        for i in range(sides):
            j = (i + 1) % sides
            faces.append((low + i, high + i, high + j, low + j))
    plate = mesh_object(name, vertices, faces, material, smooth=False)
    shell = plate.modifiers.new("Solid bronze plate", "SOLIDIFY")
    shell.thickness = 1.4
    shell.offset = 0.2
    bevel = plate.modifiers.new("Rounded armor edge", "BEVEL")
    bevel.width = 0.45
    bevel.segments = 2
    return plate


def ribbon(name, points, widths, material, thickness=1.0):
    vertices = []
    for index, point in enumerate(points):
        p = Vector(point)
        before = Vector(points[max(0, index - 1)])
        after = Vector(points[min(len(points) - 1, index + 1)])
        tangent = (after - before).normalized()
        side = tangent.cross(Vector((0, 1, 0))).normalized()
        if side.length < 0.01:
            side = Vector((1, 0, 0))
        vertices.extend((tuple(p - side * widths[index] * 0.5), tuple(p + side * widths[index] * 0.5)))
    faces = [(i * 2, i * 2 + 1, i * 2 + 3, i * 2 + 2) for i in range(len(points) - 1)]
    obj = mesh_object(name, vertices, faces, material, smooth=False)
    solid = obj.modifiers.new("Woven thickness", "SOLIDIFY")
    solid.thickness = thickness
    bevel = obj.modifiers.new("Soft ribbon edge", "BEVEL")
    bevel.width = 0.5
    bevel.segments = 2
    return obj


def extruded_profile(name, center, profile, depth, material, axis="x"):
    """Beveled solid from a designed 2D silhouette (used for the hand cannon)."""
    cx, cy, cz = center
    vertices = []
    for side in (-0.5, 0.5):
        for forward, height in profile:
            if axis == "x":
                vertices.append((cx + side * depth, cy - forward, cz + height))
            else:
                vertices.append((cx + forward, cy + side * depth, cz + height))
    count = len(profile)
    faces = [tuple(reversed(range(count))), tuple(count + i for i in range(count))]
    for i in range(count):
        faces.append((i, (i + 1) % count, count + (i + 1) % count, count + i))
    obj = mesh_object(name, vertices, faces, material, smooth=False)
    bevel = obj.modifiers.new("Machined edge radii", "BEVEL")
    bevel.width = 1.05
    bevel.segments = 3
    normal = obj.modifiers.new("Receiver face normals", "WEIGHTED_NORMAL")
    return obj


def parent_to_bone(obj, armature, bone_name):
    obj.parent = armature
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    bpy.context.view_layer.update()
    rest = armature.matrix_world @ armature.pose.bones[bone_name].matrix
    obj.matrix_parent_inverse = rest.inverted()
    obj.matrix_world = Matrix.Identity(4)


def clean_meshes_and_weights():
    """Remove degenerate source faces and normalize tiny CC0 weight overshoots for glTF."""
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        if obj.data.validate(verbose=True, clean_customdata=False):
            print("CLEANED_INVALID_MESH", obj.name)
        obj.data.update()
        if not obj.vertex_groups:
            continue
        for vertex in obj.data.vertices:
            memberships = list(vertex.groups)
            total = sum(item.weight for item in memberships)
            if total <= 0.0 or abs(total - 1.0) < 1e-7:
                continue
            for item in memberships:
                obj.vertex_groups[item.group].add([vertex.index], item.weight / total, "REPLACE")


def add_body_boots(materials, armature):
    boots, soles, greaves = [], [], []
    for side, x in (("L", 13.0), ("R", -13.0)):
        shaft = loft_z(f"Scavenger Boot Shaft {side}", [
            (13, x, 3.0, 8.1, 9.0), (18, x, 3.0, 8.3, 9.2),
            (31, x, 3.2, 7.2, 8.5), (44, x, 3.5, 7.3, 8.2),
            (51, x, 3.8, 7.9, 8.4), (54, x, 3.8, 7.2, 7.9),
        ], materials["Leather | warm umber"], 18)
        parent_to_bone(shaft, armature, f"Tibia.{side}.001")
        boots.append(shaft)

        foot = ellipsoid(f"Scavenger Boot Toe {side}", (x, -1.2, 8.0), (7.8, 14.5, 6.8), materials["Leather | warm umber"], 20, 10)
        parent_to_bone(foot, armature, f"Foot.{side}")
        boots.append(foot)

        sole = loft_z(f"Scavenger Boot Sole {side}", [
            (1.3, x, -1.4, 8.6, 15.6), (3.3, x, -1.4, 8.8, 15.8),
            (5.0, x, -1.4, 8.2, 15.0),
        ], materials["Boot sole | near-black"], 20)
        parent_to_bone(sole, armature, f"Foot.{side}")
        soles.append(sole)

        cuff = loft_z(f"Scavenger Boot Cuff {side}", [
            (44, x, 3.5, 7.8, 8.7), (46, x, 3.5, 8.3, 9.1),
            (49, x, 3.5, 8.3, 9.1), (51, x, 3.5, 7.8, 8.6),
        ], materials["Aged bronze"], 18)
        parent_to_bone(cuff, armature, f"Tibia.{side}.001")
        greaves.append(cuff)
        plate = extruded_profile(f"Scavenger Shin Guard {side}", (x, -7.2, 31.5),
            [(-4.2, 8.0), (0, 11.0), (4.2, 8.0), (4.7, 2.0), (3.3, -8.0), (0, -11.0), (-3.3, -8.0), (-4.7, 2.0)],
            2.0, materials["bronze"], axis="y")
        parent_to_bone(plate, armature, f"Tibia.{side}.001")
        greaves.append(plate)
        knee = extruded_profile(f"Scavenger Knee Shell {side}", (x, -7.5, 53.0),
            [(-5.2, 2.0), (-3.6, 5.0), (0, 6.5), (3.6, 5.0), (5.2, 2.0), (4.2, -3.5), (0, -5.2), (-4.2, -3.5)],
            2.6, materials["bronze"], axis="y")
        parent_to_bone(knee, armature, f"Tibia.{side}")
        greaves.append(knee)
    return boots + soles + greaves


def add_coat_tails(materials, armature):
    result = []
    for side, sign in (("Left", -1.0), ("Right", 1.0)):
        rows = [(112, 0.0, 1.0), (99, 2.2, 0.9), (82, 4.7, 0.7), (64, 5.3, 0.0)]
        vertices = []
        for z, sway, hem in rows:
            inner_x = sign * (7.0 + sway)
            outer_x = sign * (18.0 + sway + hem)
            vertices.extend(((inner_x, 7.5 + sway * 0.4, z),
                             (outer_x, 8.8 + sway * 0.7, z - hem)))
        faces = [(i * 2, i * 2 + 1, i * 2 + 3, i * 2 + 2) for i in range(len(rows) - 1)]
        tail = mesh_object(f"Nightfall split coat tail {side}", vertices, faces, materials["Nightfall blue"], False)
        solid = tail.modifiers.new("Tail cloth thickness", "SOLIDIFY")
        solid.thickness = 1.5
        bevel = tail.modifiers.new("Tail edge soften", "BEVEL")
        bevel.width = 0.55
        bevel.segments = 2
        parent_to_bone(tail, armature, "Sacrum.001")
        edge_points = [vertices[i * 2 + 1] for i in range(len(rows))]
        seam = curve_object(f"Gold coat-tail piping {side}", edge_points, 0.7, materials["Bronze highlight"])
        parent_to_bone(seam, armature, "Sacrum.001")
        result.extend((tail, seam))
    return result


def build_character():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE_BLEND))
    scene = bpy.context.scene
    armature = bpy.data.objects["Armature"]
    body = bpy.data.objects["body.001"]
    # Keep only the editable humanoid, face, hair and eyes from the CC0 source scene.
    keep = {armature, body, bpy.data.objects["baseMesh1_A1.001"], bpy.data.objects["hair"],
            bpy.data.objects["eye.L"], bpy.data.objects["eye.R"]}
    for obj in list(scene.objects):
        if obj not in keep:
            bpy.data.objects.remove(obj, do_unlink=True)
    for modifier in list(body.modifiers):
        if modifier.type == "DISPLACE":
            body.modifiers.remove(modifier)
    clean_meshes_and_weights()

    materials = {
        "skin": image_material("Scavenger skin | source albedo", SOURCE_DIR / "baseMesh_A1_body.png"),
        "face": image_material("Scavenger face | source UV albedo", SOURCE_DIR / "baseMesh_A1_face.png"),
        "eye": image_material("Scavenger eyes | source iris", SOURCE_DIR / "black_eye.png", 0.35),
        "cloth": mat("Nightfall blue", (0.004, 0.014, 0.085), roughness=0.86, noise=0.035),
        "sleeve": mat("Nightfall royal-blue sleeves", (0.008, 0.028, 0.15), roughness=0.82, noise=0.03),
        "pants": mat("Charcoal fitted trousers", (0.012, 0.016, 0.03), roughness=0.9, noise=0.025),
        "boot": mat("Leather warm umber", (0.10, 0.034, 0.012), roughness=0.76, noise=0.045),
        "sole": mat("Boot sole | near-black", (0.012, 0.016, 0.025), roughness=0.94),
        "glove": mat("Dark leather gloves", (0.035, 0.027, 0.024), roughness=0.86, noise=0.025),
        "ivory": mat("Scarf | warm ivory", (0.75, 0.66, 0.50), roughness=0.92, noise=0.02),
        "bronze": mat("Aged bronze", (0.38, 0.15, 0.032), metallic=0.55, roughness=0.38, noise=0.035),
        "gold": mat("Bronze highlight", (0.78, 0.43, 0.10), metallic=0.55, roughness=0.32, noise=0.015),
        "steel": mat("Blued steel", (0.055, 0.08, 0.13), metallic=0.58, roughness=0.38, noise=0.015),
        "hair": mat("Blue-black hair", (0.012, 0.008, 0.018), roughness=0.8, noise=0.015),
        "hair_hi": mat("Warm hair glints", (0.075, 0.027, 0.024), roughness=0.72),
        "amber": mat("Lantern amber glass", (0.62, 0.16, 0.025), metallic=0.06, roughness=0.34, emission=0.18),
        "goggle": mat("Smoked amber goggle lenses", (0.22, 0.055, 0.006), metallic=0.28, roughness=0.24, emission=0.015),
        "dark": mat("Ink-dark trim", (0.018, 0.016, 0.024), roughness=0.72),
    }
    materials.update({
        "Leather | warm umber": materials["boot"],
        "Bronze highlight": materials["gold"],
        "Aged bronze": materials["bronze"],
        "Boot sole | near-black": materials["sole"],
        "Nightfall blue": materials["cloth"],
    })

    # Restore image-based materials; the source blend omitted their node links.
    body.data.materials.clear()
    body.data.materials.append(materials["skin"])
    body.data.materials.append(materials["cloth"])
    body.data.materials.append(materials["sleeve"])
    body.data.materials.append(materials["pants"])
    body.data.materials.append(materials["boot"])
    body.data.materials.append(materials["glove"])
    assign_body_materials(body, list(body.data.materials))
    for name in ("baseMesh1_A1.001",):
        bpy.data.objects[name].data.materials.clear()
        bpy.data.objects[name].data.materials.append(materials["face"])
    for name in ("eye.L", "eye.R"):
        bpy.data.objects[name].data.materials.clear()
        bpy.data.objects[name].data.materials.append(materials["eye"])
    hair = bpy.data.objects["hair"]
    hair.data.materials.clear()
    hair.data.materials.append(materials["hair"])

    # The fitted fabric layers inherit the base mesh's actual vertex weights.
    apply_rest_pose(body, armature)
    garments = [
        weighted_surface_shell(body, "Tailored blue coat | weighted", {1, 2}, armature, 2.0, 1.4),
        weighted_surface_shell(body, "Charcoal trousers | weighted", {3}, armature, 1.8, 1.2),
        weighted_surface_shell(body, "Leather gloves | weighted", {5}, armature, 1.4, 1.0),
    ]
    garments.extend(add_body_boots(materials, armature))
    garments.extend(add_coat_tails(materials, armature))

    # A thick cloth cowl shortens the neck read and two sculpted tails break the chest plane.
    scarf_points = []
    for i in range(36):
        t = 2 * math.pi * i / 36
        scarf_points.append((11.0 * math.cos(t), 2.0 + 12.0 * math.sin(t), 157.0 + 1.6 * math.sin(t * 2)))
    scarf = curve_object("Scavenger wrapped ivory scarf", scarf_points, 3.5, materials["ivory"], cyclic=True, resolution=4)
    parent_to_bone(scarf, armature, "Spine3")
    garments.append(scarf)
    tail_a = ribbon("Scarf tail | broad diagonal drape", [(-2, -13.5, 157), (-6, -14.0, 152), (-10, -14.8, 147), (-11, -15.4, 142), (-8, -14.5, 137)], [7.5, 8.0, 7.2, 5.5, 3.2], materials["ivory"], 1.7)
    parent_to_bone(tail_a, armature, "Spine3")
    garments.append(tail_a)
    scarf_stitch = curve_object("Ivory scarf stitched edge", [(-6, -15.3, 151), (-10, -16.0, 145), (-9, -15.5, 139)], 0.32, materials["gold"])
    parent_to_bone(scarf_stitch, armature, "Spine3")
    garments.append(scarf_stitch)

    # Tailored lapels, chest harness and double stitched coat seams.
    for side, sign in (("Left", -1), ("Right", 1)):
        lapel = ribbon(f"Blue coat lapel {side}", [(sign * 8, -13.5, 153), (sign * 12, -15.3, 145), (sign * 7, -16.4, 137)], [6.5, 5.8, 3.5], materials["sleeve"], 1.2)
        parent_to_bone(lapel, armature, "Spine3")
        garments.append(lapel)
        seam = curve_object(f"Coat seam | {side}", [(sign * 17, -10.2, 132), (sign * 16, -11.4, 120), (sign * 14, -11.1, 111)], 0.55, materials["gold"])
        parent_to_bone(seam, armature, "Spine2")
        garments.append(seam)
    harness = ribbon("Diagonal leather scavenger harness", [(17, -11.6, 151), (8, -14.0, 141), (-2, -15.3, 130), (-14, -13.6, 115)], [4.6, 4.4, 4.1, 3.6], materials["boot"], 1.4)
    parent_to_bone(harness, armature, "Spine2")
    garments.append(harness)
    harness_edge = curve_object("Harness gold welt", [(17, -12.5, 151), (8, -14.9, 141), (-2, -16.1, 130), (-14, -14.4, 115)], 0.45, materials["gold"])
    parent_to_bone(harness_edge, armature, "Spine2")
    garments.append(harness_edge)

    # The rear has matching harness and tailoring, rather than an empty blue slab.
    back_yoke = ribbon("Nightfall back shoulder yoke", [(-15, 12.0, 148), (-9, 14.0, 153), (0, 15.0, 154), (9, 14.0, 153), (15, 12.0, 148)], [4.0, 4.7, 4.8, 4.7, 4.0], materials["cloth"], 1.4)
    parent_to_bone(back_yoke, armature, "Spine3")
    back_harness = ribbon("Scavenger rear harness", [(-15, 13.0, 150), (-7, 15.0, 140), (2, 15.4, 130), (15, 13.0, 116)], [3.4, 3.2, 3.0, 2.8], materials["boot"], 1.2)
    parent_to_bone(back_harness, armature, "Spine2")
    garments.extend((back_yoke, back_harness))
    star_front = [(0, 16.0, 151), (1.1, 16.0, 146.3), (4.0, 16.0, 144), (1.1, 16.0, 141.7),
                  (0, 16.0, 137), (-1.1, 16.0, 141.7), (-4.0, 16.0, 144), (-1.1, 16.0, 146.3)]
    star_vertices = star_front + [(x, y + 1.0, z) for x, y, z in star_front]
    star_faces = [tuple(range(8)), tuple(reversed(range(8, 16)))] + [(i, (i + 1) % 8, 8 + (i + 1) % 8, 8 + i) for i in range(8)]
    back_crest = mesh_object("Four-point Scavenger back crest", star_vertices, star_faces, materials["gold"], False)
    parent_to_bone(back_crest, armature, "Spine3")
    garments.append(back_crest)

    # Convex shoulder shells catch light as armor instead of reading like flat boxes.
    for side, x, bone, scale in (("Left", 16.5, "Clavicle.L", 1.22), ("Right", -16.5, "Clavicle.R", 0.48)):
        outward = 1.0 if x > 0 else -1.0
        shell = domed_pauldron(f"Scavenger domed shoulderguard {side}", (x, -9.0, 149.5), 8.4 * scale, 6.6 * scale, materials["bronze"])
        parent_to_bone(shell, armature, bone)
        shoulder_outline = [(-0.82, -0.28), (-0.88, 0.18), (-0.56, 0.66), (-0.12, 0.88),
                            (0.42, 0.74), (0.86, 0.36), (1.0, -0.08), (0.62, -0.66),
                            (0.05, -0.92), (-0.50, -0.70)]
        rim_points = [(x + outward * 8.4 * scale * px, -9.25, 149.5 + 6.6 * scale * pz)
                      for px, pz in shoulder_outline]
        rim = curve_object(f"Shoulderguard raised bronze edge {side}", rim_points, 0.38 * scale, materials["gold"], cyclic=True)
        parent_to_bone(rim, armature, bone)
        rivet = ellipsoid(f"Shoulderguard rivet {side}", (x + outward * 4.8 * scale, -11.4, 151.0), (0.65 * scale, 0.48, 0.65 * scale), materials["gold"], 10, 8)
        parent_to_bone(rivet, armature, bone)
        crest = curve_object(f"Shoulderguard Nightfall crest {side}",
            [(x, -12.5, 153.0), (x - 0.9 * scale, -12.5, 150.9),
             (x, -12.5, 148.8), (x + 0.9 * scale, -12.5, 150.9),
             (x, -12.5, 153.0)], 0.32 * scale, materials["gold"])
        parent_to_bone(crest, armature, bone)
        garments.extend((shell, rim, rivet, crest))

    # Belt is a curved leather strap, with an oversized readable buckle and two pouches.
    belt_points = []
    for i in range(40):
        t = 2 * math.pi * i / 40
        belt_points.append((17.5 * math.cos(t), 1.0 + 13.0 * math.sin(t), 107.0 + 1.3 * math.cos(t * 2)))
    belt = curve_object("Scavenger layered leather belt", belt_points, 2.6, materials["boot"], cyclic=True)
    parent_to_bone(belt, armature, "Sacrum.001")
    garments.append(belt)
    # Rectangular buckle built as a bevelled frame mesh, not an image decal.
    buckle = curve_object("Bronze belt buckle frame", [(-4, -14.8, 109), (4, -14.8, 109), (4, -14.8, 103), (-4, -14.8, 103)], 0.9, materials["gold"], cyclic=True)
    parent_to_bone(buckle, armature, "Sacrum.001")
    garments.append(buckle)
    center_bar = curve_object("Buckle tongue", [(0, -15.6, 104), (0, -15.6, 108)], 0.55, materials["bronze"])
    parent_to_bone(center_bar, armature, "Sacrum.001")
    garments.append(center_bar)
    for side, x in (("Right", 18),):
        pouch = extruded_profile(f"Scavenger utility pouch {side}", (x, -12.0, 101),
            [(-5.2, 5.0), (4.6, 5.0), (6.0, 2.5), (5.2, -5.0), (-5.2, -5.0), (-6.0, 2.5)],
            5.2, materials["boot"])
        parent_to_bone(pouch, armature, "Sacrum.001")
        flap = extruded_profile(f"Utility pouch flap {side}", (x, -15.0, 104.4),
            [(-5.6, 2.5), (5.6, 2.5), (5.0, -1.8), (0.0, -3.0), (-5.0, -1.8)],
            1.4, materials["bronze"])
        parent_to_bone(flap, armature, "Sacrum.001")
        stud = ellipsoid(f"Utility pouch brass stud {side}", (x, -16.2, 104.4), (0.75, 0.45, 0.75), materials["gold"], 10, 8)
        parent_to_bone(stud, armature, "Sacrum.001")
        garments.extend((pouch, flap, stud))

    # Two layered round goggles sit on the hairline; the strap wraps around the skull.
    for side, x in (("Left", -4.4), ("Right", 4.4)):
        lens = ellipsoid(f"Amber goggle lens {side}", (x, -8.8, 185.6), (3.25, 1.15, 2.75), materials["goggle"], 24, 14)
        frame = ring_front(f"Bronze goggle frame {side}", (x, -9.8, 185.6), 3.45, 0.58, materials["gold"])
        inner = ring_front(f"Dark goggle inner seal {side}", (x, -10.05, 185.6), 2.88, 0.22, materials["dark"], 24, 6)
        for obj in (lens, frame, inner):
            parent_to_bone(obj, armature, "head")
            garments.append(obj)
        hinge = ellipsoid(f"Goggle temple hinge {side}", (x * 1.9, -8.1, 185.6), (0.9, 0.75, 0.8), materials["bronze"], 12, 8)
        parent_to_bone(hinge, armature, "head")
        garments.append(hinge)
    bridge = curve_object("Goggle bridge", [(-0.9, -10.0, 185.6), (0, -10.6, 186.0), (0.9, -10.0, 185.6)], 0.62, materials["bronze"])
    parent_to_bone(bridge, armature, "head")
    garments.append(bridge)
    strap = curve_object("Goggle leather head strap", [(-8.8, -8.0, 185.6), (-12.0, -4.0, 183.8), (-12.2, 4.5, 181.5), (0, 9.5, 181.0), (12.2, 4.5, 181.5), (12.0, -4.0, 183.8), (8.8, -8.0, 185.6)], 0.82, materials["boot"])
    parent_to_bone(strap, armature, "head")
    garments.append(strap)
    # Strengthen the source face's expression with separate brows, not a painted-on face card.
    for side, points in (
        ("Left", [(-5.8, -5.0, 177.1), (-3.4, -5.8, 178.0), (-1.0, -5.2, 176.6)]),
        ("Right", [(1.0, -5.2, 176.6), (3.4, -5.8, 178.0), (5.8, -5.0, 177.1)]),
    ):
        brow = curve_object(f"Scavenger expressive brow {side}", points, 0.62, materials["hair"], resolution=2)
        parent_to_bone(brow, armature, "head")
        garments.append(brow)

    # Sidearm is modeled face-on for the review/gameplay angle, with its muzzle down in the holster.
    hx, hy, hz = -18.0, -13.0, 108.0
    receiver = extruded_profile("Scavenger pistol | sculpted receiver", (hx, hy - 1.0, hz + 4.5),
        [(-7.5, -1.5), (-5.8, 3.2), (3.4, 4.4), (7.5, 2.2), (7.2, -1.8), (2.0, -3.8), (-5.2, -3.6)],
        4.8, materials["steel"], axis="y")
    parent_to_bone(receiver, armature, "Sacrum.001")
    garments.append(receiver)
    side_plate = extruded_profile("Scavenger pistol | bronze side plate", (hx, hy - 3.9, hz + 4.5),
        [(-4.7, -1.4), (-3.3, 2.0), (3.2, 2.3), (4.9, 0.8), (3.8, -1.1), (-3.4, -1.7)],
        0.7, materials["bronze"], axis="y")
    parent_to_bone(side_plate, armature, "Sacrum.001")
    garments.append(side_plate)
    barrel = loft_z("Scavenger pistol | blued barrel", [
        (hz - 16.0, hx, hy - 3.2, 1.3, 1.3), (hz - 14.0, hx, hy - 3.2, 1.8, 1.8),
        (hz + 0.5, hx, hy - 3.2, 1.8, 1.8), (hz + 2.0, hx, hy - 3.2, 1.35, 1.35)],
        materials["steel"], 10)
    muzzle = loft_z("Scavenger pistol | brass muzzle", [
        (hz - 16.2, hx, hy - 3.2, 1.6, 1.6), (hz - 15.2, hx, hy - 3.2, 1.9, 1.9)],
        materials["gold"], 10)
    for obj in (barrel, muzzle):
        parent_to_bone(obj, armature, "Sacrum.001")
        garments.append(obj)
    grip = extruded_profile("Scavenger pistol | wrapped grip", (hx + 1.5, hy - 4.0, hz + 9.5),
        [(-2.5, -1.0), (2.7, -0.3), (4.4, 3.2), (3.2, 9.6), (0.8, 11.0), (-2.4, 8.2)],
        4.0, materials["boot"], axis="y")
    parent_to_bone(grip, armature, "Sacrum.001")
    garments.append(grip)
    grip_bands = [curve_object(f"Pistol grip wrap {i}", [(hx - 1.0, hy - 6.2, hz + i * 2.2), (hx + 4.2, hy - 6.2, hz + i * 2.2)], 0.32, materials["gold"]) for i in range(1, 4)]
    for obj in grip_bands:
        parent_to_bone(obj, armature, "Sacrum.001")
    garments.extend(grip_bands)
    trigger = curve_object("Scavenger pistol | trigger guard", [(hx - 3, hy - 6.0, hz + 1), (hx - 3, hy - 6.0, hz - 2.5), (hx + 3, hy - 6.0, hz - 2.5), (hx + 3, hy - 6.0, hz + 1)], 0.42, materials["gold"])
    parent_to_bone(trigger, armature, "Sacrum.001")
    garments.append(trigger)
    chamber = ellipsoid("Pistol amber chamber", (hx + 4.0, hy - 5.0, hz + 4.5), (1.35, 0.75, 1.35), materials["amber"], 12, 8)
    parent_to_bone(chamber, armature, "Sacrum.001")
    garments.append(chamber)
    holster = extruded_profile("Scavenger pistol leather holster", (hx, hy + 4.0, hz - 4.0),
        [(-7.0, 5.0), (5.8, 5.0), (7.2, 2.6), (6.4, -7.0), (3.6, -17.0), (-3.4, -17.0), (-6.4, -8.0)],
        5.4, materials["boot"], axis="y")
    parent_to_bone(holster, armature, "Sacrum.001")
    holster_flap = extruded_profile("Holster retention strap", (hx, hy - 2.8, hz + 2.0),
        [(-5.8, 1.2), (5.8, 1.2), (5.8, -1.2), (-5.8, -1.2)],
        1.0, materials["bronze"], axis="y")
    parent_to_bone(holster_flap, armature, "Sacrum.001")
    garments.extend((holster, holster_flap))

    # A faceted glass lantern with a real cage and shaped bronze crown.
    lantern_x, lantern_y, lantern_z = 22.0, -13.0, 92.0
    lantern = loft_z("Belt lantern | faceted amber glass", [
        (84.7, lantern_x, lantern_y, 3.6, 2.5), (87.0, lantern_x, lantern_y, 4.3, 2.8),
        (97.0, lantern_x, lantern_y, 4.3, 2.8), (99.3, lantern_x, lantern_y, 3.6, 2.5),
    ], materials["amber"], 8)
    parent_to_bone(lantern, armature, "Sacrum.001")
    garments.append(lantern)
    for z in (85.4, 98.6):
        cap = loft_z(f"Lantern bronze cap {z:.1f}", [
            (z - 1.2, lantern_x, lantern_y, 4.7, 3.0),
            (z, lantern_x, lantern_y, 5.4, 3.35),
            (z + 1.2, lantern_x, lantern_y, 4.7, 3.0),
        ], materials["bronze"], 8)
        parent_to_bone(cap, armature, "Sacrum.001")
        garments.append(cap)
    for dx in (-5.2, 5.2):
        rail = curve_object(f"Lantern bronze cage rail {dx:+.1f}", [(lantern_x + dx, lantern_y - 3.1, lantern_z - 7.5), (lantern_x + dx, lantern_y - 3.1, lantern_z + 7.5)], 0.55, materials["gold"])
        parent_to_bone(rail, armature, "Sacrum.001")
        garments.append(rail)
    for z in (lantern_z - 7.5, lantern_z + 7.5):
        rail = curve_object("Lantern bronze crossbar", [(lantern_x - 5.2, lantern_y - 3.1, z), (lantern_x + 5.2, lantern_y - 3.1, z)], 0.55, materials["bronze"])
        parent_to_bone(rail, armature, "Sacrum.001")
        garments.append(rail)
    handle = curve_object("Lantern hanging loop", [(lantern_x - 3, lantern_y, lantern_z + 8), (lantern_x - 2, lantern_y, lantern_z + 13), (lantern_x + 2, lantern_y, lantern_z + 13), (lantern_x + 3, lantern_y, lantern_z + 8)], 0.65, materials["gold"])
    parent_to_bone(handle, armature, "Sacrum.001")
    garments.append(handle)

    # Add stitch points and rivets only where they help the silhouette read.
    for side, x in (("Left", 13.0), ("Right", -13.0)):
        for i in range(3):
            stud = ellipsoid(f"Cuff bronze rivet {side} {i + 1}", (x + (3.2 if x > 0 else -3.2), -9.0, 23 + i * 4.2), (0.58, 0.48, 0.58), materials["gold"], 10, 8)
            parent_to_bone(stud, armature, f"Tibia.{ 'L' if side == 'Left' else 'R' }.001")
            garments.append(stud)

    # Convert bevelled curves to real meshes so both Blender and glTF see the same details.
    for obj in list(bpy.context.scene.objects):
        if obj.type == "CURVE":
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            bpy.ops.object.convert(target="MESH")
            obj.select_set(False)
    clean_meshes_and_weights()
    lantern_pivot = Vector((lantern_x, lantern_y, lantern_z))
    lantern_fit = (Matrix.Translation(lantern_pivot) @ Matrix.Scale(0.82, 4) @
                   Matrix.Translation(-lantern_pivot))
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and (obj.name.startswith("Belt lantern") or obj.name.startswith("Lantern ")):
            obj.data.transform(lantern_fit)
            obj.data.update()
    armature.name = "Nightfall Scavenger Humanoid Rig"
    armature.animation_data_clear()

    for obj in list(scene.objects):
        if obj.type != "MESH" or obj.parent == armature:
            continue
        if any(mod.type == "ARMATURE" and mod.object == armature for mod in obj.modifiers):
            world = obj.matrix_world.copy()
            obj.parent = armature
            obj.parent_type = "OBJECT"
            obj.matrix_world = world

    # Character root scales the original centimeter-based source to meters for glTF.
    root = bpy.data.objects.new("Nightfall Scavenger Root", None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    character_objects = [obj for obj in bpy.context.scene.objects if obj.type in {"MESH", "ARMATURE"}]
    for obj in character_objects:
        if obj == root:
            continue
        if obj.parent is None:
            world = obj.matrix_world.copy()
            obj.parent = root
            obj.matrix_world = world
    root.scale = (0.01, 0.01, 0.01)
    for image in bpy.data.images:
        if image.source == "FILE":
            try:
                image.pack()
            except RuntimeError:
                pass

    # Studio scene is meters after the root scale.
    scene.unit_settings.system = "METRIC"
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 1280
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = 0.15
    world = bpy.data.worlds.new("Nightfall navy studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.025, 0.05, 0.12, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    scene.world = world
    floor_mat = mat("Studio stage | blue-black", (0.012, 0.025, 0.065), roughness=0.94)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.022))
    floor = bpy.context.object
    floor.name = "Render-only studio floor"
    floor.data.materials.append(floor_mat)
    floor.hide_render = False
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 2.0, 5.0), rotation=(math.radians(90), 0, 0))
    backdrop = bpy.context.object
    backdrop.name = "Render-only studio backdrop"
    backdrop.data.materials.append(floor_mat)
    for name, position, power, color, size in [
        ("Key | soft warm", (-3.2, -4.0, 3.5), 250, (1.0, 0.79, 0.61), 3.2),
        ("Fill | cool", (3.0, -2.8, 2.0), 120, (0.46, 0.62, 1.0), 3.0),
        ("Rim | blue", (0.6, 2.2, 3.1), 220, (0.2, 0.42, 1.0), 2.2),
        ("Face fill", (-0.2, -2.4, 1.7), 65, (1.0, 0.88, 0.73), 1.5),
    ]:
        data = bpy.data.lights.new(name, "AREA")
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.location = position
        data.energy = power
        data.shape = "DISK"
        data.size = size
        light.rotation_euler = (Vector((0, 0, 1.0)) - light.location).to_track_quat("-Z", "Y").to_euler()

    def camera(name, location, target, ortho=2.25):
        data = bpy.data.cameras.new(name)
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = location
        obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
        data.type = "ORTHO"
        data.ortho_scale = ortho
        return obj

    cams = {
        "threequarter": camera("Review | Nightfall three-quarter", (2.1, -4.4, 1.72), (0, 0, 0.98), 2.25),
        "front": camera("Review | front", (0, -4.4, 1.72), (0, 0, 0.98), 2.25),
        "side": camera("Review | right profile", (4.4, 0, 1.72), (0, 0, 0.98), 2.25),
        "back": camera("Review | rear", (0, 4.4, 1.72), (0, 0, 0.98), 2.25),
    }
    scene.camera = cams["threequarter"]
    scene.render.film_transparent = False

    # Opening the .blend should show the model, not a script console or a hidden stage.
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.region_3d.view_perspective = "CAMERA"
                space.shading.type = "MATERIAL"
                space.overlay.show_floor = False
                space.overlay.show_axis_x = False
                space.overlay.show_axis_y = False

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUT))

    # Render independent views so depth, side profile, and back construction are reviewable.
    review_target = Vector((0.0, 0.0, 0.98))
    for view_name, view_camera in cams.items():
        toward_camera = (view_camera.location - review_target).normalized()
        backdrop.location = review_target - toward_camera * 1.8
        backdrop.rotation_euler = toward_camera.to_track_quat("Z", "Y").to_euler()
        backdrop.hide_render = False
        scene.camera = view_camera
        scene.render.filepath = str(VIEWS[view_name])
        bpy.ops.render.render(write_still=True)

    # Mobile-conscious export: one rig, fitted weighted garments, modular props, packed albedo.
    backdrop.hide_render = False
    scene.camera = cams["threequarter"]
    export_set = [root, armature] + [obj for obj in bpy.context.scene.objects
                                     if obj.type == "MESH" and not obj.name.startswith("Render-only studio")]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in export_set:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(filepath=str(GLB_OUT), export_format="GLB", use_selection=True,
        export_skins=True, export_materials="EXPORT", export_cameras=False,
        export_lights=False, export_animations=False, export_apply=True,
        export_yup=True, export_image_format="AUTO")

    # Self-check the authored source before reporting it.
    body_shells = [obj for obj in bpy.context.scene.objects if obj.name.startswith(("Tailored blue coat", "Charcoal trousers", "Leather gloves"))]
    assert len(body_shells) == 3, "Weighted cloth shells were not created"
    assert len(armature.data.bones) >= 60, "The humanoid skeleton was lost"
    assert all(any(m.type == "ARMATURE" and m.object == armature for m in obj.modifiers) for obj in body_shells), "Garments must retain skinning"
    assert all(path.exists() and path.stat().st_size > 50_000 for path in [BLEND_OUT, GLB_OUT, *VIEWS.values()])
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj != floor]
    triangles = sum(len(obj.data.loop_triangles) for obj in mesh_objects)
    print("NIGHTFALL_SCAVENGER_POLISHED_BUILD_OK",
          "bones", len(armature.data.bones),
          "mesh_objects", len(mesh_objects),
          "triangles", triangles,
          "blend", BLEND_OUT,
          "glb", GLB_OUT)


build_character()
