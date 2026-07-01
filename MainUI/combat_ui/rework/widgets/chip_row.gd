extends HBoxContainer
class_name ChipRow

# Row of monster stat chips. The controller hands it the whole monster roll; it
# tells each child Chip which value to show, keyed by that chip's own role. So the
# row doesn't care about child order or count — add/remove/reorder chips freely.

func set_roll(roll: Array) -> void:
	for chip in find_children("*", "Chip", true):   # recursive: finds chips at any depth
		chip.set_value(roll[chip.role])   # role = index into [base, mult, anti]
		if chip.role == Rollables.RollIndex.ANTI and roll.size() > Rollables.RollIndex.ANTI_TYPE:
			chip.set_anti_type(roll[Rollables.RollIndex.ANTI_TYPE])   # anti chip also shows its type
