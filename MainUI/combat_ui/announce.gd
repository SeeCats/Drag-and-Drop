extends Label

@export var max_length : int = 4
var combat_log_list : Array[String]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.announced.connect(announce)
	
func announce(announcement : String):
	combat_log_list.push_front(announcement)
	if combat_log_list.size() > max_length:
		combat_log_list.pop_back()
	text = "\n".join(combat_log_list)
