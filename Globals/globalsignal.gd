extends Node

# Global signal bus. The four attack/miss signals are emitted per hit/miss by
# combat_state._apply_attack for juice only (SFX, damage numbers) — damage is
# applied directly to Hp, never via these.

@warning_ignore("unused_signal")
signal updated_roll
@warning_ignore("unused_signal")
signal player_attacked
@warning_ignore("unused_signal")
signal monster_attacked
@warning_ignore("unused_signal")
signal player_missed
@warning_ignore("unused_signal")
signal monster_missed
