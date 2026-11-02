"""Build an original suburban mailbox, in metres, with no external assets.

Run from any directory:
    blender --background --factory-startup --python tools/blender/briefkasten.py

Blender coordinates: Z up, front faces -Y; origin is the post's ground contact.
glTF export converts to Y up. This script replaces the current Blender scene.
"""

from math import cos, pi, sin
from pathlib import Path

import bpy


OUTPUT = Path(__file__).resolve().parents[2] / "assets/models/generated/briefkasten.glb"


def material(name, color, metallic=0.0, roughness=0.65):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return mat


def mesh_object(name, vertices, faces, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def box(name, location, dimensions, mat, bevel=0.002):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Small rounded edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def profile(radius, floor, shoulder):
    """Closed cross-section: flat bottom, vertical sides, semicircular roof."""
    return [(-radius, floor), (radius, floor)] + [
        (radius * cos(i * pi / 20), shoulder + radius * sin(i * pi / 20))
        for i in range(21)
    ]


def panel(name, outline, front, back, mat):
    count = len(outline)
    vertices = [(x, y, z) for y in (front, back) for x, z in outline]
    faces = [tuple(range(count)), tuple(range(2 * count - 1, count - 1, -1))]
    faces += [(i, i + count, (i + 1) % count + count, (i + 1) % count)
              for i in range(count)]
    return mesh_object(name, vertices, faces, mat)


def build():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    steel = material("Faded blue painted steel", (0.12, 0.21, 0.25), 0.55)
    edge = material("Dark galvanized fittings", (0.10, 0.12, 0.13), 0.8, 0.4)
    wood = material("Weathered cedar", (0.24, 0.16, 0.095))
    red = material("Red signal flag", (0.65, 0.025, 0.018), 0.35)

    box("Cedar post", (0, 0.10, 0.60), (0.105, 0.105, 1.20), wood)
    box("Mounting crossbeam", (0, 0, 1.115), (0.14, 0.62, 0.075), wood)
    brace = box("Diagonal support", (0, 0.22, 0.96), (0.065, 0.065, 0.34), wood)
    brace.rotation_euler.x = -pi / 4

    # Thin closed sheet-metal shell, with a separate front door and back panel.
    outer = profile(0.135, 1.16, 1.30)
    inner = profile(0.131, 1.164, 1.30)
    count = len(outer)
    vertices = [(x, y, z) for outline in (outer, inner)
                for y in (-0.285, 0.285) for x, z in outline]
    faces = []
    for i in range(count):
        j = (i + 1) % count
        faces.extend([
            (i, i + count, j + count, j),
            (i + 2 * count, j + 2 * count, j + 3 * count, i + 3 * count),
            (i, j, j + 2 * count, i + 2 * count),
            (i + count, i + 3 * count, j + 3 * count, j + count),
        ])
    mesh_object("Arched metal housing", vertices, faces, steel)
    panel("Back panel", inner, 0.277, 0.285, steel)
    panel("Door dark seam", outer, -0.291, -0.285, edge)
    panel("Front door", profile(0.131, 1.164, 1.30), -0.299, -0.291, steel)
    box("Door hinge", (0, -0.302, 1.174), (0.21, 0.018, 0.016), edge)
    box("Latch strap", (0, -0.305, 1.402), (0.027, 0.012, 0.052), edge)
    box("Door handle", (0, -0.319, 1.405), (0.068, 0.026, 0.014), edge)

    box("Flag bracket", (0.143, 0.12, 1.275), (0.015, 0.045, 0.045), edge)
    box("Raised flag stem", (0.157, 0.12, 1.385), (0.009, 0.018, 0.22), red)
    box("Red flag", (0.157, 0.078, 1.48), (0.009, 0.10, 0.065), red)
    for y in (-0.18, 0.18):
        box("Mounting bolt", (0, y, 1.166), (0.018, 0.018, 0.012), edge, 0.001)

    # Recalculate normals consistently, including the hollow shell's inner wall.
    for obj in list(scene.objects):
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        obj.select_set(False)

    root = bpy.data.objects.new("Briefkasten", None)
    scene.collection.objects.link(root)
    for obj in list(scene.objects):
        if obj.type == "MESH":
            obj.parent = root
            obj.select_set(True)
    root.select_set(True)
    root["source"] = "Original procedural model: tools/blender/briefkasten.py"
    root["units"] = "metres"
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT), export_format="GLB", use_selection=True,
        export_yup=True, export_extras=True, export_animations=False,
        export_cameras=False, export_lights=False,
    )
    print(f"Exported {OUTPUT}")


if __name__ == "__main__":
    build()
