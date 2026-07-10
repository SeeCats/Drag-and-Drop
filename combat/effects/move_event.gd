extends GameEvent
class_name MoveEvent

# Gate question (ADR-003): may this verb happen? Effects veto by setting allowed = false.
# The seam (controller) narrates and logs denials; input just asks.

var verb : String = ""
var allowed : bool = true


func _conditions_pass(e: Effect) -> bool:
	return e.condition_verb == "" or e.condition_verb == verb
