extends Control

# Spawns the monster chosen by Encounter.next_monster into this slot.
# Sibling UI (Anouncement, DamageNumberZone) stays put; only the monster swaps,
# so the player (and its HP) survives a gauntlet advance.

var _current: Node

func _ready() -> void:
	add_to_group("monster_spawner")
	_spawn()

func _spawn() -> void:
	_current = Encounter.next_monster.instantiate()
	add_child(_current)
	move_child(_current, 0)   # render behind the overlay UI
	if _current is Control:
		_current.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# Free the defeated monster and spawn the next; the player is untouched.
func respawn() -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	_spawn()
