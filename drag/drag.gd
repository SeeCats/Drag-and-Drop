extends Control
class_name Drag

var is_draggable : bool = false
var initial_position : Vector2
var swap_position : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(self.name," is ready")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("click"):
		self.global_position = get_global_mouse_position() -size/2
	if Input.is_action_just_released("click"):
		self.global_position = initial_position
		
	pass


func _on_mouse_entered() -> void:
	initial_position = self.global_position
	is_draggable = true
	print("draggable")
	pass # Replace with function body.



func _on_mouse_exited() -> void:
	is_draggable = false
	print("not draggable")
	pass # Replace with function body.
