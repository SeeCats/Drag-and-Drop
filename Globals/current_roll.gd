extends Rollables

# Shared roll data + the pure resolver. Owners publish here: the controller writes
# current_roll_list on commit, monster.update_roll writes current_monster_roll_list.

# [base, mult, anti, anti_type] — the committed player roll / this round's monster roll.
var current_roll_list = [1, 2, 3, 0]
var current_monster_roll_list = [3, 3, 1, 0]
# Anti floors per factor (base/mult floor at 1, anti strips to 0).
var current_min_list = [1, 1, 0, 0]
var current_monster_min_list = [1, 1, 0, 0]
var next_pattern: Pattern   # upcoming round's pattern (lookahead hook, #11)

# Per-hit + block amounts published by the FSM right before each attack, read by the
# damage-number zone.
var player_damage : int
var monster_damage : int
var player_blocked : int
var monster_blocked : int

var attack_stagger : float = 0.3  # delay between each hit/miss pop (read by combat_state._apply_attack)


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

# Builds one side's outcome around its damage LEDGER (ADR-002): the ordered list of
# damage instances this attack will apply. Entries are uniform (base repeated mult
# times) until effects exist to vary them; total derives from the ledger, and
# per_hit/hits stay as derived fields for the existing readers.
func _side(reduced: Array, initial: Array) -> Dictionary:
	var ledger : Array[int] = []
	for _i in reduced[RollIndex.MULT]:
		ledger.append(reduced[RollIndex.BASE])
	var total : int = 0
	for amount in ledger:
		total += amount
	return {
		"ledger": ledger,
		"per_hit": reduced[RollIndex.BASE],
		"hits": ledger.size(),
		"total": total,
		"blocked": initial[RollIndex.BASE] - reduced[RollIndex.BASE],
		"misses": initial[RollIndex.MULT] - reduced[RollIndex.MULT],
	}
