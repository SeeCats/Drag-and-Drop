extends Character
class_name Monster

var monster_name : String = "Slime"
var monster_pattern_list : Array[Pattern] =[]
var current_round : int:
	set(new_value):
		current_round = new_value
		current_pattern = pattern_list[current_round % pattern_list.size()]
@export var pattern_list : Array[Pattern]
var current_pattern : Pattern
@onready var current_roll: HBoxContainer = $VBar/CurrentRoll



func _ready() -> void:
	super()
	current_pattern = pattern_list[current_round]
	update_roll()
	current_roll.update_text()
	GlobalSignal.player_attacked.connect(monster_hit)
	# Announce as soon as monster_attacked fires — at that point the FSM has
	# computed damage but hasn't yet cascaded into CHECK_DEFEAT / ROUND_START
	# (which would reset current_monster_roll_list to next round's values).
	GlobalSignal.monster_atack_finished.connect(_announce_attack)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func round_start():
	super()
	current_round += 1
	update_roll()

func update_roll():
	CurrentRoll.current_monster_roll_list[RollIndex.BASE] = current_pattern.base
	CurrentRoll.current_monster_roll_list[RollIndex.MULT] = current_pattern.mult
	CurrentRoll.current_monster_roll_list[RollIndex.ANTI] = current_pattern.anti
	CurrentRoll.current_monster_roll_list[RollIndex.ANTI_TYPE] = current_pattern.anti_type
	GlobalSignal.updated_roll.emit()
	
func monster_hit():
	print("monster_hit: dmg=", CurrentRoll.player_damage, " hp_before=", hp.current_hp)
	hp.current_hp -= CurrentRoll.player_damage
	print("  hp_after=", hp.current_hp)
	
	
	

func _announce_attack():
	print("INITIAL  player: ", CurrentRoll.initial_roll, "  monster: ", CurrentRoll.initial_monster_roll)
	print("CURRENT  player: ", CurrentRoll.current_roll_list, "  monster: ", CurrentRoll.current_monster_roll_list)
	print("announce: base=", CurrentRoll.current_monster_roll_list[RollIndex.BASE], " mult=", CurrentRoll.current_monster_roll_list[RollIndex.MULT])

	var base_string = get_reduced_roll(RollIndex.BASE)
	var mult_string = get_reduced_roll(RollIndex.MULT)
	var announcement = "%s took %s x %s damage" % [monster_name, base_string, mult_string]
	print(announcement)
	GlobalSignal.announced.emit(announcement)
	

func get_reduced_roll(index:Constants.RollIndex):
	var reduced_roll : String = ""
	if CurrentRoll.current_roll_list[index] == CurrentRoll.initial_roll[index]:
		reduced_roll = str(CurrentRoll.current_roll_list[index])
	else:
		var reduced_ammount = CurrentRoll.initial_roll[index] - CurrentRoll.current_roll_list[index]
		reduced_roll = "(%d - %d)" % [CurrentRoll.initial_roll[index], reduced_ammount]
	return reduced_roll
