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

func player_hit():
	hp.current_hp -= CurrentRoll.monster_damage
	var base_string = get_reduced_roll(RollIndex.BASE)
	var mult_string = get_reduced_roll(RollIndex.MULT)
	var announcement = "player took %s x %s damage"% [base_string, mult_string]
	print(announcement)
	GlobalSignal.announced.emit(announcement)
	# Round restart / defeat is now handled by CombatState (CHECK_DEFEAT → ROUND_START / GAME_OVER).

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
