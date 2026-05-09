extends Node


func round_start():
	GlobalSignal.round_started.emit()
	pass

func turn_end():
	pass
