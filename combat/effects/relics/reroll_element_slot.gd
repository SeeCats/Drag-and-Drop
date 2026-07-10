extends Effect

# "The slot holding [condition_element] always rerolls" — POST_ROLL op; the element comes
# from the declared condition field (data-configured: one script, any element via .tres).

func effect(event: GameEvent) -> bool:
	var e : RollEvent = event
	var did : bool = false
	for i in e.elements.size():
		if e.elements[i] == condition_element:
			e.reroll_slot(i)
			did = true
	return did
