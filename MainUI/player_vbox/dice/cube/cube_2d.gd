@tool
extends Node2D
class_name Cube

# 2D wireframe shape with simulated 3D rotation.
#
# The shape itself (corners, edges, faces) lives in a WireShape resource so this
# one script can render any convex-ish 3D outline — cubes, tetrahedra, monsters,
# items — just by swapping the .tres in the inspector.
#
# Rendering layers, bottom to top:
#   1. face fills (one Polygon2D per face)
#   2. halo lines (wide, soft outer glow per edge)
#   3. core lines (thin bright filament per edge)
#
# All three layers project from the SAME rotated 3D corners every frame, so they
# stay locked together no matter the rotation.

@export var rotation_period : float = 500.0          # seconds per full rotation
@export var rotation_axis : Vector3 = Vector3(0.5, 1.5, 0.707)
@export var euler_offset : Vector3 = Vector3(45, 45, 45)
var rotation_true : bool = true

# Camera state lives on the View autoload — all cubes share one vanishing point.
# Tune View.camera_position / camera_distance / focal_length, not per-cube.

# ---- Shape ---------------------------------------------------------------------------------------
# Swap this .tres to render a different wireframe. Setter rebuilds the Line2Ds /
# Polygon2Ds because the new shape may have a different edge or face count.
@export var shape : WireShape :
	set(value):
		shape = value
		_rebuild_layers()

# ---- Face fill -----------------------------------------------------------------------------------
# Shared tint applied to every face. Keep alpha low (~0.1–0.3) so overlapping
# faces stack into a translucent volumetric look instead of a flat blob.
@export var fill_color : Color = Color(0, 1, 1, 0.5) :
	set(value):
		fill_color = value
		for poly in _face_polys:
			poly.color = fill_color

# ---- Halo + core line layers ---------------------------------------------------------------------
# Drag two PNGs onto the texture slots. Halo is the wider, softer outer glow;
# core is the bright thin filament drawn on top. Either may be left empty.
# Color is multiplied with the texture pixels.

@export var halo_texture : Texture2D :
	set(value):
		halo_texture = value
		_apply_layer(_halo_lines, halo_texture, halo_width, halo_color)

@export var halo_width : float = 40.0 :
	set(value):
		halo_width = value
		_apply_layer(_halo_lines, halo_texture, halo_width, halo_color)

@export var halo_color : Color = Color.WHITE :
	set(value):
		halo_color = value
		_apply_layer(_halo_lines, halo_texture, halo_width, halo_color)

@export var core_texture : Texture2D :
	set(value):
		core_texture = value
		_apply_layer(_core_lines, core_texture, core_width, core_color)

@export var core_width : float = 12.0 :
	set(value):
		core_width = value
		_apply_layer(_core_lines, core_texture, core_width, core_color)

@export var core_color : Color = Color.WHITE :
	set(value):
		core_color = value
		_apply_layer(_core_lines, core_texture, core_width, core_color)

# ---- Internal child arrays ----------------------------------------------------------------------
var _face_polys : Array[Polygon2D] = []
var _halo_lines : Array[Line2D] = []
var _core_lines : Array[Line2D] = []
var _angle : float = 0.0

# ---camera-----------------------------------
@export var camera_distance : float = 4
@export var focal_length : float = 450

func _ready() -> void:
	print("Rotation speed ",rotation_period)
	_rebuild_layers()


# Free any existing children and respawn one Polygon2D per face, one Line2D per
# edge (twice — halo then core). Spawn order matters: children render in list
# order, so fills go first (bottom), then ALL halos, then ALL cores. Spawning
# all halos before any core also prevents joint "pinching" at edge corners.
func _rebuild_layers() -> void:
	for poly in _face_polys: poly.queue_free()
	for line in _halo_lines: line.queue_free()
	for line in _core_lines: line.queue_free()
	_face_polys.clear()
	_halo_lines.clear()
	_core_lines.clear()
	if shape == null:
		return
	for _face in shape.faces:
		_face_polys.append(_make_polygon())
	for _edge in shape.edges:
		_halo_lines.append(_make_line())
	for _edge in shape.edges:
		_core_lines.append(_make_line())
	_apply_layer(_halo_lines, halo_texture, halo_width, halo_color)
	_apply_layer(_core_lines, core_texture, core_width, core_color)


# Polygon2D factory.
func _make_polygon() -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = fill_color
	add_child(poly, false, Node.INTERNAL_MODE_BACK)
	return poly


# Line2D factory — keeps the Line2D defaults in one place.
func _make_line() -> Line2D:
	var line := Line2D.new()
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	add_child(line, false, Node.INTERNAL_MODE_BACK)
	return line


# Push texture + width + color onto every line in one of the layers. Called from
# _rebuild_layers and from each @export setter so inspector edits update live.
func _apply_layer(lines: Array[Line2D], texture: Texture2D, width: float, color: Color) -> void:
	for line in lines:
		line.texture = texture
		line.width = width
		line.default_color = color


func _process(delta: float) -> void:
	if shape == null:
		return

	_angle += TAU / rotation_period * delta * (rotation_true as float)

	# Guard: Basis(axis, angle) errors if axis is a zero vector. Skip the frame
	# instead of spamming the output (happens when an instance has a legacy
	# zero rotation_axis serialized from before the const→@export migration).
	if rotation_axis.is_zero_approx():
		return

	# Build the rotation as a Basis (3x3 matrix) once per frame, then apply it
	# to each corner. Basis(axis, angle) is Godot's built-in axis-angle constructor.
	var euler_basis := Basis.from_euler(euler_offset * PI / 180.0)
	var rotation_basis := Basis(rotation_axis.normalized(), _angle)

	# Step 1: rotate + project every corner once.
	# euler_basis pre-rotates the raw corners into the desired resting orientation,
	# then rotation_basis spins that pre-rotated shape around rotation_axis.
	var projected : Array[Vector2] = []
	for corner in shape.corners:
		projected.append(_project(rotation_basis * (euler_basis * corner)))

	# Step 2: feed projected points into the fill polygons (one per face).
	for i in shape.faces.size():
		var face_indices := shape.faces[i]
		var face_points := PackedVector2Array()
		for idx in face_indices:
			face_points.append(projected[idx])
		_face_polys[i].polygon = face_points

	# Step 3: feed the same two endpoints into both the halo and core line for
	# each edge — they share geometry, only width/texture differs.
	for i in shape.edges.size():
		var edge := shape.edges[i]
		var points := PackedVector2Array([projected[edge.x], projected[edge.y]])
		_halo_lines[i].points = points
		_core_lines[i].points = points


# Perspective projection: 3D corner offset → 2D pixel offset from this Node2D's origin.
# Per-cube pinhole — each cube projects around its own center, so a cube placed
# anywhere on screen renders cleanly there. (The shared-camera variant — using
# View.camera_position as a common vanishing point — pushed off-anchor cubes off
# the screen, so it was reverted. View.camera_position is still defined for a
# future second attempt at a shared-camera effect.)
#
# Math:
#   depth  = View.camera_distance - corner.z   # distance in front of pinhole
#   return = (corner.x, -corner.y) * focal_length / depth   # flip Y: world-up → screen-down
func _project(corner: Vector3) -> Vector2:
	var depth : float = camera_distance - corner.z
	if depth < 0.1:
		depth = 0.1   # clamp if a corner ever passes through the camera plane
	return Vector2(corner.x, -corner.y) * focal_length / depth
