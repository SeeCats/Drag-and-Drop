extends Control

# Spawns the monster chosen by Encounter.next_monster into this slot.
# Sibling UI (Anouncement, DamageNumberZone) stays put; only the monster swaps.
func _ready() -> void:
	var monster := Encounter.next_monster.instantiate()
	add_child(monster)
	move_child(monster, 0)   # render behind the overlay UI
	if monster is Control:
		monster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
