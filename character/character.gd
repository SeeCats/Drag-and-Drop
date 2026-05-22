extends Rollables
class_name Character

@export var hp : Hp
@export var round_start_priority : int = 100
var alive : bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CombatState.state_entered.connect(_on_state_entered)
	add_to_group("round_participants")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _exit_tree() -> void:
	if CombatState.state_entered.is_connected(_on_state_entered):
		CombatState.state_entered.disconnect(_on_state_entered)

func _on_state_entered(_state):
	pass  # subclasses override (e.g., monster handles MONSTER_ATTACK)

func round_start():
	pass

func die():
	alive = false
	pass
