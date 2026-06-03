extends Label

@export var max_length : int = 4
var combat_log_list : Array[String]
var drag_start_pos : Vector2
var drag_end_pos : Vector2
var is_dragging : bool:
	set(new_value):
		if is_dragging == true and new_value == false and (drag_start_pos.x - drag_end_pos.x) >= 100:
			print("dragged draggeddraggeddraggeddraggeddraggeddraggeddraggeddraggeddraggeddraggeddraggeddragged")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.announced.connect(announce)
	
func announce(announcement : String):
	combat_log_list.push_front(announcement)
	if combat_log_list.size() > max_length:
		combat_log_list.pop_back()
	text = "\n".join(combat_log_list)


func _process(_delta: float) -> void:
	if Input.is_action_pressed("click"):
		is_dragging = true
		print(self, " dragging started")
		drag_start_pos = get_global_mouse_position()
		
	if Input.is_action_just_released("click"):
		is_dragging = false
		print(self, " dragging ended")
		drag_end_pos = get_global_mouse_position()
		
