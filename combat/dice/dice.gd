@tool
extends Control
class_name Dice

# A single die: holds a current_roll value (1..max_roll), shows it as a Label,
# and displays a spinning wireframe Cube2d behind the number tinted to the
# dice's element color (red/green/blue/white via Swatch.ELEMENT_COLOR).

@export var max_roll : int = 6
@export var min_roll : int =1
@export var current_roll : int :
	set(new_value):
		current_roll = clamp(new_value, min_roll, max_roll)
		if label:
			label.text = str(current_roll)
@export var element : Rollables.Element :
	set(value):
		element = value
		_apply_element_tint()
@export var fit_to_control : bool = true   # size the cube to this Control's rect (rework slots); off keeps old UI dice unchanged


# Grab/release state. On grab: cache home, go top_level, and snap to the cursor in the
# same frame (top_level reinterprets position as global). On release: snap straight back
# home — leaving the position garbled until the deferred container sort corrupted any
# read taken in the same input event (the rotate flight launched from garbage coords).
var swapping : bool:
	set(new_value):
		swapping = new_value
		if swapping:
			_drag_home = global_position   # capture before leaving the layout
			top_level = true
			global_position = get_global_mouse_position() - size / 2
			swap_time = 0.0
			fake_roll()
		else:
			top_level = false
			global_position = _drag_home
			label.text = str(current_roll)
			cube.halo_width = initial_halo_width
			get_parent().queue_sort()
var swap_time : float = 0
var swap_interval : float = 0.2
var initial_halo_width : float = 12
var _drag_home : Vector2   # layout position a drag returns to
@onready var cube : Cube = $Cube2d   # the spinning wireframe cube behind the number
@onready var label = $Label                 # the number rendered on top of the cube


func _ready() -> void:
	_apply_element_tint()



func _apply_element_tint() -> void:
	# Tint cube fill + halo to this die's element. Guarded because the element
	# setter can fire before @onready resolves cube.
	if cube:
		cube.fill_color = Swatch.HALF[element as int]
		cube.halo_color = Swatch.NEON_COLOR[element as int]


func fake_roll():
	label.text = "?"


var _fly_tween : Tween
var _flight_offset : Vector2 = Vector2.ZERO   # visual-only shift, applied to label+cube in _process

# Presentation-only FLIP flight: the die (already showing its final value) appears to
# launch from from_global and settle into place. Implemented as a pure visual offset on
# the label/cube — the control itself never leaves its container (a top_level flight
# reflowed the slot layout mid-air and the die landed against a shifted rect).
# arc_height > 0 bows the path up over the row (the rotate wrap, ui-spec §5).
func fly_from(from_global: Vector2, arc_height: float = 0.0, dur: float = 0.25) -> void:
	if swapping:
		return   # a grabbed die follows the mouse; don't fight it
	if _fly_tween and _fly_tween.is_valid():
		_fly_tween.kill()
	var start : Vector2 = from_global - global_position
	_fly_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fly_tween.tween_method(_fly_step.bind(start, arc_height), 0.0, 1.0, dur)

# One flight sample: the offset shrinks to exactly ZERO at t=1, plus a parabolic bow.
func _fly_step(t: float, start: Vector2, arc_height: float) -> void:
	_flight_offset = start * (1.0 - t) - Vector2(0.0, arc_height * 4.0 * t * (1.0 - t))


func _process(delta: float) -> void:
	# Keep the cube glued to the label's visual center, even if the Dice
	# control resizes. Label fills the parent (anchors_preset = 15) and text
	# is centered, so label.position + label.size / 2 is where the digit sits.
	# _flight_offset shifts both during a fly_from (zero at rest).
	label.position = _flight_offset
	cube.position = label.position + label.size / 2
	if fit_to_control:
		cube.fit_to(min(size.x, size.y))   # cube tracks the slot size
	if swapping:
		cube.halo_width = initial_halo_width * (1 + 1 * sin(TAU * swap_time / swap_interval))
		swap_time += delta
		global_position = get_global_mouse_position() - size / 2
