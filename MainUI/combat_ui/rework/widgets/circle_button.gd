@tool
extends Button
class_name CircleButton
# A Button rendered as a circle — for the few round buttons (cancel / confirm).
# Implemented with a round StyleBoxFlat (corner radius = half the node's size),
# NOT by overriding _draw: this keeps Button's text/icon and hover/pressed/focus
# states intact, and the fill always draws behind the glyph. Regular Button stays
# rectangular, so only nodes that ARE a CircleButton are round.
# Keep the node square (e.g. 62×62) for a true circle; non-square makes a capsule.

@export var fill_color: Color = Color(0, 0, 0, 0):       # transparent by default
	set(v): fill_color = v; _restyle()
@export var border_color: Color = Color("3e6a52"):
	set(v): border_color = v; _restyle()
@export var border_thickness: int = 2:
	set(v): border_thickness = v; _restyle()

func _ready() -> void:
	if not resized.is_connected(_restyle):
		resized.connect(_restyle)   # keep radius = half size as it resizes
	_restyle()

func _restyle() -> void:
	var radius := int(minf(size.x, size.y) * 0.5)
	add_theme_stylebox_override("normal",   _circle(fill_color, border_color, radius))
	add_theme_stylebox_override("hover",    _circle(fill_color, border_color.lightened(0.18), radius))
	add_theme_stylebox_override("pressed",  _circle(fill_color.lightened(0.10), border_color.lightened(0.35), radius))
	add_theme_stylebox_override("focus",    _circle(fill_color, border_color, radius))
	add_theme_stylebox_override("disabled", _circle(fill_color, border_color.darkened(0.4), radius))

func _circle(bg: Color, bord: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bord
	sb.set_border_width_all(border_thickness)
	sb.set_corner_radius_all(radius)
	return sb
