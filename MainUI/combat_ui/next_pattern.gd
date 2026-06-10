extends Label

# Lookahead hint: shows the ROLE (Type) of the monster's next pattern.
# Reads CurrentRoll.next_pattern (published by monster.update_roll) — the type
# is authored on the Pattern resource, not inferred from the numbers.

func _ready() -> void:
	GlobalSignal.updated_roll.connect(_update)
	_update()

func _update() -> void:
	var p: Pattern = CurrentRoll.next_pattern
	text = "Next: " + (Pattern.Type.keys()[p.type].capitalize() if p else "—")
