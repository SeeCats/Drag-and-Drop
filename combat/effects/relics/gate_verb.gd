extends Effect

# Denies a verb while active (condition_verb picks which; a duration makes it a status —
# e.g. swap-lock = condition_verb "swap", duration 2).

func effect(event: GameEvent) -> bool:
	var e : MoveEvent = event
	e.allowed = false
	return true
