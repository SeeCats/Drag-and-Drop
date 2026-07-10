extends Node
class_name TrayInput

# Turns tray gestures into controller intents. Two verbs, two gestures (input rework
# 2026-07-06; supersedes the knob flick — knob is display-only now):
#   swap   = tap one die, then tap another (first-tapped lands on the second + rerolls)
#   rotate = drag a die onto another slot (the row cycles so the dragged die lands there)

@onready var controller : CombatRework = owner as CombatRework
@onready var slots : Array[DiceSlot] = [%BaseSlot, %MultSlot, %AntiSlot]

@export var drag_threshold : float = 12.0   # px of travel before a press becomes a drag

var _pressed : int = -1        # slot under the current press; -1 = none
var _press_pos : Vector2
var _dragging : bool = false
var _selected : int = -1       # first tap of a staged swap; -1 = none
var _move_done : bool = false  # one swap/rotate per turn; reset on Cancel + each planning phase


# Wires the cancel button and the per-planning-phase reset.
func _ready() -> void:
	var cancel_button : Button = %CancelButton
	cancel_button.pressed.connect(_on_cancel)
	CombatState.state_changed.connect(_on_state_changed)


func _on_cancel() -> void:
	_move_done = false
	_clear_selection()


# Each new planning phase clears the one-move guard + any stale selection; leaving
# planning aborts any gesture still in flight (today only commit can do that, but a
# future effect-driven turn end would otherwise leak a grabbed die).
func _on_state_changed(_from, to) -> void:
	if to == CombatState.State.PLAYER_PLANNING:
		_move_done = false
		_clear_selection()
	else:
		_abort_gesture()


# Drops an in-flight gesture: un-grabs the die, clears marks, forgets the press.
func _abort_gesture() -> void:
	if _dragging and _pressed != -1:
		slots[_pressed].dice.swapping = false
	_dragging = false
	_pressed = -1
	_clear_selection()


# Routes presses/releases to the gesture handlers; motion past drag_threshold
# promotes a held press into a drag.
func _input(event: InputEvent) -> void:
	if CombatState.current_state != CombatState.State.PLAYER_PLANNING:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press()
		else:
			_release()
	elif event is InputEventMouseMotion and _pressed != -1 and not _dragging:
		if _mouse().distance_to(_press_pos) >= drag_threshold:
			_begin_drag()


# Press: remember the slot whose zone contains the press; empty space clears a staged tap.
func _press() -> void:
	if _move_done:
		return
	_press_pos = _mouse()
	_pressed = _slot_at(_press_pos)
	if _pressed == -1:
		_clear_selection()


# Held press moved far enough: it's a drag (rotate gesture). Supersedes a staged tap.
func _begin_drag() -> void:
	_dragging = true
	_clear_selection()
	slots[_pressed].dice.swapping = true
	for i in slots.size():
		slots[i].set_highlight(i != _pressed)   # shine the drop targets


# Release: finish a drag (rotate onto the hovered slot) or count it as a tap.
func _release() -> void:
	if _pressed == -1:
		return
	if _dragging:
		for slot in slots:
			slot.set_highlight(false)
		slots[_pressed].dice.swapping = false
		var tgt : int = _slot_at(_mouse())
		if tgt != -1 and tgt != _pressed:
			controller.request_rotate_to(_pressed, tgt, _mouse())
			_move_done = true
		_dragging = false
	else:
		_tap(_pressed)
	_pressed = -1


# Tap flow: first tap selects (steady border) and shines the valid partners; tapping the
# selected die deselects; tapping a different die commits the swap intent.
func _tap(slot: int) -> void:
	if _selected == -1:
		if not controller.can_swap():
			controller.notify_swap_denied()   # gated verb: owner decides, owner narrates
			return
		_selected = slot
		slots[slot].set_selected(true)
		for i in slots.size():
			if i != slot:
				slots[i].set_highlight(true)
	elif _selected == slot:
		_clear_selection()
	else:
		var first : int = _selected
		_clear_selection()
		controller.request_swap(first, slot)
		_move_done = true


func _clear_selection() -> void:
	_selected = -1
	for slot in slots:
		slot.set_selected(false)
		slot.set_highlight(false)


# Index of the slot whose framed zone (the wrapping Outliner) contains the point, or -1.
# Rect hit-test on raw coordinates — hover signals proved unreliable (an overlay control
# can eat mouse_entered, and TrayInput reads raw _input anyway).
func _slot_at(point: Vector2) -> int:
	for i in slots.size():
		var zone : Control = slots[i].get_parent() as Control
		if zone == null:
			zone = slots[i]
		if zone.get_global_rect().has_point(point):
			return i
	return -1


# Global mouse position (borrowed from a CanvasItem — plain Nodes don't have one).
func _mouse() -> Vector2:
	return slots[0].get_global_mouse_position()
