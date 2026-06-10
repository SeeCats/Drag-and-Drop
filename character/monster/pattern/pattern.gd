extends Resource
class_name Pattern

enum Type { HEAVY, FLURRY, GUARDED, SPIKE }   # round role — drives the lookahead hint

@export var type : Type = Type.HEAVY
@export var base : int = 3
@export var mult : int = 4
@export var anti : int = 3
@export var anti_type : int = 0
