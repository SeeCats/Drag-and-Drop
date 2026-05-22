extends Label
class_name DamageNumber

var vertical_speed :int = 80
var duration : float = 0.4

func _ready() -> void:
	pass


# Called when the node enters the scene tree for the first time.
func pop_show():
	var start_y = position.y
	var t = create_tween()
	t.set_parallel(false)   # sequential for the up-then-down chain
	t.tween_property(self, "position:y", start_y - vertical_speed, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", start_y, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fade out in parallel — runs alongside the bounce
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, duration * 2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t.finished
	queue_free()

func pop_show_number(number: int):
	text = str(number)
	pop_show()

func pop_show_miss():
	text = "MISS"
	pop_show()

func pop_show_block(number: int):
	text = "BLOCKED %d" % [number] 
	pop_show()
