extends ProgressBar
class_name Hp

var max_hp :int = 40:
	set(new_value):
		max_value = max_hp
		label.max_value = max_hp
var current_hp = 40 :
	set(new_value):
		current_hp = clamp(new_value, 0, max_hp)
		value = current_hp
		label.current_value = current_hp
var hp_regen = 0
@onready var label: Label = $Label


func _ready():
	GlobalSignal.round_started.connect(round_start)
	max_value = max_hp
	label.max_value = max_hp
	value = current_hp
	label.current_value = current_hp


func round_start():
	current_hp += hp_regen
	
	
func take_damage(damage: int):
	current_hp -= damage
