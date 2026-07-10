extends RefCounted
class_name GameEvent

# Transient dispatch envelope (ADR-003). Deliberately NOT a Resource — events are runtime
# instances, never authored data. Two laws: events are consumed during dispatch and never
# stored (log copies, not references); effects never hold references to events (RefCounted
# has no cycle collector).

var trigger : Effect.Trigger
var dry : bool = false   # preview dispatch: effects must not touch their OWN state when set
var acted : Array = []   # dispatcher-filled: one {relic, trigger} per effect that fired


# The event judges (ADR-003): is the effect tuned to this moment (bit-test against its
# triggers mask) + whatever declared conditions this event type understands.
func matches(e: Effect) -> bool:
	return (e.triggers & (1 << trigger)) != 0 and _conditions_pass(e)


func _conditions_pass(_e: Effect) -> bool:
	return true
