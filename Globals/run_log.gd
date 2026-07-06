extends Node

# Run history logger (autoload "RunLog"). The rework controller reports run / fight / round
# events; end_run() appends one JSON line per completed run to user://run_log.jsonl for later
# analysis (real play vs balance_sim). Local-only, no upload. Abandoned runs are flushed
# with outcome "abandoned" when the window closes (see _notification).

const PATH = "user://run_log.jsonl"

var _run : Dictionary = {}


# Quit mid-run: flush the in-progress run as-is (outcome is still "abandoned") — where
# players quit IS balance data. Desktop only; a mobile export should also flush on
# NOTIFICATION_APPLICATION_PAUSED (revisit at export time).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _run.is_empty():
		_run["final_hp"] = _final_hp()
		_append(JSON.stringify(_run))
		_run = {}


# Starts a fresh run record (discards any unfinished one).
func begin_run(start_hp: int) -> void:
	_run = {
		"ts": Time.get_datetime_string_from_system(),
		"start_hp": start_hp,
		"outcome": "abandoned",   # overwritten by end_run
		"died_to": null,
		"final_hp": start_hp,
		"fights": [],
	}


# Opens a fight record (player HP carries in from the previous fight).
func begin_fight(monster: String, max_hp: int, hp_in: int) -> void:
	if _run.is_empty():
		return
	_run["fights"].append({
		"monster": monster, "max_hp": max_hp, "hp_in": hp_in,
		"hp_out": null, "rounds": [],
	})


# Opens a round with its start-of-round state: dice arrangement, the monster's roll this
# turn, and HP before (both sides). Defaults let a round stand even if it never resolves.
func begin_round(start_dice: Array, monster_roll: Array, hp_player: int, hp_monster: int) -> void:
	var f = _current_fight()
	if f == null:
		return
	f["rounds"].append({
		"start": start_dice,
		"monster_roll": monster_roll,
		"hp_before": {"player": hp_player, "monster": hp_monster},
		"action": {"type": "pass"},
		"after": start_dice.duplicate(true),
		"deal": 0, "take": 0,
		"hp_after": {"player": hp_player, "monster": hp_monster},
	})


# Records the player's move + post-move dice for the open round.
func record_action(action: Dictionary, after_dice: Array) -> void:
	var r = _current_round()
	if r == null:
		return
	r["action"] = action
	r["after"] = after_dice


# Finalizes the open round from post-resolve HP. deal/take are the actual HP deltas, so a
# kill-skip reads take 0 and over-kill is clamped.
func record_result(hp_player: int, hp_monster: int) -> void:
	var r = _current_round()
	if r == null:
		return
	var pa : int = max(hp_player, 0)
	var ma : int = max(hp_monster, 0)
	r["hp_after"] = {"player": pa, "monster": ma}
	r["deal"] = max(r["hp_before"]["monster"] - ma, 0)
	r["take"] = max(r["hp_before"]["player"] - pa, 0)


# Closes the open fight.
func end_fight(hp_out: int) -> void:
	var f = _current_fight()
	if f == null:
		return
	f["hp_out"] = hp_out


# Finalizes the run and appends it as one JSON line.
func end_run(outcome: String, died_to = null) -> void:
	if _run.is_empty():
		return
	_run["outcome"] = outcome
	_run["died_to"] = died_to
	_run["final_hp"] = _final_hp()
	_append(JSON.stringify(_run))
	_run = {}


func _current_fight():
	if _run.is_empty() or _run["fights"].is_empty():
		return null
	return _run["fights"].back()


func _current_round():
	var f = _current_fight()
	if f == null or f["rounds"].is_empty():
		return null
	return f["rounds"].back()


func _final_hp() -> int:
	var f = _current_fight()
	if f != null and not f["rounds"].is_empty():
		return f["rounds"].back()["hp_after"]["player"]
	return _run.get("start_hp", 0)


# Appends one line, seeking to end so runs accumulate across sessions.
func _append(line: String) -> void:
	var f : FileAccess
	if FileAccess.file_exists(PATH):
		f = FileAccess.open(PATH, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("RunLog: could not open %s" % PATH)
		return
	f.store_line(line)
	f.close()
