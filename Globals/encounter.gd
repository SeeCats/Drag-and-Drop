extends Node

# External "next monster" selector (autoload "Encounter").
# Run/encounter logic sets `next_monster` before combat loads; the spawner reads
# it. Defaults to slime so combat works without any selection logic yet.

var slime : PackedScene = preload("res://character/monster/slime/slime.tscn")
var ghost : PackedScene =  preload("res://character/monster/ghost/ghost.tscn")
var alien : PackedScene =  preload("res://character/monster/alien/alien.tscn")
var alligator : PackedScene = preload("res://character/monster/alligator/alligator.tscn")


var current_monster_order : int
var monster_list = [
	alligator,
	ghost,
	alien,
	slime,
]

var next_monster : PackedScene:
	get:
		return monster_list[current_monster_order % monster_list.size()]
