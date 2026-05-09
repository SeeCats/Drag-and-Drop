extends Line2D

@export var max_point : int = 10
var point_list : Array
@export var ratio : float = 0.2
var curve =Curve2D.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("click"):
		point_list.append(get_global_mouse_position())
		if point_list.size() > max_point:
			point_list.remove_at(0)
	elif point_list.size() !=0:
		point_list.remove_at(0)
	curve.clear_points()
	for i in point_list.size()-1:
		var current_point = point_list[i]
		var previous_point = point_list[max(0,i -1)]
		var next_point = point_list[min(point_list.size(), i+1)]
		var out_point = (next_point - current_point) * ratio
		var in_point = (current_point -previous_point) * ratio 
		curve.add_point(current_point, -out_point, -in_point)
	
	points = curve.get_baked_points()
		
	pass
