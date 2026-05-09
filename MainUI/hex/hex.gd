extends Control

@onready var zone1 = $Zone1
@onready var zone2 = $Zone2
@onready var zone3 = $Zone3
@onready var dice1 = $Dice1
@onready var dice2 = $Dice2
@onready var dice3 = $Dice3

@onready var dice_list : Array[Dice] = [dice1, dice2, dice3]
@onready var zone_list = [zone1, zone2, zone3]

@onready var rotate: Rotate = $Rotate


var swap_started : Array[bool] = [false, false, false]
var swap_ended: Array[bool] = []
var mouse_is_inside: Array[bool] = [false, false, false]



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.round_started.connect(round_start)
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
		print("swap started",swap_started)
		print("swap ended", swap_ended)
		swap()
	
	pass


# Called when dice locations swap
func swap():
	if swap_started.has(true) and swap_ended.has(true):
		var i = swap_started.find(true)
		var j = swap_ended.find(true)
		dice_list[i].global_position = zone_list[j].global_position + zone_list[j].size/2 - dice_list[i].size/2
		dice_list[j].global_position = zone_list[i].global_position + zone_list[i].size/2 - dice_list[j].size/2
		swap_element(dice_list, i, j)
		zone1.swap_started = false
		zone2.swap_started = false
		zone3.swap_started = false
		zone1.swap_ended = false
		zone2.swap_ended = false
		zone3.swap_ended = false
		swap_started = [zone1.swap_started, zone2.swap_started, zone3.swap_started]
		swap_ended = [zone1.swap_ended, zone3.swap_ended, zone3.swap_ended]
		print("swap done")
		print("swap started",swap_started)
		print("swap ended", swap_ended)
		update_player_dice()
		
	
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


func update_player_dice():
	var base_index = rotate.action_index_list.find(1)
	print("base_index ", base_index)
	var mult_index = rotate.action_index_list.find(2)
	print("mult_index ", mult_index)
	var anti_index = rotate.action_index_list.find(3)
	print("anti_index ", anti_index)
	CurrentRoll.base = dice_list[base_index].current_roll
	CurrentRoll.mult = dice_list[mult_index].current_roll
	CurrentRoll.anti = dice_list[anti_index].current_roll
	CurrentRoll.anti_type = dice_list[anti_index].element_type
	GlobalSignal.updated_roll.emit()
	print("action index list", rotate.action_index_list)


func roll_dice_list():
	for i in dice_list:
		i.roll()
	

func _on_rotate_rotated() -> void:
	update_player_dice()
	pass # Replace with function body.

func _exit_tree() -> void:
	GlobalSignal.round_started.disconnect(round_start)
	
func round_start():
	roll_dice_list()
	update_player_dice()
