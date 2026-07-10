extends Effect

# "When a [condition_element] die is rerolled, deal damage to the monster" — REROLLED
# reaction. Accumulates onto the event per matching reroll instance; the seam applies.
# condition_include_base = true also counts the fresh-hand roll (fires ~every round —
# balance accordingly; the OP-but-intended original reading, now authorable).

@export var damage_per_reroll : int = 4

func effect(event: GameEvent) -> bool:
	var e : RollEvent = event
	var hits : int = e.matching_rerolls(condition_element, condition_include_base).size()
	e.monster_damage += hits * damage_per_reroll
	return hits > 0
