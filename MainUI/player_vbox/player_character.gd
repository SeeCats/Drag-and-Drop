extends Character
class_name PlayerCharacter

# Lean player entity for the rework: just HP + round_participants membership + Combatants
# registration. The fat player_vbox scene and its rotate/swap/dice-roll/preview bridge were
# retired 2026-06-30, so this script no longer carries any of that.


func _ready() -> void:
	super()
	Combatants.player = self


func _exit_tree() -> void:
	super()
	if Combatants.player == self:
		Combatants.player = null
