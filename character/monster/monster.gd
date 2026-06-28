extends Character
class_name Monster

@export var monster_name : String = "Slime"
@export var data : MonsterResource   # when set, overrides the fields below (rework path); null = legacy
var current_round : int:
	set(new_value):
		current_round = new_value
		current_pattern = pattern_list[current_round % pattern_list.size()]
@export var pattern_list : Array[Pattern]
var current_pattern : Pattern
@onready var current_roll = get_node_or_null("VBar/CurrentRoll")   # legacy roll display; absent in the lean rework Monster



func _ready() -> void:
	super()
	Combatants.monster = self
	_load_data()
	hp.label.set("monster_name", monster_name)   # name shows on this monster's HP bar only
	current_pattern = pattern_list[current_round]
	update_roll()
	if current_roll:
		current_roll.update_text()
	# Legacy self-applies damage + announces via these signals; the rework monster (data
	# set) lets the FSM resolve and apply to Combatants HP, so the lean one skips them
	# (otherwise it'd double-apply with _apply_attack).
	if not data:
		GlobalSignal.player_attacked.connect(monster_hit)
		GlobalSignal.monster_atack_finished.connect(_announce_attack)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Clears the registry ref on free, guarded so a respawn's new monster isn't clobbered.
func _exit_tree() -> void:
	super()
	if Combatants.monster == self:
		Combatants.monster = null


# Pulls static fields from the MonsterResource when one is assigned (rework path).
# Legacy scenes leave `data` null and keep their baked @export fields.
func _load_data() -> void:
	if not data:
		return
	monster_name = data.monster_name
	pattern_list = data.pattern_list
	if hp:
		hp.max_hp = data.max_hp
		hp.current_hp = data.max_hp

func round_start():
	super()
	update_roll()          # round uses the current pattern...
	current_round += 1     # ...then advance for next round

func update_roll():
	CurrentRoll.current_monster_roll_list[RollIndex.BASE] = current_pattern.base
	CurrentRoll.current_monster_roll_list[RollIndex.MULT] = current_pattern.mult
	CurrentRoll.current_monster_roll_list[RollIndex.ANTI] = current_pattern.anti
	CurrentRoll.current_monster_roll_list[RollIndex.ANTI_TYPE] = current_pattern.anti_type
	CurrentRoll.next_pattern = pattern_list[(current_round + 1) % pattern_list.size()]
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
