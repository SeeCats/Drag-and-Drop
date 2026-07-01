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
	var per_hit = CurrentRoll.player_damage          # published by combat_state._on_player_attack
	var blocked = CurrentRoll.player_blocked
	var label = _spawn()
	if label == null:  # subscene failed to load
		return
	if blocked > 0:
		label.pop_show_block(per_hit + blocked, blocked)
	else:
		label.pop_show_number(per_hit)

func _on_player_missed():
	var label = _spawn()
	if label:
		label.pop_show_miss()

func _on_monster_attacked():  # monster ver: down-tween variants
	var per_hit = CurrentRoll.monster_damage         # published by combat_state._on_monster_attack
	var blocked = CurrentRoll.monster_blocked
	var label = _spawn()
	if label == null:
		return
	if blocked > 0:
		label.pop_show_block_monster(per_hit + blocked, blocked)
	else:
		label.pop_show_number_monster(per_hit)

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
	_clamp_on_screen(n)   # keep the whole pop on-screen
	return n

func _clamp_on_screen(n: DamageNumberLabel) -> void:
	var view := get_viewport_rect().size
	var label_size := damage_number.size     # settled template size (n's may read 0 for a frame)
	var travel := float(n.vertical_speed)    # pop slides up/down by this
	var margin := 28.0                        # absorbs scale-punch overhang + screen shake
	var p := n.global_position
	p.x = clampf(p.x, margin, view.x - label_size.x - margin)
	p.y = clampf(p.y, margin + travel, view.y - label_size.y - travel - margin)
	n.global_position = p

func get_random_global_position():
	var random_position : Vector2 = Vector2(0,0)
	random_position.x = randf() * rect.size.x + rect.global_position.x
	random_position.y = randf() * rect.size.y + rect.global_position.y
	return	random_position
	
	
