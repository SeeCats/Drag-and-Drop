extends Control
# REWORK combat UI (ui-spec §3–§7).
# The scene tree is authored in the EDITOR as real nodes (so they can be selected
# and tweaked). This script stays a thin controller: it will hold @onready refs to
# those nodes and wire them to CombatState / CurrentRoll / compute_outcome once the
# layout exists. Nothing is built in code. Refs get added as the tree grows.

func _ready() -> void:
	pass
