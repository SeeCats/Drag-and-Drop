@tool
extends Node2D
class_name Cube

# 2D wireframe cube with simulated 3D rotation.
# Each edge is drawn TWICE — once as a wide "halo" Line2D underneath, once as
# a thinner "core" Line2D on top. Both share the same projected endpoints; only
# their textures and widths differ. Same idea as the 3D core+halo cylinders but
# implemented as 2D textured strips.

@export var rotation_period : float = 3.0          # seconds per full rotation
@export var rotation_axis : Vector3 = Vector3(1, 1, 1)
@export var camera_distance : float = 4.0          # camera at (0, 0, +z) looking toward -Z
@export var focal_length : float = 250.0           # in pixels; bigger = telephoto/closer-looking
# ---- Inspector-tweakable layers --------------------------------------------------------------
# Drag two PNGs onto these slots — the halo is the wider, softer outer glow; the
# core is the bright thin filament drawn on top. Either can be left empty (the
# corresponding layer just won't render meaningfully without a texture).
# Color is multiplied with the texture pixels — WHITE = use texture colors as-is,
# anything else tints the whole layer (e.g. cyan halo with a white texture).

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

# ---- Geometry --------------------------------------------------------------------------------
# 8 corners of a unit cube — every combination of ±1 on each axis.
const CORNERS : Array[Vector3] = [
	Vector3(-1, -1, -1), Vector3( 1, -1, -1), Vector3( 1,  1, -1), Vector3(-1,  1, -1),
	Vector3(-1, -1,  1), Vector3( 1, -1,  1), Vector3( 1,  1,  1), Vector3(-1,  1,  1),
]
# 12 edges, each as a pair of indices into CORNERS.
const EDGES : Array = [
	[0, 1], [1, 2], [2, 3], [3, 0],     # back face (z = -1)
	[4, 5], [5, 6], [6, 7], [7, 4],     # front face (z = +1)
	[0, 4], [1, 5], [2, 6], [3, 7],     # 4 connectors between the two faces
]

# Two parallel arrays: same edge index, two visual layers.
var _halo_lines : Array[Line2D] = []
var _core_lines : Array[Line2D] = []
var _angle : float = 0.0


func _ready() -> void:
	# Spawn ALL halos first, THEN all cores. Children draw in list order, so this
	# guarantees every core sits on top of every halo at the corners — otherwise
	# edge B's halo (spawned after edge A's core in an interleaved layout) would
	# cover the connecting end of edge A's core and the joints look "pinched".
	# INTERNAL_MODE_BACK keeps everything above the non-internal Background.
	for _edge in EDGES:
		_halo_lines.append(_make_line())
	for _edge in EDGES:
		_core_lines.append(_make_line())
	_apply_layer(_halo_lines, halo_texture, halo_width, halo_color)
	_apply_layer(_core_lines, core_texture, core_width, core_color)


# Single-line factory — keeps the Line2D defaults in one place.
func _make_line() -> Line2D:
	var line := Line2D.new()
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	add_child(line, false, Node.INTERNAL_MODE_BACK)
	return line


# Push texture + width + color onto every line in one of the layers. Called from
# _ready and from each @export setter so inspector edits update live.
func _apply_layer(lines: Array[Line2D], texture: Texture2D, width: float, color: Color) -> void:
	for line in lines:
		line.texture = texture
		line.width = width
		line.default_color = color


func _process(delta: float) -> void:
	_angle += TAU / rotation_period * delta

	# Guard: Basis(axis, angle) errors if axis is a zero vector (no direction to
	# normalize). Skip the frame instead of spamming the output. Happens when an
	# instance has rotation_axis set to (0,0,0) — usually from a legacy serialized
	# value before the const→@export migration.
	if rotation_axis.is_zero_approx():
		return

	# Build the rotation as a Basis (3x3 matrix) once per frame, then apply it
	# to each corner. Basis(axis, angle) is Godot's built-in axis-angle constructor.
	var rotation_basis := Basis(rotation_axis.normalized(), _angle)

	# Step 1: rotate + project every corner once.
	var projected : Array[Vector2] = []
	for corner in CORNERS:
		projected.append(_project(rotation_basis * corner))

	# Step 2: feed the same two endpoints into both the halo and core line for
	# each edge — they share geometry, only width/texture differs.
	for i in EDGES.size():
		var edge = EDGES[i]
		var points := PackedVector2Array([projected[edge[0]], projected[edge[1]]])
		_halo_lines[i].points = points
		_core_lines[i].points = points


# Perspective projection: 3D world point → 2D pixel offset from this Node2D's origin.
# Place this Node2D wherever on screen you want the cube's center.
#
# Math: classic pinhole camera. Camera sits at (0, 0, +camera_distance) looking
# along -Z. For a point at world position (x, y, z), distance in front of the
# camera is (camera_distance - z). Dividing x and y by that distance gives the
# foreshortening — points farther away project closer to the screen center.
# Multiplying by focal_length converts to pixels.
# Y is negated because screen-Y grows downward but world-Y grows upward.
func _project(point: Vector3) -> Vector2:
	var z_from_camera : float = camera_distance - point.z
	if z_from_camera < 0.1:
		z_from_camera = 0.1   # clamp if a corner ever passes through the camera plane
	return Vector2(point.x, -point.y) * focal_length / z_from_camera
