extends Node
class_name Character

@export var hp : Hp = Hp.new()
@export var evasion : int = 0
@export var armor : int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.round_started.connect(round_start)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _exit_tree() -> void:
	GlobalSignal.round_started.disconnect(round_start)

func round_start():
	pass

func die():
	pass
