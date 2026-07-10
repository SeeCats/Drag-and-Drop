extends Effect

# "Committing [condition_action] heals" — COMMIT reaction. Accumulates onto the event;
# the seam applies clamped and logs the actual delta (rotate_heal = condition "rotate").

@export var heal : int = 10

func effect(event: GameEvent) -> bool:
	var e : CommitEvent = event
	e.hp_delta += heal
	return heal != 0
