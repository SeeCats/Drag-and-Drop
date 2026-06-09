extends Control

# AD HOC (temporary): autoloads (CombatState/CurrentRoll) persist across scene
# reloads, so after a loss the FSM stays stuck in LOSE and the round never
# restarts. Kicking start() here on combat load works for now.
# TODO: replace with a proper scene-start / run-reset flow.
#
# This root also hosts the combat juice: screen shake + hit/miss SFX.

const SHAKE_MAX_OFFSET := 12.0   # px at full trauma
const SHAKE_DECAY := 1.5         # trauma lost per second
const HIT_PITCH_STEP := 0.08     # pitch rise per hit within a volley
const HIT_PITCH_MAX := 2.0

@export_range(-40.0, 6.0) var hit_volume_db := -6.0    # zap loudness
@export_range(-40.0, 6.0) var miss_volume_db := -8.0   # whoosh loudness

var _trauma := 0.0
var _base_pos: Vector2
var _hit_sfx: AudioStreamPlayer
var _miss_sfx: AudioStreamPlayer
var _hit_pitch := 1.0

func _ready() -> void:
	CombatState.start()
	_base_pos = position
	_hit_sfx = _make_player("res://assets/audio/laser_zap.mp3", hit_volume_db)
	_miss_sfx = _make_player("res://assets/audio/whoosh.mp3", miss_volume_db)
	GlobalSignal.player_attacked.connect(_on_player_hit)
	GlobalSignal.monster_attacked.connect(_on_monster_hit)
	GlobalSignal.player_missed.connect(_on_miss)
	GlobalSignal.monster_missed.connect(_on_miss)
	GlobalSignal.player_attack_finished.connect(_reset_hit_pitch)
	GlobalSignal.monster_atack_finished.connect(_reset_hit_pitch)

func _make_player(path: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = volume_db
	p.max_polyphony = 5   # let rapid hits overlap instead of cutting off
	add_child(p)
	return p

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - SHAKE_DECAY * delta, 0.0)
	position = _base_pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * SHAKE_MAX_OFFSET * _trauma
	if _trauma == 0.0:
		position = _base_pos

func add_shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)

func _shake_for(dmg: int) -> float:  # bigger hits shake harder; volleys stack
	return clampf(0.15 + dmg * 0.06, 0.15, 0.7)

func _play_hit() -> void:  # zap, pitch rising across the volley
	_hit_sfx.pitch_scale = _hit_pitch
	_hit_sfx.play()
	_hit_pitch = minf(_hit_pitch + HIT_PITCH_STEP, HIT_PITCH_MAX)

func _reset_hit_pitch() -> void:
	_hit_pitch = 1.0

func _on_player_hit() -> void:
	add_shake(_shake_for(CurrentRoll.player_damage))
	_play_hit()

func _on_monster_hit() -> void:
	add_shake(_shake_for(CurrentRoll.monster_damage))
	_play_hit()

func _on_miss() -> void:
	_miss_sfx.pitch_scale = randf_range(0.95, 1.1)  # slight variation
	_miss_sfx.play()
