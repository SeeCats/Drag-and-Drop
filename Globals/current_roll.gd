extends Rollables

var base : int =1:
	set(new_value):
		base = new_value
		current_roll_list[0] = new_value

var mult : int=2:
	set(new_value):
		mult = new_value
		current_roll_list[1] = new_value

var anti : int =3:
	set(new_value):
		anti = new_value
		current_roll_list[2] = new_value

var anti_type : int =0:
	set(new_value):
		anti_type = new_value
		current_roll_list[3] = new_value

var current_roll_list = [base, mult, anti, anti_type]
var action_index_list : Array[int]
#base mult anti
var current_min_list = [1,1,0,0]
# base, mult, anti, anti_type
var current_monster_roll_list = [3, 3 , 1, 0]
var current_monster_min_list = [1, 1, 0, 0]
var next_pattern: Pattern   # upcoming round's pattern (lookahead)

var player_damage :int
var monster_damage : int
var player_blocked : int    # base reduction this attack — for the damage-number "Blocked" pop
var monster_blocked : int

var initial_roll : Array[int]
var initial_monster_roll : Array[int]

var attack_stagger : float = 0.3  # delay between each hit/miss pop (read by combat_state._apply_attack)

var is_player_winning : String = "Proj Drag Drop"


func _ready() -> void:
	pass


func _exit_tree() -> void:
	pass


func round_end():
	await get_tree().create_timer(1).timeout
	CombatState.transition_to(CombatState.State.ROUND_START)


# --- Resolver --------------------------------------------------------------
# compute_outcome is the live resolver — both the FSM (via combat_state._on_turn_resolving)
# and the preview UI use it. The old mutating anti_operator / player_attack / monster_attack
# path was removed 2026-06-30; compute_outcome supersedes it (see ADR-001).

# Dice -> roll list. Model A: column order IS role order, so read left->right;
# anti_type = the ANTI-column die's element. Replaces player_character._roll_from.
func get_roll_from_dice(values: Array, elements: Array) -> Array:
	return [
		values[RollIndex.BASE],   # col 0
		values[RollIndex.MULT],   # col 1
		values[RollIndex.ANTI],   # col 2
		elements[RollIndex.ANTI], # anti_type = anti die's element
	]


# Pure, side-effect-free outcome: applies anti both ways on COPIES, returns per-side numbers.
func compute_outcome(player_roll: Array, monster_roll: Array) -> Dictionary:
	var p := player_roll.duplicate()
	var m := monster_roll.duplicate()
	# player's anti cuts the monster's roll at the player's anti_type
	var p_at: int = p[RollIndex.ANTI_TYPE]
	m[p_at] = max(m[p_at] - p[RollIndex.ANTI], current_monster_min_list[p_at])
	# monster's (now-updated) anti cuts the player's roll at the monster's anti_type
	var m_at: int = m[RollIndex.ANTI_TYPE]
	p[m_at] = max(p[m_at] - m[RollIndex.ANTI], current_min_list[m_at])
	return { "player": _side(p, player_roll), "monster": _side(m, monster_roll) }

func _side(reduced: Array, initial: Array) -> Dictionary:
	return {
		"per_hit": reduced[RollIndex.BASE],
		"hits": reduced[RollIndex.MULT],
		"total": reduced[RollIndex.BASE] * reduced[RollIndex.MULT],
		"blocked": initial[RollIndex.BASE] - reduced[RollIndex.BASE],
		"misses": initial[RollIndex.MULT] - reduced[RollIndex.MULT],
	}
