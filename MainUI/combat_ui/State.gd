extends Label

var State = [
	"INITIAL",            # sentinel — FSM starts here so the first real transition fires
	"ROUND_START",        # roll dice, set monster pattern
	"PLAYER_PLANNING",    # waiting for player to swap / rotate / end turn
	"TURN_RESOLVING",     # apply anti, compute damage
	"PLAYER_ATTACK",      # emit per-hit damage
	"MONSTER_ATTACK",     # counter-attack
	"CHECK_DEFEAT",       # someone dead? → GAME_OVER : ROUND_START
	"WIN",                # monster dead
	"LOSE",               # player dead
]

func _ready() -> void:
	# Use state_changed (not state_entered) so the label updates in forward
	# cascade order. state_entered fires AFTER _enter_state returns, which
	# means during a synchronous cascade through multiple states the emits
	# come back in reverse and the label shows the wrong (earliest) state.
	CombatState.state_changed.connect(show_state)

func show_state(_from: int, to: int) -> void:
	text = State[to]
