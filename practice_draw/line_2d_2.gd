extends Line2D

var curve = Curve2D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in points:
		curve.add_point(i)
	points = curve.get_baked_points()
	print(points)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


	
