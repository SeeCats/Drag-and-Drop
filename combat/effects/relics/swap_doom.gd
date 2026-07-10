extends Effect

# Doom clock (debuff): committing `clock_action` ticks it down; the commit that reaches 0
# DETONATES for `damage` to the player, then re-arms. The verb-priced bomb: swap stays
# the gamble verb, and this counts your gambles. Deterministic → the staged detonation
# previews as "· -N hp" on the DEAL sub (exactness pillar). Dying to it is caught by the
# FSM's _advance at the next boundary, like every other decoupled death.

@export var damage : int = 10
@export var cooldown : int = 10          # qualifying commits per detonation
@export var clock_action : String = "swap"
@export var current_cooldown : int = 0   # ticks remaining; author the start in the .tres


func effect(event: GameEvent) -> bool:
	if event.trigger != Effect.Trigger.COMMIT:
		return false
	var c : CommitEvent = event
	var before : int = current_cooldown
	var cd_after : int = current_cooldown
	if (clock_action == "" or c.action.get("type", "") == clock_action) and cd_after > 0:
		cd_after -= 1
	var detonates : bool = cd_after == 0
	if detonates:
		c.hp_delta -= damage
	if not c.dry:
		current_cooldown = cooldown if detonates else cd_after
	return detonates or current_cooldown != before


func state_readout() -> String:
	return str(current_cooldown)
