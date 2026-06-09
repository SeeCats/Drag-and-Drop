extends Label

@export var max_length : int = 4
var combat_log_list : Array[String]
var drag_start_pos : Vector2
var drag_end_pos : Vector2
var is_dragging : bool:
	set(new_value):
		is_dragging = new_value
		if not is_dragging:
			var drag_delta = drag_end_pos.x - drag_start_pos.x
			if drag_delta >= 50:
				show()
			elif drag_delta <= -50:
				hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	GlobalSignal.announced.connect(announce)
	
func announce(announcement : String):
	combat_log_list.push_front(announcement)
	if combat_log_list.size() > max_length:
		combat_log_list.pop_back()
	text = "\n".join(combat_log_list)


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		drag_start_pos = get_global_mouse_position()
		print("drag_start_pos = ", drag_start_pos)
		is_dragging = true
		print("Announcement dragging is ", is_dragging)
	else:
		drag_end_pos = get_global_mouse_position()
		print("drag_end_pos = ", drag_end_pos)
		is_dragging = false
		print("Announcement dragging is ", is_dragging)
		
