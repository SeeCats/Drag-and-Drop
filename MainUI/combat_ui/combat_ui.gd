extends Control

# AD HOC (temporary): autoloads (CombatState/CurrentRoll) persist across scene
# reloads, so after a loss the FSM stays stuck in LOSE and the round never
# restarts. Kicking start() here on combat load works for now.
# TODO: replace with a proper scene-start / run-reset flow.
func _ready() -> void:
	CombatState.start()
