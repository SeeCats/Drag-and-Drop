extends ProgressBar
class_name Hp

var max_hp :int = 40:
	set(new_value):
		max_value = new_value
		label.max_value = max_hp
var current_hp = 40 :
	set(new_value):
		var old = current_hp
		current_hp = clamp(new_value, 0, max_hp)
		label.current_value = current_hp
		if is_node_ready() and current_hp < old:
			_hit_feedback(current_hp)   # damage: tween bar + flash
		else:
			value = current_hp          # init / heal: instant
var hp_regen = 0
@export var round_start_priority : int = 50
@onready var label: Label = $Label


func _ready():
	add_to_group("round_participants")
	max_value = max_hp
	label.max_value = max_hp
	value = current_hp
	label.current_value = current_hp



func round_start():
	current_hp += hp_regen
	
	
func take_damage(damage: int):
	current_hp -= damage

var _hp_tween: Tween

func _hit_feedback(target: float) -> void:
	if _hp_tween and _hp_tween.is_valid():
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(self, "value", target, 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	modulate = Color(2, 2, 2)  # bright flash, eased back to white
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)



	
