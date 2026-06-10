extends TextureRect

# Blurred, anti_type-tinted halo that sits behind the slime sprite.
# The shader does the actual blurring; this script just keeps the tint
# uniform in sync with the monster's current anti_type.

const SHADER_PATH := "res://character/monster/slime/blurry_halo.gdshader"

@export var halo_alpha : float = 0.8

var _mat : ShaderMaterial


func _ready() -> void:
	show_behind_parent = true
	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER_PATH)
	material = _mat
	GlobalSignal.updated_roll.connect(_refresh_color)
	_refresh_color()


func _exit_tree() -> void:
	if GlobalSignal.updated_roll.is_connected(_refresh_color):
		GlobalSignal.updated_roll.disconnect(_refresh_color)


func _refresh_color() -> void:
	var anti_type : int = CurrentRoll.current_monster_roll_list[3]
	if anti_type < 0 or anti_type >= Swatch.ELEMENT_COLOR.size():
		return
	var c : Color = Swatch.ELEMENT_COLOR[anti_type]
	c.a = halo_alpha
	if _mat != null:
		_mat.set_shader_parameter("tint_color", c)
