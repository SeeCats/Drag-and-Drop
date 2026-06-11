extends Character
class_name PlayerCharacter


@onready var rotate: Rotate = $Rotate
@onready var swap: HBoxContainer = $Swap

var action_index_list : Array[Constants.RollIndex] = [
	RollIndex.BASE,
	RollIndex.MULT,
	RollIndex.ANTI
]
var element_index_list : Array[Constants.Element] = [
	Element.RED,
	Element.GREEN,
	Element.BLUE,
]
var dice_roll_list : Array [int]


func _ready() -> void:
	super()
	GlobalSignal.updated_roll.connect(update_player_dice)
	GlobalSignal.monster_attacked.connect(player_hit)
	GlobalSignal.monster_atack_finished.connect(announce_damage_taken)
	rotate.actions_rotated.connect(update_action)
	swap.dice_swapped.connect(update_dice_roll)

func update_player_dice():
	CurrentRoll.base = dice_roll_list[action_index_list.find(RollIndex.BASE) as int]
	CurrentRoll.mult = dice_roll_list[action_index_list.find(RollIndex.MULT) as int]
	CurrentRoll.anti = dice_roll_list[action_index_list.find(RollIndex.ANTI) as int]
	CurrentRoll.anti_type = element_index_list[action_index_list.find(RollIndex.ANTI) as int]

func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(update_player_dice)
	GlobalSignal.monster_attacked.disconnect(player_hit)
	GlobalSignal.monster_atack_finished.disconnect(announce_damage_taken)

func player_hit():
	hp.current_hp -= CurrentRoll.monster_damage  # per monster hit
	# Defeat handled by CombatState (CHECK_DEFEAT).

func announce_damage_taken():  # once, after all monster hits
	var base_string = get_reduced_roll(RollIndex.BASE)
	var mult_string = get_reduced_roll(RollIndex.MULT)
	var announcement = "player took %s x %s damage"% [base_string, mult_string]
	print(announcement)
	GlobalSignal.announced.emit(announcement)

func update_action(new_action_list : Array[Constants.RollIndex]):
	action_index_list = new_action_list

func update_dice_roll(dice_rolled_list : Array[int], element_list : Array[Constants.Element]):
	dice_roll_list = dice_rolled_list
	element_index_list = element_list


func get_reduced_roll(index:Constants.RollIndex):
	var reduced_roll : String = ""
	if CurrentRoll.current_monster_roll_list[index] == CurrentRoll.initial_monster_roll[index]:
		reduced_roll = str(CurrentRoll.current_monster_roll_list[index])
	else:
		var reduced_ammount = CurrentRoll.initial_monster_roll[index] - CurrentRoll.current_monster_roll_list[index]
		reduced_roll = "(%d - %d)" % [CurrentRoll.initial_monster_roll[index], reduced_ammount]
	return reduced_roll


# --- Hover preview (Stage 2): build a hypothetical arrangement, return readout ---

# Rotate src->tgt is deterministic: cycle the action labels on a copy, recompute.
func preview_rotate(src: int, tgt: int) -> String:
	var actions := action_index_list.duplicate()
	var k := (3 - src - tgt) % 3
	var t = actions[k]; actions[k] = actions[tgt]; actions[tgt] = actions[src]; actions[src] = t
	var o : Dictionary = CurrentRoll.compute_outcome(_roll_from(dice_roll_list, element_index_list, actions),
		CurrentRoll.current_monster_roll_list)
	return "Deal %d    Take %d" % [o.player.total, o.monster.total]

# Swap rerolls the picked die (src->tgt), so the outcome is a RANGE over 1..6.
func preview_swap(src: int, tgt: int) -> String:
	var deals := []
	var takes := []
	for v in range(1, 7):   # the picked die's possible reroll values
		var values := dice_roll_list.duplicate()
		var colors := element_index_list.duplicate()
		values[tgt] = v;                         colors[tgt] = element_index_list[src]
		values[src] = dice_roll_list[tgt];       colors[src] = element_index_list[tgt]
		var o : Dictionary = CurrentRoll.compute_outcome(_roll_from(values, colors, action_index_list),
			CurrentRoll.current_monster_roll_list)
		deals.append(o.player.total)
		takes.append(o.monster.total)
	return "Deal %s    Take %s" % [_rng(deals.min(), deals.max()), _rng(takes.min(), takes.max())]

func _roll_from(values: Array, colors: Array, actions: Array) -> Array:
	return [
		values[actions.find(RollIndex.BASE)],
		values[actions.find(RollIndex.MULT)],
		values[actions.find(RollIndex.ANTI)],
		colors[actions.find(RollIndex.ANTI)],
	]

func _rng(a: int, b: int) -> String:
	return str(a) if a == b else "%d~%d" % [a, b]
