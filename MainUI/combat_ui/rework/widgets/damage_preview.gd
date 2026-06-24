@tool
extends RichLabel
class_name DamagePreview

# Player's projected-damage readout in the knob: DEAL header, number, sub line.
var value: String:
	set(new_value):
		value = new_value
		_queue_refresh()
var sub: String:
	set(new_value):
		sub = new_value
		_queue_refresh()

var _pending: bool = false

# Schedules one deferred render per frame, so value + sub coalesce into a single rebuild.
func _queue_refresh() -> void:
	if _pending:
		return
	_pending = true
	set_deal.call_deferred()

# Renders the three stacked lines from the current value and sub.
func set_deal() -> void:
	_pending = false
	text = "[center][font_size=13]DEAL[/font_size][/center]\n[center][font_size=30]%s[/font_size][/center]\n[center][font_size=13]%s[/font_size][/center]" % [value, sub]
