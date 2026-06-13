extends Node
# Debug screenshot tool (ui-spec §8 verification protocol).
# F12 captures the current viewport to screenshots/<timestamp>.png.
# Editor / debug builds only — res:// is read-only in exported builds, so this
# is a dev aid for the 6-state screenshot checklist, not shipped UI.

const DIR := "res://screenshots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		_capture()
		get_viewport().set_input_as_handled()

func _capture() -> void:
	await RenderingServer.frame_post_draw          # ensure the frame is drawn first
	var img := get_viewport().get_texture().get_image()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/shot_%s.png" % [DIR, stamp]
	var err := img.save_png(path)
	print("screenshot: ", path if err == OK else "FAILED (err %d)" % err)
