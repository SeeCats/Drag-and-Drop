extends Node

const RED = Color(Color.RED)

const GREEN = Color(Color.GREEN)
const BLUE = Color(Color.BLUE)
const WHITE = Color(Color.GHOST_WHITE)
const ELECTRIC_LIME : Color = Color("B0FF00")

const ELEMENT_COLOR = [RED, GREEN, BLUE, WHITE]
# Indexed by Element {RED,GREEN,BLUE,WHITE}. WHITE (3) is reserved-dormant
# (ui-spec §6.2): a ghost-white placeholder so element-indexed lookups never go OOB.
const NEON_COLOR = [
	Color.MAGENTA,
	ELECTRIC_LIME,
	Color.CYAN,
	WHITE,
]
const HALF = [
	Color(1,0,1,0.05),
	Color(0.2,1,0.2,0.05),
	Color(0,1,1,0.05),
	Color(1,1,1,0.05),
]

static func from_name(key: String) -> Color:
	match key:
		"red":        return RED
		"green":      return GREEN
		"blue":       return BLUE
		"white":      return WHITE
		"neon_red":   return NEON_COLOR[0]
		"neon_green": return NEON_COLOR[1]
		"neon_blue":  return NEON_COLOR[2]
		"neon_white": return NEON_COLOR[3]
		_:            return Color(key)  # fallback: treat as hex
