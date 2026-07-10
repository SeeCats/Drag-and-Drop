extends GameEvent
class_name ProjectRollEvent

# The dice→roll projection seam (get_roll_from_dice's moment). Effects modify the ROLL
# (e.g. spend charges into MULT). ALWAYS dry: this dispatch runs inside every preview
# trial as well as the commit publish, so effects may read their state here but NEVER
# mutate it — state changes belong to non-dry seams (COMMIT).

var values : Array[int]
var elements : Array   # Rollables.Element per slot
var roll : Array       # [base, mult, anti, anti_type] — mutate this


func _init() -> void:
	dry = true
