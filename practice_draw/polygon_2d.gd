extends Polygon2D

@export var radius : float = 60
@export var vertice_number : int =6
@warning_ignore("shadowed_variable_base_class")
@onready var tail: Polygon2D = $Tail


func get_vertice():
	var circular_sector_angle = 2 * PI / vertice_number
	var vertice_point_list : PackedVector2Array
	for i in vertice_number:
		var x = radius * cos(circular_sector_angle * i)
		var y = radius * sin(circular_sector_angle * i)
		vertice_point_list.push_back( Vector2(y, x) )
		polygon = vertice_point_list
		
func get_tail():
	tail.polygon = [
		polygon[3],
		polygon[2],
		polygon[1],
		polygon[1] + polygon[2] * 3 ,
	]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_vertice()
	get_tail()
	print(polygon)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
