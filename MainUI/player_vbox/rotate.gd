extends Rollables
class_name Rotate

var is_rotating :bool = false
@onready var zone1: Zone = $Zone1
@onready var zone2: Zone = $Zone2
@onready var zone3: Zone = $Zone3
@onready var zone_list = [zone1, zone2, zone3]
@onready var action1: Control = $Zone1/CenterContainer/Action1
@onready var action3: Control = $Zone3/CenterContainer2/Action3
@onready var action2: Control = $Zone2/CenterContainer2/Action2
@onready var action_list = [action1, action2, action3]


var action_index_list : Array[Constants.RollIndex] = [
	RollIndex.BASE,
	RollIndex.MULT,
	RollIndex.ANTI
]
var swap_started : Array[bool] = [false, false, false]
var swap_ended: Array[bool] = []
var mouse_is_inside: Array[bool] = [false, false, false]

signal actions_rotated(new_list: Array[Constants.RollIndex])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
	swap_ended = [zone1.swap_ended, zone3.swap_ended, zone3.swap_ended]
	mouse_is_inside = [zone1.is_inside, zone2.is_inside, zone3.is_inside]
	if Input.is_action_pressed("click") && mouse_is_inside.has(true) && !swap_started.has(true):
		zone_list[mouse_is_inside.find(true)].swap_started_true()
		swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
		
	if Input.is_action_just_released("click") && swap_started.has(true) && mouse_is_inside.has(true) && ! (swap_started.find(true) == mouse_is_inside.find(true)) :
		zone_list[mouse_is_inside.find(true)].swap_ended_true()
		swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]
		print("rotate started",swap_started)
		print("rotate ended", swap_ended)
		rotate()


# Called when rotating the position of actions
func rotate():
	if swap_started.has(true) and swap_ended.has(true):
		var i = swap_started.find(true)
		var j = swap_ended.find(true)
		var k = (3- i -j) % 3 
		var i_parent = action_list[i].get_parent()
		var j_parent = action_list[j].get_parent()
		var k_parent = action_list[k].get_parent()
		action_list[i].reparent(j_parent)
		action_list[j].reparent(k_parent)
		action_list[k].reparent(i_parent)
		rotate_element(action_list, i, j, k)
		false_zone_list()
		GlobalSignal.updated_roll.emit()
		CombatState.end_player_turn()


# Called when summing an array
func sum(array: Array):
	var sum_of_array = 0
	for elements in array:
		sum_of_array += elements
	return sum_of_array

# Called when rotating the elements of arrays
func rotate_element(array : Array, i: int, j:int, k:int):
	var temp = array[k]
	array[k] = array[j]
	array[j] = array[i]
	array[i] = temp
	var temp2 = action_index_list[k]
	action_index_list[k] = action_index_list[j]
	action_index_list[j] = action_index_list[i]
	action_index_list[i] = temp2
	emit_signal("actions_rotated", action_index_list)
	print("action index list", action_index_list)

func false_zone_list():
	zone1.swap_started = false
	zone2.swap_started = false
	zone3.swap_started = false
	zone1.swap_ended = false
	zone2.swap_ended = false
	zone3.swap_ended = false
	swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
	swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]
