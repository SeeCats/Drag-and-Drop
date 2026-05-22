extends Control
class_name Zone

var is_inside : bool = false
var swap_started : bool = false :
	set(new_value):
		swap_started = new_value
		print(self.name," set swap_started ", swap_started)
var swap_ended : bool = false :
	set(new_value):
		swap_ended = new_value
		print(self.name ," set swap_ended", swap_ended)
@export_enum("R", "G", "B", "W") var element : int
@onready var label: Label = $Label


var pointlist :PackedVector2Array = [
	Vector2(0,-34.5),
	Vector2(30,-17.25),
	Vector2(30,17.25),
	Vector2(0,34.5),
	Vector2(-30,17.25),
	Vector2(-30,-17.25)
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(self.name,global_position,)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func swap_started_true():
	swap_started = true


func swap_ended_true():
	swap_ended = true


func _on_mouse_exited() -> void:
	is_inside = false
	print("Mouse exited ", self.name)
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	is_inside = true
	print("Mouse entered ", self.name)
	pass # Replace with function body.
