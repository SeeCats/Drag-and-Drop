extends Node

# Live combatant registry (autoload "Combatants"). Holds refs to the player and the
# current monster node so the FSM can read their HP without scanning the tree. Entities
# self-register on _ready and clear on _exit_tree; the monster reassigns itself on respawn
# (the freed one's clear is guarded by `== self`, so respawn order doesn't matter).

var player : PlayerCharacter
var monster : Monster
