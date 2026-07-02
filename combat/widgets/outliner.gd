@tool
extends PanelContainer
class_name Outliner

# A PanelContainer that frames its content with a rounded outline + padding, so a
# group of nodes reads as one unit. The border + padding are a StyleBoxFlat built
# in script (no per-instance theme setup needed) and tunable via the exports.
# Drop one in, put content inside; transparent fill by default so it's just a frame.
#
# padding = the gap between the border and the content (StyleBox content margin).

@export var border_color : Color = Color("3e6a52") :
	set(v): border_color = v; _restyle()
@export var border_width : int = 2 :
	set(v): border_width = v; _restyle()
@export var corner_radius : int = 8 :
	set(v): corner_radius = v; _restyle()
@export var padding : int = 10 :
	set(v): padding = v; _restyle()
@export var fill_color : Color = Color(0, 0, 0, 0) :   # transparent — frame only by default
	set(v): fill_color = v; _restyle()

var _rest_border : Color
var _hl_tween : Tween

func _ready() -> void:
	_rest_border = border_color
	_restyle()


# Drop-target shine: pulses the border toward white and back on a loop — same 0.2s
# rhythm as the grabbed die's halo flicker — snapping to the authored color on clear.
# (Color lerp, not modulate — the border is dark, so brightening it actually reads.)
func set_highlight(on: bool) -> void:
	if _hl_tween and _hl_tween.is_valid():
		_hl_tween.kill()
	if not on:
		border_color = _rest_border   # snap back, like the die's halo on release
		return
	var bright := _rest_border.lerp(Color.WHITE, 0.55)
	_hl_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hl_tween.tween_property(self, "border_color", bright, 0.1)
	_hl_tween.tween_property(self, "border_color", _rest_border, 0.1)

func _restyle() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.set_content_margin_all(padding)   # padding between border and content
	add_theme_stylebox_override("panel", sb)
