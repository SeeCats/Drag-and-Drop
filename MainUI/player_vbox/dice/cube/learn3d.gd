@tool
extends Node3D

# Neon wireframe cube — built procedurally so each step is visible.
# @tool makes _ready() run in the editor too, so the cube appears in the 3D
# viewport without pressing Play. All add_child calls below use INTERNAL_MODE_FRONT
# so spawned nodes aren't saved into the .tscn (otherwise reopening the scene
# would duplicate them every time).
# Scene tree at runtime:
#   Learn3d (Node3D + this script)
#     ├── Camera3D                (added in _setup_camera)
#     ├── WorldEnvironment        (added in _setup_environment — gives us bloom)
#     └── 12 × MeshInstance3D     (added in _build_wireframe_cube — the edges)

const CUBE_SIZE : float = 2.0           # edge-to-edge length of the cube
const EDGE_RADIUS : float = 0.04        # thickness of the halo "tube"
const CORE_RADIUS_RATIO : float = 0.4   # inner white core is 40% of halo radius
const AURA_RADIUS_RATIO : float = 6.0   # outer world-space glow is 6× halo radius
const NEON_COLOR : Color = Color.CYAN
const EMISSION_ENERGY : float = 6.0     # how hot the emission is; >1 pushes into HDR for bloom
const ROTATION_PERIOD : float = 3.0     # seconds for one full rotation
const ROTATION_AXIS : Vector3 = Vector3(1, 1, 1)  # diagonal — normalized at use

var _halo_material : StandardMaterial3D
var _core_material : StandardMaterial3D
var _aura_material : StandardMaterial3D
var _cube_root : Node3D                 # parent of the 36 cylinders, so we rotate
										# just the cube and leave the camera/env still


func _ready() -> void:
	_setup_camera()
	_setup_environment()
	_cube_root = Node3D.new()
	add_child(_cube_root, false, Node.INTERNAL_MODE_FRONT)
	_build_wireframe_cube()


func _process(delta: float) -> void:
	# Rotate the cube container — not the whole scene — so camera and environment
	# stay still while the geometry spins.
	if _cube_root == null:
		return
	_cube_root.rotate(ROTATION_AXIS.normalized(), TAU / ROTATION_PERIOD * delta)


# ---- 1. Camera ---------------------------------------------------------------
# A 3D scene renders nothing until a Camera3D is present and "current".
# Position somewhere off-axis so we see the cube in 3/4 view, then look_at the origin.
func _setup_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(3, 3, 5)
	camera.fov = 50.0  # narrower than default 75° — portrait viewport needs less spread
	add_child(camera, false, Node.INTERNAL_MODE_FRONT)  # must be in tree BEFORE look_at —
	camera.look_at(Vector3.ZERO, Vector3.UP)   # look_at reads global_transform, which is
											   # only valid once the node has a parent in
											   # the scene tree. Called before add_child it
											   # silently no-ops and the camera stays at
											   # default rotation (facing -Z).


# ---- 2. Environment + glow ---------------------------------------------------
# "Neon" isn't a material — it's a bright color + a post-process bloom that
# bleeds bright pixels into a soft halo. Without glow_enabled, the cube is just
# a flat cyan wireframe with no halo. The hdr_threshold controls which pixels
# count as "bright enough" to bloom.
func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)  # near-black so the glow pops
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	env.glow_hdr_scale = 2.0

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env, false, Node.INTERNAL_MODE_FRONT)


# ---- 3. The wireframe cube ---------------------------------------------------
# A cube has 12 edges — 4 along each of the X, Y, Z axes.
# For each edge we spawn one thin cylinder positioned at the edge's midpoint
# and rotated so its long axis lies along the edge direction.
# All edges share ONE material so we could retint the whole cube by changing
# _edge_material.emission later.
func _build_wireframe_cube() -> void:
	# Halo: full-radius cyan tube using ADD blend so it lights the air around it
	# without occluding the white core sitting inside it.
	_halo_material = StandardMaterial3D.new()
	_halo_material.albedo_color = NEON_COLOR
	_halo_material.emission_enabled = true
	_halo_material.emission = NEON_COLOR
	_halo_material.emission_energy_multiplier = EMISSION_ENERGY
	_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	# Core: thin opaque white tube — the "filament" you see through the halo,
	# slightly hotter than the halo so it punches through.
	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = Color.WHITE
	_core_material.emission_enabled = true
	_core_material.emission = Color.WHITE
	_core_material.emission_energy_multiplier = EMISSION_ENERGY * 1.5

	# Aura: fat low-energy cyan tube — the world-space glow that stays constant
	# relative to the cube under zoom (unlike post-process bloom). Low emission
	# energy so it sums softly instead of overpowering. ADD blend, no occlusion.
	_aura_material = StandardMaterial3D.new()
	_aura_material.albedo_color = NEON_COLOR
	_aura_material.emission_enabled = true
	_aura_material.emission = NEON_COLOR
	_aura_material.emission_energy_multiplier = EMISSION_ENERGY * 0.15
	_aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	var half : float = CUBE_SIZE * 0.5
	var corners : Array[float] = [-half, half]

	# X-axis edges: 4 edges (one per Y/Z corner combination)
	for y in corners:
		for z in corners:
			_add_edge(Vector3(-half, y, z), Vector3(half, y, z))
	# Y-axis edges
	for x in corners:
		for z in corners:
			_add_edge(Vector3(x, -half, z), Vector3(x, half, z))
	# Z-axis edges
	for x in corners:
		for y in corners:
			_add_edge(Vector3(x, y, -half), Vector3(x, y, half))


# Build one cylinder between two endpoints.
# CylinderMesh's default orientation is +Y (vertical). We rotate so +Y aligns
# with the edge direction. For axis-aligned cube edges, the direction is always
# one of +X, +Y, +Z, so the math is simple — cross product gives the rotation
# axis, dot product gives the angle.
func _add_edge(start_pos: Vector3, end_pos: Vector3) -> void:
	var length : float = start_pos.distance_to(end_pos)
	var midpoint : Vector3 = (start_pos + end_pos) * 0.5
	var direction : Vector3 = (end_pos - start_pos).normalized()

	# Three cylinders per edge, inside-out: opaque core, transparent halo,
	# fat low-energy aura. All ADD-blended layers commute, but going inside-out
	# keeps the intent readable.
	_spawn_cylinder(midpoint, direction, length, EDGE_RADIUS * CORE_RADIUS_RATIO, _core_material)
	_spawn_cylinder(midpoint, direction, length, EDGE_RADIUS, _halo_material)
	_spawn_cylinder(midpoint, direction, length, EDGE_RADIUS * AURA_RADIUS_RATIO, _aura_material)


func _spawn_cylinder(center: Vector3, direction: Vector3, length: float, radius: float, material: StandardMaterial3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.material = material

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	if not direction.is_equal_approx(Vector3.UP):
		var axis : Vector3 = Vector3.UP.cross(direction).normalized()
		var angle : float = acos(Vector3.UP.dot(direction))
		instance.rotate(axis, angle)

	# Parent to _cube_root, not self — so the cube rotates without the camera moving.
	_cube_root.add_child(instance, false, Node.INTERNAL_MODE_FRONT)
