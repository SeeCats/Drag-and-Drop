extends RichTextEffect
class_name HaloEffect

# Usage: [halo]text[/halo]
# Tag params (all optional, fall back to exports):
#   brightness=1.5  — RGB multiplier (>1 blooms brighter)
#   outline=0.3     — pulse minimum alpha (0..1)

var bbcode = "halo"

@export var halo_color: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var pulse_speed: float = 3.0
@export var pulse_min_alpha: float = 0.3

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if not char_fx.outline:
		return true  # leave fill text alone

	# DEBUG: confirm outline pass fires and color takes effect
	char_fx.color = Color.RED
	return true
