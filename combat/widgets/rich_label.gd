@tool
extends RichTextLabel
class_name RichLabel
# Our standard label: a RichTextLabel preset so we stop re-toggling the same three
# props on every label — BBCode on, sizes to its own text, never wraps.
# Override any property per-node as usual.
#
# Editor icon: none set on purpose. A class_name with no @icon inherits its base
# class's icon, so this shows the built-in RichTextLabel icon automatically.

func _init() -> void:
	bbcode_enabled = true
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
