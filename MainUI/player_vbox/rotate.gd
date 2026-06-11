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

@onready var _player := get_parent() as PlayerCharacter
var _last_preview_tgt := -2


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


# Live hover preview: while rotating, push the hypothetical (deterministic).
func _process(_delta: float) -> void:
	var started := [zone1.swap_started, zone2.swap_started, zone3.swap_started]
	if not started.has(true):
		if _last_preview_tgt != -2:
			_last_preview_tgt = -2
			GlobalSignal.preview_clear.emit()
		return
	var src: int = started.find(true)
	var inside := [zone1.is_inside, zone2.is_inside, zone3.is_inside]
	var tgt: int = inside.find(true)
	if tgt == src:
		tgt = -1
	if tgt == _last_preview_tgt:
		return
	_last_preview_tgt = tgt
	if tgt == -1:
		GlobalSignal.preview_clear.emit()
	else:
		GlobalSignal.preview_set.emit(_player.preview_rotate(src, tgt))


func _input(event: InputEvent) -> void:
	if CombatState.current_state != CombatState.State.PLAYER_PLANNING:
		return   # only rotate during planning
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
	mouse_is_inside = [zone1.is_inside, zone2.is_inside, zone3.is_inside]

	if event.pressed and mouse_is_inside.has(true) and not swap_started.has(true):
		var idx = mouse_is_inside.find(true)
		zone_list[idx].swap_started_true()
		swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
		get_viewport().set_input_as_handled()

	if not event.pressed:
		swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]
		if swap_started.has(true) and mouse_is_inside.has(true) and not (swap_started.find(true) == mouse_is_inside.find(true)):
			zone_list[mouse_is_inside.find(true)].swap_ended_true()
			swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]
			rotate()
			get_viewport().set_input_as_handled()
		else:
			false_zone_list()


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
