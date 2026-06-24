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
@export var range_amount: float = 0.0:         # middle "uncertain" band between value and secondary
	set(v): range_amount = v; queue_redraw()
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
	var frac_r := clampf(range_amount / max_value, 0.0, 1.0 - frac_v)
	var frac_s := clampf(secondary / max_value, 0.0, 1.0 - frac_v - frac_r)
	# track (full ring)
	draw_arc(center, radius, start, start + dir * TAU, 96, track_color, thickness, true)
	# secondary (sure loss) — outermost band of the filled arc
	if frac_s > 0.0:
		var s0 := start + dir * (frac_v + frac_r) * TAU
		draw_arc(center, radius, s0, s0 + dir * frac_s * TAU, 96, secondary_color, thickness, true)
	# range (uncertain) — middle band, a blend of value and secondary
	if frac_r > 0.0:
		var r0 := start + dir * frac_v * TAU
		draw_arc(center, radius, r0, r0 + dir * frac_r * TAU, 96, value_color.lerp(secondary_color, 0.5), thickness, true)
	# value (bright) drawn last so the seam is clean
	if frac_v > 0.0:
		draw_arc(center, radius, start, start + dir * frac_v * TAU, 96, value_color, thickness, true)

# Sets the two arcs from a single HP projection (the exact, no-gamble case).
func set_hp(current: float, projected: float, maximum: float) -> void:
	var dmg := current - projected
	set_hp_range(current, dmg, dmg, maximum)

# Sets three bands from a damage RANGE: bright = survivors at worst, middle =
# uncertain (the gamble), dim = sure loss. Equal min/max collapses the middle.
func set_hp_range(current: float, dmg_min: float, dmg_max: float, maximum: float) -> void:
	max_value = maximum
	value = maxf(current - dmg_max, 0.0)        # survives even at max damage
	range_amount = maxf(dmg_max - dmg_min, 0.0)  # the gamble band
	secondary = maxf(dmg_min, 0.0)              # lost for sure
	queue_redraw()

var _tween: Tween

## Animate the bright arc down to `target` (damage feedback). Because `value`'s
## setter calls queue_redraw(), tweening it redraws the arc each frame. Clears the
## at-risk `secondary` (the preview is now being realized) and flashes the ring.
func tween_to(target: float, dur: float = 0.25, flash: bool = true) -> void:
	secondary = 0.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", target, dur)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if flash:
		modulate = Color(2, 2, 2)                              # bright flash
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
