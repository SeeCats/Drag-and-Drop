extends TextureRect

# Glow effect for the monster — tints itself with the color matching
# the monster's current anti_type and sits behind the main sprite.

@export var glow_alpha : float = 0.55
@export var glow_scale : float = 1.15


func _ready() -> void:
	show_behind_parent = true
	pivot_offset = size / 2.0
	scale = Vector2(glow_scale, glow_scale)
	resized.connect(_recenter_pivot)
	GlobalSignal.updated_roll.connect(_refresh_color)
	_refresh_color()


func _exit_tree() -> void:
	if GlobalSignal.updated_roll.is_connected(_refresh_color):
		GlobalSignal.updated_roll.disconnect(_refresh_color)


func _recenter_pivot() -> void:
	pivot_offset = size / 2.0


func _refresh_color() -> void:
	var anti_type : int = CurrentRoll.current_monster_roll_list[3]
	if anti_type < 0 or anti_type >= Swatch.ELEMENT_COLOR.size():
		return
	var c : Color = Swatch.ELEMENT_COLOR[anti_type]
	c.a = glow_alpha
	modulate = c
