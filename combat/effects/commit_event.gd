extends GameEvent
class_name CommitEvent

# The turn was committed with an action (ADR-003). Effects ACCUMULATE onto the event; the
# seam applies (clamped, logged) — which also makes the preview free: dispatch the same
# event shape and read the accumulator without applying.

var action : Dictionary = {}
var values : Array[int]  # the committed hand (charge relics read the arrangement)
var elements : Array
var hp_delta : int = 0        # player HP change (heals positive); seam applies + logs actual
var monster_damage : int = 0  # commit-time damage to the monster (blasts); seam applies + logs actual


func _conditions_pass(e: Effect) -> bool:
	return e.condition_action == "" or e.condition_action == action.get("type", "")
