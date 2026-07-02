extends Button

# Play button — loads the combat scene.

func _on_button_up() -> void:
	get_tree().change_scene_to_file("res://combat/CombatRework.tscn")
