extends Effect

# Clocked blast: commits tick the cooldown down ("" clock_action = every commit; "swap"
# etc. = only that verb); the commit that reaches 0 fires `damage` at the monster and
# resets to max — tick→0→fire→max, forever. Single trigger (COMMIT): clock and proc share
# the moment; dry previews simulate tick+proc without state. Starting charge is authored
# via the exported state (current_cooldown in the .tres) — project convention.

@export var damage : int = 10
@export var cooldown : int = 10          # qualifying commits per proc
@export var clock_action : String = ""   # "" = any commit ticks; "swap"/"rotate"/"pass" = that verb only
@export var current_cooldown : int = 0   # ticks remaining; author the start in the .tres


func effect(event: GameEvent) -> bool:
	if event.trigger != Effect.Trigger.COMMIT:
		return false
	var c : CommitEvent = event
	var before : int = current_cooldown
	var cd_after : int = current_cooldown
	if (clock_action == "" or c.action.get("type", "") == clock_action) and cd_after > 0:
		cd_after -= 1
	var procs : bool = cd_after == 0
	if procs:
		c.monster_damage += damage
	if not c.dry:
		current_cooldown = cooldown if procs else cd_after
	return procs or current_cooldown != before


func state_readout() -> String:
	return str(current_cooldown)
