extends Node2D
class_name Starfield

# Decorative starfield drifting downward behind the combat UI (ui-spec §7). Purely
# aesthetic — never inside an info container (it's on a back CanvasLayer). Drift speed is
# the tempo channel: a slow crawl during planning, a fast downward streak while the turn
# resolves, eased between. Spawned by the controller; reads CombatState for its speed.

@export var star_count : int = 90
@export var crawl_speed : float = 18.0     # px/sec down during planning
@export var streak_speed : float = 420.0   # px/sec down during the resolve beat
@export var star_color : Color = Color(0.8, 0.9, 1.0, 0.5)

var _stars : Array = []          # each: {pos: Vector2, size: float, mult: float}
var _bounds : Vector2
var _speed : float = 18.0        # current drift, eased toward the state's target


func _ready() -> void:
	_bounds = get_viewport_rect().size
	_speed = crawl_speed
	for i in star_count:
		_stars.append(_new_star(randf() * _bounds.y))   # scatter across the screen at start
	get_viewport().size_changed.connect(func(): _bounds = get_viewport_rect().size)


# One star: random x, given y, small random size + a parallax speed multiplier (depth).
func _new_star(y: float) -> Dictionary:
	return {
		"pos": Vector2(randf() * _bounds.x, y),
		"size": randf_range(1.0, 2.5),
		"mult": randf_range(0.5, 1.4),
	}


func _process(delta: float) -> void:
	_speed = lerp(_speed, _target_speed(), clampf(delta * 4.0, 0.0, 1.0))   # ease toward the tempo
	for s in _stars:
		s.pos += Vector2(0.0, _speed * s.mult * delta)   # += reassigns the dict key (member-mutate wouldn't persist)
		if s.pos.y > _bounds.y:                            # fell off the bottom → respawn at the top
			s.pos = Vector2(randf() * _bounds.x, 0.0)
			s.size = randf_range(1.0, 2.5)
			s.mult = randf_range(0.5, 1.4)
	queue_redraw()


# Slow crawl by default; fast streak only while the turn is resolving.
func _target_speed() -> float:
	match CombatState.current_state:
		CombatState.State.TURN_RESOLVING, CombatState.State.PLAYER_ATTACK, CombatState.State.MONSTER_ATTACK:
			return streak_speed
		_:
			return crawl_speed


func _draw() -> void:
	var streaking : bool = _speed > crawl_speed * 3.0
	for s in _stars:
		if streaking:
			draw_line(s.pos, s.pos - Vector2(0.0, s.size * 6.0), star_color, s.size)   # trail behind the fall
		else:
			draw_circle(s.pos, s.size, star_color)
