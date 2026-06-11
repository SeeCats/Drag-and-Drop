extends Label

# Shared readout: PREVIEW (live outcome of the current/hovered arrangement) or
# LOG (combat announcements). A horizontal swipe started on this label toggles
# them. Hover hypotheticals arrive via preview_set / preview_clear.

@export var max_length : int = 4
var combat_log_list : Array[String]

enum Mode { PREVIEW, LOG }
var mode := Mode.PREVIEW
var preview_str := ""
var drag_start_pos : Vector2

func _ready() -> void:
	GlobalSignal.announced.connect(announce)
	# Deferred so the player roll (also an updated_roll handler) refreshes first.
	GlobalSignal.updated_roll.connect(_update_preview, CONNECT_DEFERRED)
	GlobalSignal.preview_set.connect(_on_preview_set)    # hover hypothetical
	GlobalSignal.preview_clear.connect(_update_preview)  # back to committed
	_update_preview()

func _update_preview() -> void:
	var o: Dictionary = CurrentRoll.compute_outcome(CurrentRoll.current_roll_list, CurrentRoll.current_monster_roll_list)
	preview_str = "Deal %d    Take %d" % [o.player.total, o.monster.total]
	_refresh()

func _on_preview_set(preview: String) -> void:
	preview_str = preview
	_refresh()

func announce(announcement : String) -> void:
	combat_log_list.push_front(announcement)
	if combat_log_list.size() > max_length:
		combat_log_list.pop_back()
	_refresh()

func _refresh() -> void:
	text = preview_str if mode == Mode.PREVIEW else "\n".join(combat_log_list)

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		drag_start_pos = get_global_mouse_position()
	elif get_global_rect().has_point(drag_start_pos) and absf(get_global_mouse_position().x - drag_start_pos.x) >= 50:
		mode = Mode.LOG if mode == Mode.PREVIEW else Mode.PREVIEW
		_refresh()
