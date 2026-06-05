# Project History

A running log of work and decisions. Newest entries on top. Keep each session entry concise: what changed, why, and any open threads. Code-level detail belongs in `CLAUDE.md`; this file is the narrative trail.

---

## 2026-06-05

### Damage-number null bug — fixed
- Symptom: `Cannot call method 'hide' on a null value` at `damage_number_zone.gd` `_ready`.
- Root cause: `damage_number_zone.gd` was attached to the **`CombatUi` root node** (which has no `DamageNumber` child), not just the real `DamageNumberZone` instance. `$DamageNumberLabel` resolved to null.
- Fix: removed the script from the `CombatUi` root (user's mistaken double-assignment). Kept defensive `preload`-alias type ref + null guards in the zone.

### CLAUDE.md architecture reference — added
- Read the whole project and wrote an Architecture section into `CLAUDE.md` (autoloads, FSM flow, roll data, signals, scene map, quirks) so it loads every session.
- Later moved `CLAUDE.md` from the parent `drag-drop/` folder **into the repo** (`DragAndDrop/CLAUDE.md`) so it syncs across devices via git.

### Player attack → staggered damage numbers
- `player_attack()` rewritten as a staggered coroutine (`attack_stagger`, 0.3s): a **miss loop then a hit loop**, each emit spaced by a timer; FSM `await`s it.
- Outcome rules from `anti_operator()`: `mult` reduction → MISS pops for lost hits; `base` reduction → `pop_show_block(original, blocked)` ("BLOCKED 5 - 3"); otherwise `pop_show_number`.
- New `player_missed` signal so misses don't deal damage. HP chunks per hit via existing `monster_hit()`.
- `pop_show_block` changed to take two args (original, blocked).

### Monster attack — mirrored
- `CurrentRoll.monster_attack()` mirrors the player (per-hit, block/miss, staggered) off `current_monster_roll_list` / `initial_monster_roll`.
- New `monster_missed` signal; reused `monster_atack_finished` (typo kept) to fire announcements **once** (moved `_announce_attack` and player's announcement off the now-per-hit `monster_attacked`).
- One **shared** `DamageNumberZone` reacts to both sides: player signals → up-tween variants, monster signals → `_monster` down-tween variants.

### Relics & status effects — architecture (DESIGN ONLY, not built)
- Decided on a **pipeline / chain-of-responsibility** model: every behavior becomes a mutable `Event` dispatched through all `Effect`s in priority order; each effect may read/modify/cancel it. This makes "all behaviors go through all effects" literal and gives effect-to-effect interaction for free.
- Pieces: `Effect` (Resource, `handle(event, host)`, `priority`, optional `duration`), `Event` (typed subclasses, PRE/POST phases), `EffectPipeline` (per-Character, ordered list, `dispatch()`).
- Lifecycle: `add_effect()` = `duplicate()` (avoid shared-resource state collisions) → `on_apply(host)` → sort by priority. Relics enter via reward screen (permanent); statuses enter via other effects' `handle()` (carry `duration`, self-remove via `on_remove()`). Mutate the effects list safely during dispatch (iterate a copy / defer).
- Open thread: scaffold `Effect` / `Event` / `EffectPipeline` on the `feature/effect-system` branch when ready (currently on hold).
- Study list gathered: Game Programming Patterns (Observer, Event Queue, Command, Type Object), GoF Chain of Responsibility, Godot custom Resources docs, and reference repos (wyvernshield-triggers, godot-gameplay-systems, GDQuest status effects).

### Repo / multi-device setup
- Repo lives at `DragAndDrop/` (remote: `SeeCats/Drag-and-Drop`, branch `main`).
- Created branch **`feature/effect-system`** off `main`; published to GitHub.
- Note: this Cowork sandbox **cannot reliably write to `.git`** (lock/permission issues; a `git checkout` left a stale lock and a misread that looked like HEAD corruption — data was always intact). Going forward: Claude edits code files; the user drives all git operations in GitHub Desktop.
