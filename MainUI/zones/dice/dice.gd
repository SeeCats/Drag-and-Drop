extends Control
class_name Dice

@export var max_roll : int = 6
@export var min_roll : int =1
@export var current_roll : int :
	set(new_value):
		current_roll = clamp(new_value, min_roll, max_roll)
		label.text = str(current_roll)
@export var texture : Texture
@export_enum ("R", "G", "B") var element_type : int

@onready var texture_box = $TextureRect
@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_box.texture = texture
	texture_box.modulate = Swatch.ELEMENT_COLOR[element_type as int]
	print(self.name,global_position)
	
	pass # Replace with function body.

func roll():
	current_roll = randi_range(min_roll, max_roll)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
