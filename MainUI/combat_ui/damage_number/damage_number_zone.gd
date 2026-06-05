extends Control


# preload-by-path: type survives sibling script parse errors
const DamageNumberLabel = preload("res://MainUI/combat_ui/damage_number/damage_number_label.gd")

@onready var rect: Control = self
@onready var damage_number: DamageNumberLabel = $DamageNumberLabel

var drag_start_pos : Vector2
var drag_end_pos : Vector2
var is_dragging : bool

func _ready() -> void:
	damage_number.hide()  # template stays hidden; we pop duplicates
	GlobalSignal.player_attacked.connect(_on_player_attacked)
	GlobalSignal.player_missed.connect(_on_player_missed)
	GlobalSignal.monster_attacked.connect(_on_monster_attacked)
	GlobalSignal.monster_missed.connect(_on_monster_missed)

func _on_player_attacked():
	var original = CurrentRoll.initial_roll[Constants.RollIndex.BASE]
	var current = CurrentRoll.current_roll_list[Constants.RollIndex.BASE]
	var blocked = original - current
	var label = _spawn()
	if label == null:  # subscene failed to load
		return
	if blocked > 0:
		label.pop_show_block(original, blocked)
	else:
		label.pop_show_number(current)

func _on_player_missed():
	var label = _spawn()
	if label:
		label.pop_show_miss()

func _on_monster_attacked():  # monster ver: down-tween variants
	var original = CurrentRoll.initial_monster_roll[Constants.RollIndex.BASE]
	var current = CurrentRoll.current_monster_roll_list[Constants.RollIndex.BASE]
	var blocked = original - current
	var label = _spawn()
	if label == null:
		return
	if blocked > 0:
		label.pop_show_block_monster(original, blocked)
	else:
		label.pop_show_number_monster(current)

func _on_monster_missed():
	var label = _spawn()
	if label:
		label.pop_show_miss_monster()

func _spawn() -> DamageNumberLabel:
	if damage_number == null:
		return null
	var n = damage_number.duplicate()
	n.global_position = get_random_global_position()
	add_child(n)
	return n

func get_random_global_position():
	var random_position : Vector2 = Vector2(0,0)
	random_position.x = randf() * rect.size.x + rect.global_position.x
	random_position.y = randf() * rect.size.y + rect.global_position.y
	return	random_position
	
	
