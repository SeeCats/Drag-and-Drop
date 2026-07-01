extends Node
class_name CombatSfx

# Combat SFX, self-wired off the global juice signals: hit (laser_zap) on a landed hit,
# miss (whoosh) on a hit lost to anti. Replaces the audio that lived in the deleted legacy
# combat_ui.gd. The rework controller spawns one of these; no scene/placement needed.

var _hit : AudioStreamPlayer
var _miss : AudioStreamPlayer


func _ready() -> void:
	_hit = _make_player(preload("res://assets/audio/laser_zap.mp3"))
	_miss = _make_player(preload("res://assets/audio/whoosh.mp3"))
	GlobalSignal.player_attacked.connect(_on_hit)
	GlobalSignal.monster_attacked.connect(_on_hit)
	GlobalSignal.player_missed.connect(_on_miss)
	GlobalSignal.monster_missed.connect(_on_miss)


# Builds a child AudioStreamPlayer for one stream.
func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player


func _on_hit() -> void:
	_hit.play()


func _on_miss() -> void:
	_miss.play()
