extends Resource
class_name MonsterResource

# Static, authored monster data. Runtime state (current_hp, current_round, current_pattern)


@export var monster_name : String = "Slime"
@export var texture : Texture2D
@export var max_hp : int = 25
@export var pattern_list : Array[Pattern] = []
