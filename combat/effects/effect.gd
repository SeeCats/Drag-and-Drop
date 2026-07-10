extends Resource
class_name Effect

# One relic/status (ADR-003): declared trigger + typed conditions + a payload. The EVENT
# judges whether this effect applies (event.matches(effect)); game code never names an
# effect. Simple effects are data-configured .tres on a template script; only novel
# payloads need new scripts.

enum Trigger {
	PRE_ROLL,      # before the planning-entry base roll — edit the roll mask (RollEvent)
	POST_ROLL,     # after the base roll — perform reroll ops on live values (RollEvent)
	REROLLED,      # react to the reroll instance record (RollEvent)
	MOVE_GATE,     # may this verb happen? veto by event.allowed = false (MoveEvent)
	COMMIT,        # the turn was committed with an action (CommitEvent)
	PROJECT_ROLL,  # dice -> roll projection; modify the roll (ProjectRollEvent, ALWAYS dry)
}

@export var id : String = ""                 # log tag; shows in run_log "events" + the trace
# Which moments this effect listens to — a BITMASK so one effect (e.g. a charge relic) can
# tune to several. Bit n = enum Trigger value n; event.matches tests (triggers & 1 << event.trigger).
@export_flags("Pre Roll", "Post Roll", "Rerolled", "Move Gate", "Commit", "Project Roll")
var triggers : int = 0
@export var duration : int = 0               # 0 = permanent relic; >0 = status, ticks down per planning phase, self-removes at 0

# Declared conditions, typed on purpose (no string DSL — typos should fail at authoring
# time, not silently at runtime). -1 / "" = no condition.
@export var condition_element : int = -1     # Rollables.Element the event entry must have
@export var condition_verb : String = ""     # MOVE_GATE: "swap" / "rotate"
@export var condition_action : String = ""   # COMMIT: "swap" / "rotate" / "pass"
@export var condition_include_base : bool = false   # REROLLED: base-roll instances also count (default: effect ops only)


# Debug-readout hook: stateful effects return their live number (cooldown ticks, charges)
# as a short string; "" = stateless. The controller's planning-phase readout polls it.
func state_readout() -> String:
	return ""


# The payload. Effects mutate the EVENT only (masks, ops, accumulators); the dispatching
# seam applies results to the world and logs actual deltas (ADR-003 law).
# Returns whether the effect actually DID something — matched-but-idle (on cooldown, no
# valid target, nothing to add) returns false and stays out of acted/log/trace-ACTED.
func effect(_event: GameEvent) -> bool:
	return false
