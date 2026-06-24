extends Node
class_name TrayInput

# Turns tray gestures into controller intents: drag a die between slots -> swap,
# flick the knob horizontally -> rotate. Reads each DiceSlot.is_inside for targeting.

@onready var controller : CombatRework = owner as CombatRework
@onready var slots : Array[DiceSlot] = [%BaseSlot, %MultSlot, %AntiSlot]
@onready var knob : Control = %KnobWrap

@export var flick_threshold : float = 24.0   # px of horizontal drag before a flick counts

var _grabbed : int = -1
var _flicking : bool = false
var _flick_start_x : float = 0.0
var _move_done : bool = false   # one swap/rotate per turn; reset on Cancel (and round start, #2)

# Resets the one-move guard when the player cancels.
func _ready() -> void:
	var cancel_button : Button = %CancelButton
	cancel_button.pressed.connect(_on_cancel)

func _on_cancel() -> void:
	_move_done = false

# Routes left mouse press/release to the gesture handlers.
func _input(event: InputEvent) -> void:
	# TODO(#2): gate to CombatState.PLAYER_PLANNING once the FSM drives the rework.
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		_press()
	else:
		_release()

# Press: start a knob flick if over the knob, else grab the hovered die.
func _press() -> void:
	if _move_done:
		return
	if knob.get_global_rect().has_point(knob.get_global_mouse_position()):
		_flicking = true
		_flick_start_x = knob.get_global_mouse_position().x
		return
	_grabbed = _hovered_slot()
	if _grabbed != -1:
		slots[_grabbed].dice.swapping = true

# Release: finish a flick (rotate) or a die drag (swap).
func _release() -> void:
	if _flicking:
		_flicking = false
		var dx : float = knob.get_global_mouse_position().x - _flick_start_x
		if absf(dx) >= flick_threshold:
			controller.request_rotate(1 if dx > 0 else -1)
			_move_done = true
		return
	if _grabbed == -1:
		return
	slots[_grabbed].dice.swapping = false
	var tgt : int = _hovered_slot()
	if tgt != -1 and tgt != _grabbed:
		controller.request_swap(_grabbed, tgt)
		_move_done = true
	_grabbed = -1

# Index of the currently hovered slot, or -1.
func _hovered_slot() -> int:
	for i in slots.size():
		if slots[i].is_inside:
			return i
	return -1
