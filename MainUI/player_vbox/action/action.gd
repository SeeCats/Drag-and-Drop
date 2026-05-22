extends Control

@export_enum ("R", "G", "B", "W") var element_type : int
@export var texture = Texture2D

@onready var textureRect: TextureRect = $CenterContainer/TextureRect
@onready var background: TextureRect = $Background

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background.modulate = Swatch.ELEMENT_COLOR[element_type as int]
	textureRect.texture = texture
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
