extends Rollables

@onready var zone1 = $Zone1
@onready var zone2 = $Zone2
@onready var zone3 = $Zone3
@onready var dice1: Dice = $Zone1/CenterContainer/Dice
@onready var dice2: Dice = $Zone2/CenterContainer/Dice
@onready var dice3: Dice = $Zone3/CenterContainer/Dice


@onready var dice_list : Array[Dice] = [dice1, dice2, dice3]
@onready var zone_list = [zone1, zone2, zone3]

signal dice_swapped(values: Array[int], elements: Array[Constants.Element])

var swap_started : Array[bool] = [false, false, false]
var swap_ended: Array[bool] = []
var mouse_is_inside: Array[bool] = [false, false, false]

var element_index_list : Array[Constants.Element] = [
	Element.RED,
	Element.GREEN,
	Element.BLUE,
]
var dice_roll_list : Array[int]= []

@export var round_start_priority : int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("round_participants")
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
	mouse_is_inside = [zone1.is_inside, zone2.is_inside, zone3.is_inside]

	if event.pressed and mouse_is_inside.has(true) and not swap_started.has(true):
		var idx = mouse_is_inside.find(true)
		zone_list[idx].swap_started_true()
		swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
		dice_list[idx].swapping = true
		get_viewport().set_input_as_handled()

	if not event.pressed:
		swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]
		if swap_started.has(true) and mouse_is_inside.has(true) and not (swap_started.find(true) == mouse_is_inside.find(true)):
			zone_list[mouse_is_inside.find(true)].swap_ended_true()
			swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]
			swap()
			swapping_false()
			false_zone_list()
			get_viewport().set_input_as_handled()
		else:
			swapping_false()
			false_zone_list()


# Called when dice locations swap
func swap():
	if swap_started.has(true) and swap_ended.has(true):
		var i = swap_started.find(true)
		var j = swap_ended.find(true)
		var i_parent = dice_list[i].get_parent()
		var j_parent = dice_list[j].get_parent()
		dice_list[i].roll()
		dice_list[i].reparent(j_parent)
		dice_list[j].reparent(i_parent)
		swap_element(dice_list, i, j)
		false_zone_list()
		dice_roll_list.assign(dice_list.map(func(d): return d.current_roll))
		element_index_list.assign(dice_list.map(func(d): return d.element))
		emit_signal("dice_swapped", dice_roll_list, element_index_list)
		print("swap done")
		GlobalSignal.updated_roll.emit()
		CombatState.end_player_turn()
		
	
# Called when summing array
func sum(array: Array):
	var sum_of_array = 0
	for elements in array:
		sum_of_array += elements
	return sum_of_array


# Called when swapping elements in an array
func swap_element(array : Array, i: int, j:int):
	var temp = array[i]
	array[i] = array[j]
	array[j] = temp


func roll_dice_list():
	for i in dice_list:
		i.roll()


func false_zone_list():
	zone1.swap_started = false
	zone2.swap_started = false
	zone3.swap_started = false
	zone1.swap_ended = false
	zone2.swap_ended = false
	zone3.swap_ended = false
	swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
	swap_ended = [zone1.swap_ended, zone2.swap_ended, zone3.swap_ended]


func _exit_tree() -> void:
	pass

	
func round_start():
	roll_dice_list()
	dice_roll_list.assign(dice_list.map(func(d): return d.current_roll))
	element_index_list.assign(dice_list.map(func(d): return d.element))
	emit_signal("dice_swapped", dice_roll_list, element_index_list)

func swapping_false():
	for i in dice_list:
		i.swapping = false
