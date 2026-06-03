extends Control


@onready var rect: Control = self
@onready var damage_number: DamageNumber = $DamageNumber

var drag_start_pos : Vector2
var drag_end_pos : Vector2
var is_dragging : bool

func _ready() -> void:
	##print(self, " in tree")
	##for i in 4:
	##	show_damage_number()
	##	await get_tree().create_timer(0.3).timeout
	return
	
func show_damage_number():
	var new_damage_number = damage_number.duplicate()
	new_damage_number.global_position = get_random_global_position()
	add_child(new_damage_number)
	new_damage_number.pop_show_number(8)
	
func get_random_global_position():
	var random_position : Vector2 = Vector2(0,0)
	random_position.x = randf() * rect.size.x + rect.global_position.x
	random_position.y = randf() * rect.size.y + rect.global_position.y
	return	random_position
	
	
