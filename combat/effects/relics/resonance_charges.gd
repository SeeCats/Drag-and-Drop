extends Effect

# "Resonance": at commit, +1 charge per die sitting on its HOME slot (capped). When ALL
# dice are off-home, the projected roll's MULT gains every charge — and the real commit
# spends them (always spend, reset to 0). Two moments, one relic: triggers = COMMIT +
# PROJECT_ROLL. State mutations are dry-guarded: previews read charges, never change them.

@export var cap : int = 3
var charges : int = 0   # per-instance state; survives round to round on the duplicated resource

const HOME := [0, 1, 2]   # authored column elements: RED, GREEN, BLUE (model A)


func effect(event: GameEvent) -> bool:
	if event.trigger == Effect.Trigger.PROJECT_ROLL:
		var p : ProjectRollEvent = event
		if _home_count(p.elements) == 0 and charges > 0:
			p.roll[Rollables.RollIndex.MULT] += charges   # the spend, visible to preview + publish alike
			return true
		return false
	if event.trigger == Effect.Trigger.COMMIT:
		if event.dry:
			return false   # dry-dispatch law: previews must not touch effect state
		var c : CommitEvent = event
		if _home_count(c.elements) == 0:
			var had : int = charges
			charges = 0   # the boost was projected at publish; now it's consumed
			return had > 0
		var before : int = charges
		charges = mini(charges + _home_count(c.elements), cap)
		return charges != before
	return false


func state_readout() -> String:
	return str(charges)


# How many dice sit on their home slot (element matches the authored column element).
func _home_count(elements: Array) -> int:
	var n : int = 0
	for i in elements.size():
		if elements[i] == HOME[i]:
			n += 1
	return n
