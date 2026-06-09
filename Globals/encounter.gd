extends Node

# External "next monster" selector (autoload "Encounter").
# Run/encounter logic sets `next_monster` before combat loads; the spawner reads
# it. Defaults to slime so combat works without any selection logic yet.
var next_monster: PackedScene = preload("res://character/monster/slimebosss/slimeboss.tscn")
