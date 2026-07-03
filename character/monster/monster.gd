extends Character
class_name Monster

@export var monster_name : String = "Slime"
@export var data : MonsterResource   # static authored data; the spawner sets it before add_child
var current_round : int:
	set(new_value):
		current_round = new_value
		current_pattern = pattern_list[current_round % pattern_list.size()]
@export var pattern_list : Array[Pattern]
var current_pattern : Pattern


# Registers with Combatants, loads the resource data, and publishes round 1's roll.
func _ready() -> void:
	super()
	Combatants.monster = self
	_load_data()
	hp.label.set("monster_name", monster_name)   # name shows on this monster's HP bar only
	current_pattern = pattern_list[current_round]
	update_roll()


# Clears the registry ref on free, guarded so a respawn's new monster isn't clobbered.
func _exit_tree() -> void:
	super()
	if Combatants.monster == self:
		Combatants.monster = null


# Pulls static fields from the MonsterResource when one is assigned; null keeps the
# @export defaults (e.g. a Monster.tscn instanced raw in the editor).
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


# Publishes this round's roll + the lookahead pattern, then pings the UI.
func update_roll():
	CurrentRoll.current_monster_roll_list[RollIndex.BASE] = current_pattern.base
	CurrentRoll.current_monster_roll_list[RollIndex.MULT] = current_pattern.mult
	CurrentRoll.current_monster_roll_list[RollIndex.ANTI] = current_pattern.anti
	CurrentRoll.current_monster_roll_list[RollIndex.ANTI_TYPE] = current_pattern.anti_type
	CurrentRoll.next_pattern = pattern_list[(current_round + 1) % pattern_list.size()]
	GlobalSignal.updated_roll.emit()
