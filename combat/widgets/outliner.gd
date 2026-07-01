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

func _ready() -> void:
	_restyle()

func _restyle() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.set_content_margin_all(padding)   # padding between border and content
	add_theme_stylebox_override("panel", sb)
