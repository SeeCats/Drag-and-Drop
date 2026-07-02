extends Node

# "Next monster" selector (autoload "Encounter"). Run logic sets current_monster_order;
# the spawner reads next_monster (a MonsterResource) and feeds it to a Monster node.

var slime : MonsterResource = preload("res://character/monster/slime/slime.tres")
var ghost : MonsterResource = preload("res://character/monster/ghost/ghost.tres")
var alien : MonsterResource = preload("res://character/monster/alien/alien.tres")
var alligator : MonsterResource = preload("res://character/monster/alligator/alligator.tres")

var current_monster_order : int
var monster_list : Array[MonsterResource] = [
	alligator,
	ghost,
	alien,
	slime,
]

var next_monster : MonsterResource:
	get:
		return monster_list[current_monster_order % monster_list.size()]
