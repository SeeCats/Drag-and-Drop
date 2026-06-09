extends Label

# HP readout, optionally prefixed with a monster name. The monster sets
# `monster_name` on its OWN label directly (see monster.gd); the player's label
# leaves it empty, so it just shows "cur / max".
var max_value : int:
	set(new_value):
		max_value = new_value
		_refresh()
var current_value : int:
	set(new_value):
		current_value = new_value
		_refresh()
var monster_name : String:
	set(new_value):
		monster_name = new_value
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if monster_name.is_empty():
		text = "%d / %d" % [current_value, max_value]
	else:
		text = "%s %d / %d" % [monster_name, current_value, max_value]
