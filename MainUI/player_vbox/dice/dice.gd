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
@export var texture : Texture
@export var element : Rollables.Element :
	set(value):
		element = value
		_apply_element_tint()
@export var fit_to_control : bool = true   # size the cube to this Control's rect (rework slots); off keeps old UI dice unchanged


var swapping : bool:
	set(new_value):
		swapping = new_value
		top_level = new_value
		cube.rotation_axis = Vector3(1, 1, -1)
		if !swapping:
			top_level = false
			label.text = str(current_roll)
			cube.halo_width = initial_halo_width
			cube.rotation_axis = Vector3(1, 1, 1)
			get_parent().queue_sort()
var swap_time : float = 0
var swap_interval : float = 0.2
var initial_halo_width : float = 12
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


func roll():
	current_roll = randi_range(min_roll, max_roll)

func fake_roll():
	label.text = "?"
	 
func _process(delta: float) -> void:
	# Keep the cube glued to the label's visual center, even if the Dice
	# control resizes. Label fills the parent (anchors_preset = 15) and text
	# is centered, so label.position + label.size / 2 is where the digit sits.
	cube.position = label.position + label.size / 2
	if fit_to_control:
		cube.fit_to(min(size.x, size.y))   # cube tracks the slot size
	if swapping:
		print("_process sees swapping=true, global_position=", global_position)
		cube.halo_width = initial_halo_width * (1 + 1 * sin(TAU * swap_time / swap_interval))
		swap_time += delta
		global_position = get_global_mouse_position() - size/2
		fake_roll() 
