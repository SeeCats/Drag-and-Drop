extends Resource
class_name WireShape

# A 3D wireframe shape definition that Cube renders.
#
# corners : 3D vertex positions (unit-ish — Cube projects them with focal_length).
# edges   : pairs of corner indices, one Line2D drawn per pair.
# faces   : ordered corner indices forming a convex polygon, one Polygon2D drawn per face.
#
# Faces should be listed in a consistent winding (e.g. counter-clockwise when viewed
# from outside). Winding doesn't affect Polygon2D rendering, but matters later if you
# add backface culling or normals.

@export var corners : Array[Vector3] = []
@export var edges : Array[Vector2i] = []
@export var faces : Array[PackedInt32Array] = []
