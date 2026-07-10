extends Effect

# Cooldown template: "when effect-rerolls happen, strike the monster — then recharge for
# N clock ticks." Proc on REROLLED; clock on COMMIT (exactly one commit ends every round,
# pass included, so COMMIT = the round clock). condition_action can narrow the clock to a
# verb ("swap" → cools only when you swap). Cooldown state is per-instance, dry-guarded.

@export var damage : int = 12
@export var cooldown : int = 5   # clock ticks until ready again

# Runtime state as an export = the CONVENTION for authored starting state: the .tres
# value is the start, duplicate() gives each instance its own copy. Literal default on
# purpose — `= cooldown` only worked while declared below it (order-fragile).
@export var current_cooldown : int = 0   # 0 = ready; author the start in the .tres


func effect(event: GameEvent) -> bool:
	match event.trigger:
		Effect.Trigger.REROLLED:             # the proc moment
			var e : RollEvent = event
			if current_cooldown > 0 or e.rerolled.is_empty():
				return false                  # on cooldown, or nothing actually rerolled
			e.monster_damage += damage
			current_cooldown = cooldown                    # roll-seam dispatches are real, never dry — safe write
			return true
		Effect.Trigger.COMMIT:                # the clock
			if event.dry or current_cooldown == 0:
				return false                  # previews never tick; ticking at 0 is not an action
			current_cooldown -= 1
			return true
	return false
