extends HBoxContainer

@onready var label1: Label = $Panel/CenterContainer/Label
@onready var label2: Label = $Panel2/CenterContainer/Label
@onready var label3: Label = $Panel3/CenterContainer/Label

var anti_type_list = ["Base", "Mult", "Anti"]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.updated_roll.connect(update_text)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_text():
	print("recieved updated_roll signal")
	label1.text = "Base\n%d" %[CurrentRoll.base]
	label2.text = "Mult\n%d" %[CurrentRoll.mult]
	var anti_type = anti_type_list[CurrentRoll.anti_type]
	label3.text = "Anti\n%s %d" %[anti_type,CurrentRoll.anti]

func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(update_text)
