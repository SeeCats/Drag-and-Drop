extends Node

# "Next monster" selector (autoload "Encounter"). Run logic sets current_monster_order;
# the rework spawner reads next_monster (a MonsterResource) and feeds it to a Monster node.
# Loosely typed on purpose so the legacy PackedScene spawner doesn't fail to compile.

var slimeboss = preload("res://character/monster/slimebosss/slimeboss.tres")
var slime = preload("res://character/monster/slime/slime.tres")
var ghost = preload("res://character/monster/ghost/ghost.tres")
var alien = preload("res://character/monster/alien/alien.tres")
var alligator = preload("res://character/monster/alligator/alligator.tres")

var current_monster_order : int
var monster_list = [
	alligator,
	ghost,
	alien,
	slime,
]

var next_monster:
	get:
		return monster_list[current_monster_order % monster_list.size()]
