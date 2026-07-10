extends Effect

# "Reroll the lowest die at turn start" — POST_ROLL op on the freshly rolled hand.
# First slot wins ties. The op enters the reroll record (REROLLED reactions see it).

func effect(event: GameEvent) -> bool:
	var e : RollEvent = event
	var worst : int = 0
	for i in range(1, e.values.size()):
		if e.values[i] < e.values[worst]:
			worst = i
	e.reroll_slot(worst)
	return true
