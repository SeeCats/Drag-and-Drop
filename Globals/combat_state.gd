extends Rollables
# combat_state.gd
# Autoload as "CombatState"

enum State {
	INITIAL,            # sentinel — FSM starts here so the first real transition fires
	ROUND_START,        # roll dice, set monster pattern
	PLAYER_PLANNING,    # waiting for player to swap / rotate / end turn
	TURN_RESOLVING,     # apply anti, compute damage
	PLAYER_ATTACK,      # emit per-hit damage
	MONSTER_ATTACK,     # counter-attack
	CHECK_DEFEAT,       # someone dead? → WIN/LOSE : ROUND_START
	WIN,                # monster dead
	LOSE,               # player dead
}

signal state_changed(from: State, to: State)
signal state_entered(state: State)
signal state_exited(state: State)

var current_state : State = State.INITIAL:
	set(new_state):
		if new_state == current_state:
			return
		var old_state = current_state
		_exit_state(old_state)
		state_exited.emit(old_state)
		current_state = new_state         # doesn't re-trigger setter in Godot 4
		state_changed.emit(old_state, new_state)
		_enter_state(new_state)
		state_entered.emit(new_state)

func _ready() -> void:
	# Kick things off on next frame so listeners have a chance to subscribe.
	transition_to.call_deferred(State.ROUND_START)


# --- Public API ---

func transition_to(new_state: State) -> void:
	# Optional: add validation, logging, delays
	current_state = new_state

# Called by UI when player clicks "end turn"
func end_player_turn() -> void:
	if current_state == State.PLAYER_PLANNING:
		transition_to(State.TURN_RESOLVING)


# --- State enter handlers ---

func _enter_state(state: State) -> void:
	match state:
		State.ROUND_START:
			_on_round_start()
		State.PLAYER_PLANNING:
			pass  # waiting for input — nothing to do
		State.TURN_RESOLVING:
			_on_turn_resolving()
		State.PLAYER_ATTACK:
			_on_player_attack()
		State.MONSTER_ATTACK:
			_on_monster_attack()
		State.CHECK_DEFEAT:
			_on_check_defeat()
		State.WIN:
			print("WIN")
			_on_win()
		State.LOSE:
			print("LOSE")
			_on_lose()


func _exit_state(_state: State) -> void:
	# Optional cleanup per state. Empty for now.
	pass


# --- State logic (replaces the old operators) ---

func _on_round_start() -> void:
	# Iterate every node in the "round_participants" group in priority order
	# and call round_start() on each. Lower priority runs first.
	await get_tree().create_timer(1).timeout
	var participants = get_tree().get_nodes_in_group("round_participants")
	participants.sort_custom(func(a, b): return a.round_start_priority < b.round_start_priority)
	for p in participants:
		if p.has_method("round_start"):
			p.round_start()
	transition_to(State.PLAYER_PLANNING)


func _on_turn_resolving() -> void:
	await get_tree().create_timer(1).timeout
	CurrentRoll.anti_operator()
	transition_to(State.PLAYER_ATTACK)


func _on_player_attack() -> void:
	# Emits player_attacked N times → monster.monster_hit() takes damage per emit.
	await get_tree().create_timer(1).timeout
	CurrentRoll.player_attack()
	if _is_monster_dead():
		transition_to(State.WIN)
		return
	transition_to(State.MONSTER_ATTACK)


func _on_monster_attack() -> void:
	# Computes monster_damage and emits monster_attacked → player.player_hit() takes damage.
	await get_tree().create_timer(1).timeout
	CurrentRoll.monster_damage_operator()
	GlobalSignal.monster_attacked.emit()
	if _is_player_dead():
		transition_to(State.LOSE)
		return
	transition_to(State.CHECK_DEFEAT)


func _is_monster_dead() -> bool:
	for p in get_tree().get_nodes_in_group("round_participants"):
		if p is Monster:
			return p.hp.current_hp <= 0
	return false


func _is_player_dead() -> bool:
	for p in get_tree().get_nodes_in_group("round_participants"):
		if p is PlayerCharacter:
			return p.hp.current_hp <= 0
	return false


func _on_check_defeat() -> void:
	# TODO: read HP, transition accordingly
	# if player_dead or monster_dead:
	#     transition_to(State.WIN or State.LOSE)
	# else:
	#     transition_to(State.ROUND_START)
	await get_tree().create_timer(1).timeout
	transition_to(State.ROUND_START)


func _on_win() ->void:
	await get_tree().create_timer(1).timeout
	CurrentRoll.is_player_winning = "WIN"
	get_tree().change_scene_to_file("res://MainUI/main_menu/main_menu.tscn")
	pass

func _on_lose() ->void:
	await get_tree().create_timer(1).timeout
	CurrentRoll.is_player_winning = "LOSE"
	get_tree().change_scene_to_file("res://MainUI/main_menu/main_menu.tscn")
	pass
