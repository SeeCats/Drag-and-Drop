extends Label

var max_value : int:
	set(new_value):
		max_value = new_value
		text = "%d / %d" % [max_value, current_value ]
var current_value : int:
	set(new_value):
		current_value = new_value
		text = "%d / %d" % [max_value, current_value ]




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "%d / %d" % [max_value, current_value ]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
