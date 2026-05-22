extends Control
class_name mouse

var mouse_pointer

func _ready():
	GlobalSignal.swap_started.connect(on_swap_mouse)

func on_swap_mouse(dice:Dice):
	dice.reparent(self)
	dice.label.text = "?"
	mouse_pointer.global_position = get_global_mouse_position() + mouse_pointer.size/2
	pass


func _exit_tree() -> void:
	GlobalSignal.swap_started.disconnect(on_swap_mouse)

func release(child):
	if Input.is_action_just_released("click"):
		child.queue_free()
		
func follow_mouse(dice: Dice):
	dice.global_position = get_global_mouse_position() + mouse_pointer.size/2
