extends GameEvent
class_name RollEvent

# The planning-entry roll seam's envelope, reused across its three dispatches
# (PRE_ROLL mask → base roll → POST_ROLL ops → REROLLED reactions). Carries the live hand
# BY REFERENCE — transform effects mutate the actual controller arrays through it.
# The base roll is the ROLL, not a "reroll": only ops performed here enter the record.

var values : Array[int]
var elements : Array          # Rollables.Element per slot
var base_mask : Array = []    # PRE_ROLL: which slots the base roll refreshes (bool per slot)
var rerolled : Array = []     # instance record: {slot, element, old, new, source} — source "base" or "op"
var monster_damage : int = 0  # REROLLED accumulator; the seam applies + logs the actual delta


func _conditions_pass(e: Effect) -> bool:
	if trigger == Effect.Trigger.REROLLED and e.condition_element >= 0:
		return matching_rerolls(e.condition_element, e.condition_include_base).size() > 0
	return true


# The record entries a reaction cares about (element -1 = any element; base-roll
# instances count only when the effect declares condition_include_base).
func matching_rerolls(element: int, include_base: bool = false) -> Array:
	var out : Array = []
	for r in rerolled:
		if not include_base and r.source == "base":
			continue
		if element < 0 or r.element == element:
			out.append(r)
	return out


# Rolls one slot now and records the instance (the seam uses source "base" for the
# fresh-hand roll, effects' ops default to "op").
func reroll_slot(slot: int, source: String = "op") -> void:
	var old : int = values[slot]
	values[slot] = randi_range(1, 6)
	rerolled.append({"slot": slot, "element": elements[slot], "old": old, "new": values[slot], "source": source})
