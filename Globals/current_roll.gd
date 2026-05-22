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
var current_min_list = [1,1,1,0]
# base, mult, anti, anti_type
var current_monster_roll_list = [0, 0 , 0, 0]
var current_monster_min_list = [1, 1, 1, 1]

var player_damage :int
var monster_damage : int

var initial_roll : Array[int]
var initial_monster_roll : Array[int]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.

func turn_end():
	anti_operator()
	player_attack()

func monster_turn_end():
	monster_damage_operator()


func anti_operator():
	initial_roll.assign(current_roll_list)
	initial_monster_roll.assign(current_monster_roll_list)
	 
	current_monster_roll_list[anti_type] -= anti	
	current_monster_roll_list[anti_type] = max(\
	current_monster_roll_list[anti_type],\
	current_monster_min_list[anti_type])
	
	current_roll_list[current_monster_roll_list[RollIndex.ANTI_TYPE]] -= current_monster_roll_list[RollIndex.ANTI]
	current_roll_list[current_monster_roll_list[RollIndex.ANTI_TYPE]] = max(\
	current_min_list[current_monster_roll_list[RollIndex.ANTI_TYPE]],\
	current_roll_list[current_monster_roll_list[RollIndex.ANTI_TYPE]]
	)


func player_attack():
	var player_number_of_attack = current_roll_list[1]
	player_damage = current_roll_list[0]
	for i in player_number_of_attack:
		GlobalSignal.player_attacked.emit()
	GlobalSignal.player_attack_finished.emit()
	

func monster_damage_operator():
	monster_damage = current_monster_roll_list[RollIndex.BASE] * current_monster_roll_list[RollIndex.MULT]


func _exit_tree() -> void:
	pass


func round_end():
	await get_tree().create_timer(1).timeout
	CombatState.transition_to(CombatState.State.ROUND_START)
