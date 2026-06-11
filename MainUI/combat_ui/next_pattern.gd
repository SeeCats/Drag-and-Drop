extends Label

# Lookahead hint: shows the monster's next roll. Type/role is conveyed by the
# halo color instead. anti_type picks the defense label: BASE->Block, MULT->Miss.

func _ready() -> void:
	GlobalSignal.updated_roll.connect(_update)
	_update()

func _update() -> void:
	var p: Pattern = CurrentRoll.next_pattern
	if not p:
		text = "—"
		return
	var defense := "Block" if p.anti_type == Constants.RollIndex.BASE else "Miss"
	text = "NEXT\nBase: %d  Mult: %d  %s: %d" % [p.base, p.mult, defense, p.anti]
