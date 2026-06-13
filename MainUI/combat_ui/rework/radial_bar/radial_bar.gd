@tool
extends Control
class_name RadialBar

# Circular/radial progress bar (ui-spec — monster scouter ring + knob HP halo).
# A full track ring, a bright `value` arc, and an optional dim `secondary` arc drawn right after it

@export var max_value: float = 100.0:
	set(v): max_value = maxf(v, 0.001); queue_redraw()
@export var value: float = 70.0:               # bright arc
	set(v): value = v; queue_redraw()
@export var secondary: float = 0.0:            # dim arc, drawn after `value` (e.g. at-risk HP)
	set(v): secondary = v; queue_redraw()
@export var thickness: float = 10.0:
	set(v): thickness = v; queue_redraw()
@export var start_angle_deg: float = -90.0:    # -90 = 12 o'clock
	set(v): start_angle_deg = v; queue_redraw()
@export var clockwise: bool = true:
	set(v): clockwise = v; queue_redraw()
@export var value_color: Color = Color("3fae6a"):     # monster-green default
	set(v): value_color = v; queue_redraw()
@export var secondary_color: Color = Color("2a4d4d"): # dim at-risk
	set(v): secondary_color = v; queue_redraw()
@export var track_color: Color = Color("1c2c22"):     # empty ring
	set(v): track_color = v; queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - thickness / 2.0
	if radius <= 0.0:
		return
	var start := deg_to_rad(start_angle_deg)
	var dir := 1.0 if clockwise else -1.0
	var frac_v := clampf(value / max_value, 0.0, 1.0)
	var frac_s := clampf(secondary / max_value, 0.0, 1.0 - frac_v)
	# track (full ring)
	draw_arc(center, radius, start, start + dir * TAU, 96, track_color, thickness, true)
	# secondary (at-risk) — sits between value's end and the track
	if frac_s > 0.0:
		var s0 := start + dir * frac_v * TAU
		draw_arc(center, radius, s0, s0 + dir * frac_s * TAU, 96, secondary_color, thickness, true)
	# value (bright) drawn last so the seam is clean
	if frac_v > 0.0:
		draw_arc(center, radius, start, start + dir * frac_v * TAU, 96, value_color, thickness, true)

# convenience for wiring later: set both arcs from an HP state in one call
func set_hp(current: float, projected: float, maximum: float) -> void:
	max_value = maximum
	value = projected                 # bright = what survives
	secondary = maxf(current - projected, 0.0)  # dim = what's about to be lost
	queue_redraw()
