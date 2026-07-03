extends Rollables
class_name Character

# Base combatant: an Hp ref + round_participants membership so the FSM can
# round_start() it and read its HP through Combatants.

@export var hp : Hp
@export var round_start_priority : int = 100


func _ready() -> void:
	add_to_group("round_participants")


func _exit_tree() -> void:
	pass  # subclasses super() this before their own cleanup


func round_start():
	pass  # subclasses override (e.g., monster advances its pattern)
