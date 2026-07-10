extends Effect

# "The current highest die skips its reroll" — PRE_ROLL mask transform. Highest is judged
# on live pre-roll values (last round's end hand); first slot wins ties.

func effect(event: GameEvent) -> bool:
	var e : RollEvent = event
	var best : int = 0
	for i in range(1, e.values.size()):
		if e.values[i] > e.values[best]:
			best = i
	e.base_mask[best] = false
	return true
