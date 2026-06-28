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
	WIN,                # monster dead
	LOSE,               # player dead
}

signal state_changed(from: State, to: State)
signal state_entered(state: State)
signal state_exited(state: State)

# Resolved outcome for the in-progress turn (from compute_outcome): {player:{...}, monster:{...}}.
var _outcome : Dictionary = {}

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
	# AD HOC: the FSM is now kicked by combat_ui.gd each time combat loads (see
	# start()), so it restarts correctly after a loss instead of staying stuck.
	# TODO: proper scene-start / run-reset flow.
	pass


# --- Public API ---

func transition_to(new_state: State) -> void:
	# Optional: add validation, logging, delays
	current_state = new_state

# Called by UI when player clicks "end turn"
func end_player_turn() -> void:
	if current_state == State.PLAYER_PLANNING:
		transition_to(State.TURN_RESOLVING)

# AD HOC: called by combat_ui.gd whenever the combat scene loads. Resets the
# persisted autoload FSM (e.g. stuck in LOSE after a defeat) and starts a fresh
# round. TODO: replace with a thorough scene-start / run-reset flow.
func start() -> void:
	current_state = State.INITIAL   # force-exit whatever we were stuck in
	transition_to(State.ROUND_START)


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
	_advance(State.PLAYER_PLANNING)   # a round-start damage source (future DoT) can end it here


func _on_turn_resolving() -> void:
	# Resolve the whole turn once, pure: anti is folded into compute_outcome (no more
	# mutating anti_operator). Player roll = controller's committed current_roll_list;
	# monster roll = its current pattern, written into current_monster_roll_list at round start.
	await get_tree().create_timer(1).timeout
	_outcome = CurrentRoll.compute_outcome(CurrentRoll.current_roll_list, CurrentRoll.current_monster_roll_list)
	_advance(State.PLAYER_ATTACK)


func _on_player_attack() -> void:
	await get_tree().create_timer(1).timeout
	await _apply_attack(Combatants.monster, _outcome.player, GlobalSignal.player_attacked, GlobalSignal.player_missed)
	_advance(State.MONSTER_ATTACK)   # death (either side) caught in _advance


func _on_monster_attack() -> void:
	await get_tree().create_timer(1).timeout
	await _apply_attack(Combatants.player, _outcome.monster, GlobalSignal.monster_attacked, GlobalSignal.monster_missed)
	_advance(State.ROUND_START)   # death (either side) caught in _advance


# Single transition gate. Reads HP from the live combatants so death is detected from
# ANY state (round-start DoT, mid-attack kill, or a plain attack) and routed the same way.
# Player is checked first, so a mutual kill (both at 0) resolves to LOSE — the tie
# "both win" / retreat model is deferred until effects exist (see HISTORY 2026-06-25).
func _advance(next_state: State) -> void:
	if _is_dead(Combatants.player):
		transition_to(State.LOSE)
	elif _is_dead(Combatants.monster):
		transition_to(State.WIN)
	else:
		transition_to(next_state)


# True when a combatant exists and its HP has hit 0.
func _is_dead(combatant: Character) -> bool:
	return is_instance_valid(combatant) and combatant.hp and combatant.hp.current_hp <= 0


# Applies one resolved side (per_hit / hits / misses from compute_outcome) to a target,
# staggered. Damage goes straight to the owner's Hp; the per-hit signals are emitted for
# juice only. Bails the instant the target is dead so a kill doesn't play out as over-kill.
func _apply_attack(target: Character, side: Dictionary, hit_signal: Signal, miss_signal: Signal) -> void:
	if not is_instance_valid(target) or not target.hp:
		return
	for i in side.misses:
		miss_signal.emit()
		await get_tree().create_timer(CurrentRoll.attack_stagger).timeout
	for i in side.hits:
		if _is_dead(target):
			break
		target.hp.take_damage(side.per_hit)
		hit_signal.emit()
		await get_tree().create_timer(CurrentRoll.attack_stagger).timeout


func _on_win() ->void:
	# Terminal for now: the rework loop lands here and stops (phase shows "victory").
	# Gauntlet respawn + run flow (advance Encounter, respawn the monster, restart) is
	# the next step of #2; the old monster_spawner path crashed in the rework scene.
	await get_tree().create_timer(1).timeout

func _on_lose() ->void:
	# Terminal for now: lands here and stops (phase shows "defeat"). Retreat / run-reset
	# flow is a later step.
	await get_tree().create_timer(1).timeout
