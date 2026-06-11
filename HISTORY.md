# Project History

A running log of work and decisions. Newest entries on top. Keep each session entry concise: what changed, why, and any open threads. Code-level detail belongs in `CLAUDE.md`; this file is the narrative trail.

---

## 2026-06-12 (Fable — record correction + provenance tags)

- Correction to the entry below: the committed sim run validates the baseline/sweep family of numbers, but `tools/balance_sim.py` contains **no keep-highest / mulligan-worst / +N-relic variants** — the **GDD §5.3 relic table remains irreproducible from the repo**. "Numbers match §5.3" is overclaimed; that code died with the glitched Design session. Work order stands for Code Claude: re-implement the §5.3 variants, re-run, commit per rule 5, confirm or correct the table.
- Re-added the reconstructed Design-session entry (under 06-11 below) — it was removed during the 06-12 cleanup, leaving the GDD's §5.3/§6.2/§7.6/§7.7/§7.8 additions unlogged again.
- GDD provenance tags added (cross-lane, user-directed): §5.3 labeled post-breather baseline (76%) + table-unverified warning; §7.7 labeled pre-breather baseline (66%), pointer to §7.8's +11pt breather note.
- CLAUDE.md shared rule 2 amended (user-directed): **every HISTORY entry names its author** (role) in the heading.

## 2026-06-12 (Code Claude — doc recovery + sim snapshot)

- Independently closed the "missing Design session" thread (same finding as the UI Claude 06-12 entry below): the archived `local_ba9d89fa` folder held only a 1-line transcript — a `Tool permission stream closed before response` crash at first tool call (2026-05-27). No dialogue, no ppt, nothing recoverable from disk; the chat itself lives in the app store (UI archive view), and the sim is reproducible from `tools/balance_sim.py` regardless.
- **First application of shared rule 5:** committed the raw balance_sim run to `docs/sim-results/2026-06-12-balance_sim.md` (script sha `8b64b2c4…`, seeds summary=7 / sweep=1, deterministic). Numbers match the wave-1 findings + GDD §5.3/§7.7/§7.8. Cross-lane exception (normally Design's to commit), user-approved for tonight.

## 2026-06-12 (continuation of the 06-11 UI Claude session, past midnight KST)

- **All three prototype verdicts PASSED** (deal-on-knob confirmed on the element-fixed build — "passed the tofu test"). Deal-on-knob + thin-strip S2 adopted; 17 acceptance criteria written into ui-spec §8; spec status → VALIDATED.
- §6 color unification DECIDED: neon family canonical everywhere (origin: QCD-strict RGB primaries → rejected as ugly/illegible, gf's verdict upheld); `ELEMENT_COLOR` retired from UI; WHITE element = reserved dormant slot (far-future all-elements dice), NEON_COLOR needs a defensive 4th entry; monster anti chip = neutral (element colors only on element-bearing things); player-facing text never names colors. **ui-spec status → READY FOR BUILD.**
- Idea parked **for Design Claude to place in the GDD** (design-history nugget, user request): the game once had a QCD phase — CMY anti-colors were nearly their own mechanic (anti-colored dice/anti-dice territory). Cut because teaching QCD costs more than the "portals ripped out" fiction; the QCD skeleton survives invisibly (3 elements, ANTI slot, complementary neon palette). May have a pulse for a far-future system alongside the dormant WHITE all-elements dice (ui-spec §6).
- Prototype file user-renamed to `docs/prototype/combat-ui-prototypever3.html` during phone transfers; spec references updated to match.
- "Missing archive" scare resolved: the empty zip was a session that crashed at first tool call (May 27) — nothing was lost; sim insights are canonized in GDD §5.3/§7.7/§7.8, balance_sim.py in repo, transcripts intact. (Windows note: the packaged Claude app virtualizes `%APPDATA%\Claude` into `AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude` — look there for app data on disk.)
- CLAUDE.md shared rule 5 added: **sim outputs cited in decisions get committed to `docs/sim-results/`** (dated + script version) in the same session — "insights without their data are claims." Applies from Design Claude's next sim session.
- Next: hand to Code Claude — build per ui-spec §8 acceptance criteria; work orders bundled: Swatch cleanup (+4th neon entry), tray input controller replacing swap.gd/rotate.gd, F12 screenshot autoload.

## 2026-06-11

### GDD sim-backed sections (Design Claude session — RECONSTRUCTED by Fable; session glitched and died before logging)
- Session became unresponsive mid-work; GDD edits landed, HISTORY entry didn't. Logged retroactively from the diff; treat details as best-effort.
- Added: **§5.3** measured relic power (keep-highest / mulligan-worst / +N relics vs win%+tension), **§6.2** rewritten as "threat shapes — a monster is a rotation, not a stat-block", **§7.6** perceived vs real difficulty (honest-intimidation doctrine; §3.4 sacred — never lie about a number), **§7.7** tune shape-not-level, **§7.8** volatility doctrine (concave value curve; sim before shipping any number).
- ⚠️ The relic-variant sim code behind §5.3 was never committed and died with the session — the table is **unverified** until re-implemented (see Fable's 06-12 correction above).

### Combat UI remake — foundations (UI Claude session, design only, no code)
- Ground-up redesign started; current UI declared legacy. Information hierarchy ranked (T1 outcome/thresholds/alternatives → T2 state → T3 staging → T4 lookahead → T5 resolution feedback).
- Zone map drafted: 5 vertical bands on the 540×1140 canvas — S0 status / S1 enemy (only elastic band) / S2 relation ledger (deal-take math, resolution numbers) / S3 player columns / S4 verb tray; thumb line ~45%; one N-column spine (not hardcoded 3) shared by enemy mirror and player tray.
- **DECIDED: zones are fixed furniture, dice are the only things that move.** Rotate = dice shift one column; zone/action rotation rejected (kills position-as-meaning, breaks monster mirror alignment). The 6-zone swap/rotate hack is to be deleted; `swap.gd`/`rotate.gd` dual state machines collapse into one tray input controller later.
- Direction-split gestures (swipe=rotate) proposed and **rejected** (undiscoverable, clunky). Open: input mechanic — candidates: drag-to-swap + rotate buttons w/ outcome labels; home-screen slide-to-fill (gap: can't express end-swap without drop-on-top rule); rotate handle bar; tap-tap. Redundant channels allowed.
- Screenshot-verification loop agreed: manual 6-state checklist now; F12 debug screenshot autoload = work order for Code Claude (+ Godot headless `--check-only` harness to ask Code Claude).
- Created `docs/ui-spec.md` (canonical combat-UI spec): canvas, hierarchy, zone map, spine, object model; input mechanic + commit gesture marked OPEN.
- ui-spec §5: also rejected "zones rotate, snap back at round start" variant (resolution still misaligned; reset motion = noise).
- Input mechanic working direction (ui-spec §5): **player wheel** — knob = rotate, dice-drag = swap, separate handles; monster's roll rendered as a **scouter reticle** (HP ring + stat chips) = its wheel; matched-angles pairing rule; two-vertices-up orientation (equation reads L→R, survives N=4 as flat-top square). CONDITIONAL on knob passing a walking-thumb test in the HTML phone prototype; fallback = same geometry, ⟲⟳ buttons.
- Superseded same session by **row + knob** (user's sketch): dice row (column spine restored) + rotate knob below it, Cancel/Confirm flanking (commit gesture resolved); scouter HP-ring kept as monster presentation; wrap animation = flagged design debt; "deal on the knob" + thin-strip S2 proposed. Full circular wheel archived in ui-spec §5.
- ui-spec §7 Motion added: idle dice are still (dad-playtest: constant cube spin = distracting); spin only encodes uncertainty — roll reveal, staged-reroll slow tumble (replaces "will reroll" text badge), light drag spin.
- Layout iteration on mockups: S3/S4 merged into one tight tray cluster (HP → dice → knob w/ Cancel·Confirm flanks); tight-grouping rule + wrap-path-is-animation-only added to ui-spec; recovered space went to the monster ring. Flagged: Cancel/Confirm under 80px touch minimum.
- Menu button address reserved: S0 top-left corner (rare action → deliberate reach); visual-size ≠ hit-size rule added to ui-spec §1.
- GDD §9.1: added "One level deep, everywhere" (no menu inside menu — user's founding instinct for the remake, now wordified; Clash Royale precedent). ui-spec cites it; reference scan logged (Slice & Dice = closest relative, research to-do).
- **Prototype built**: `docs/prototype/combat-ui-prototype.html` — single-file, playable loop (3-fight gauntlet, 3 cycling patterns, d10 dice). Implements: knob rotary gesture (120°/step), drag-to-swap, staging w/ one-move-replacement, cancel/confirm, wrap arc animation, deal-on-knob (range display when swap staged), kill-on-X+ threshold strip, HP ring, motion rules (idle still / staged-reroll tumble / roll reveal). Simplified math — feel-testing only, not rules-canonical. Test on phone while walking: knob feel, wrap legibility, deal-on-knob.
- Knob gesture simplified (user call): horizontal flick — end point lefter/righter than start = rotate left/right; rotary angle tracking dropped (2 rotations + one move per turn = angle tracking is pure misfire surface). Prototype + ui-spec §5 updated.
- **Knob flick PASSED the thumb test** (user operated it one-handed while eating with chopsticks — divided attention, no misfires). Row+knob promoted from working direction to DECIDED in ui-spec §5; button fallback retired.
- Wrap-arc legibility PASSED ("everything shifted around"). Prototype fidelity bug found by user: elements were rerolling with values each round — fixed (elements permanent per dice, values only).
- (Later items from this session continue under the 2026-06-12 header above — the session crossed midnight KST.)

### Playtest wave 1 — analyzed (Fable diagnosis session)
- 4 subjects (park, one-handed, designer as live tutor). Full findings: `docs/playtest-wave1-findings.md`.
- **Verdict: refine, don't restart.** Core rules validated (clean model, 3 on-ramps, player-discovered heuristics are mathematically correct, emotional core fires — 제발/망겜 from all engaged subjects). Every failure is around the rules, not in them: no teaching gauntlet (3/4 struggled with a live tutor; random play reaches the boss), no staging/confirm (GDD §9.1 unbuilt — contaminated the data), decision UI answers "what does this do" not "which move do I want", swap reads as draw not gamble (EV-positive), kill-skip racing degenerates expert play.
- Decisions: staged board + tap-dropped-die-to-commit (reroll fires on commit, anti-scumming); threshold legibility ("kill on 4+") before touching swap mechanics; teaching gauntlet = top content priority; kill-skip cured via pattern dramaturgy (kill windows/enrages) before any rule change; wave 2 (middle-profile, no tutoring, telemetry) only after fixes are built. Tripwire for widening the base loop: post-ladder+gear players still collapsing to the two heuristics.
- Roster expanded to 4 Claudes (Fable diagnosis / Code / Design / UI) — coordination block added to CLAUDE.md. UI Claude owns `docs/ui-spec.md`; GDD §9 ownership moves to UI Claude.
- Open threads: the checkout Fable reviewed (commit "testingrelicideas") **lacks `compute_outcome`** while announce.gd calls it — per the entry below it exists on other branches; resolve by merging in GitHub Desktop, don't rewrite it. Monster display scripts duplicated ×5 (alien/alligator/ghost/slime/slimebosss). Swap identity fork (gamble vs economy) pending threshold-UI test. balance_sim needs a shield-aware policy + an uncontestable-damage metric.

### Parse-error fix — `:=` inference through autoload (branch `fix-laptop`)
- Symptom: after deleting `.godot/` to reopen the project on the laptop, GDScript threw `Cannot infer the type of "o"` at `player_character.gd:76`/`:89` and `announce.gd:24`; `combat_state.gd` failed as a cascade (it depends on the `PlayerCharacter` class). A later normal reopen hard-crashed the editor (native null-deref, `0x...0028`) — automatic scene-restore tried to instance a scene whose `PlayerCharacter` script was null from the failed compile.
- Root cause: `var o := CurrentRoll.compute_outcome(...)` asks the analyzer to infer a type from a method called through an **autoload singleton**. GDScript doesn't reliably propagate return types through autoloads on a **cold** `.godot/` cache, even though `compute_outcome` declares `-> Dictionary`. The desktop "worked" only because its warm cache had the class registry already built — not because the code was robust.
- Fix: explicit annotation at the 3 sites — `var o: Dictionary = CurrentRoll.compute_outcome(...)`. No inference needed; compiles cold or warm, any machine. Behavior identical. Return type stays Dictionary deliberately (shape still exploratory; adding a key shouldn't touch the signature) — revisit a typed Outcome object only when ADR-001 effects start sharing/mutating it.
- Done on branch `fix-laptop` (user created it in GitHub Desktop; Claude only edited files). Recovery Mode is the way in if the editor is mid crash-loop.
- Open thread: committed repo cruft — orphaned `*.tscn…####.tmp` save-temp files (MainUI/, player_vbox/dice/, slime/) and a dead `mainui.tscn` (only `.tmp` copies; references a missing `hex.tscn`). Harmless to open but should be deleted + `*.tmp` added to `.gitignore`.
- Added a gotcha to `CLAUDE.md`: never `:=` on autoload method calls.

### Compile-harness feasibility — tested, doesn't belong in the sandbox
- UI Claude proposed a Godot-headless `--check-only` gate in the Cowork sandbox to catch the `:=`-autoload bug class before it hits a machine. Tested it: **not viable here.** (1) The Godot 4.6 binary can't be installed — `github.com` is reachable but the asset redirects to `release-assets.githubusercontent.com`, which the sandbox network allowlist blocks (no mirror). (2) The PyPI alternative `gdtoolkit` (`gdparse`/`gdlint`) installs fine but is a *syntax/lint* tool, not a type analyzer — fed it `var o := MyAutoload.compute_outcome(...)` and it passed clean (exit 0, "no problems"). The autoload-inference failure only Godot's own analyzer produces.
- Decision: the compile gate belongs in **CI**, not in-session. Added `.github/workflows/godot-check.yml` (cold-cache `--import` on a GitHub runner, which *can* fetch the binary). **Untested + unproven:** whether `--import` reproduces the cold-cache autoload bug or warms the cache first and gives a false green is the open question — validate by pushing a deliberate `:=` regression and checking the workflow goes red. gdtoolkit still worth adding as a cheap syntax/lint gate, but it is NOT the type checker that bug needs.

### Iris Xe editor crash on open (graphics, parked low-priority)
- Godot 4.6 default Forward+ (Vulkan) renderer crashes the editor during init on Intel Iris Xe — hard crash → Recovery Mode prompt. Not corruption, not our code (the exported build ran fine on a real phone). Durable fix if it ever matters: switch `rendering/renderer/rendering_method` to `Compatibility` (fits the mobile target anyway). Plan: test on a better-GPU machine (internet cafe); if smooth, leave it. Settled by GPU, not by code.
- (Earlier this session I'd parked the `:=`-through-autoload parse error as "suspected version skew, don't fix yet." That diagnosis was wrong — root cause was the cold-cache autoload-inference issue and it's now fixed; see the "Parse-error fix" entry above. The two crashes are independent: GPU/renderer here, analyzer there.)

---

## 2026-06-10 (later)

### Next-pattern label → raw numbers
- `next_pattern.gd` now shows the upcoming roll as `Base: N  Mult: N  Block/Miss: N` instead of the role name. Defense label from `anti_type`: BASE→Block, MULT→Miss; the N is the unreduced `anti` (threatened, not resolved). Type/role moves to the planned halo color hint (still deferred), so the two channels don't duplicate.

### Gate swap/rotate to PLAYER_PLANNING
- `swap.gd`/`rotate.gd` `_input` now early-return unless the FSM is in `PLAYER_PLANNING`, so dice can't be moved while combat is resolving/animating. Hover preview is covered transitively (it only fires off a started swap). One-line guard each.

### CLAUDE.md de-stale
- Synced CLAUDE.md to current code: added `preview_set`/`preview_clear` signals, `compute_outcome` + `next_pattern` on CurrentRoll, a Preview UI section (announce.gd dual readout, hover preview, Pattern/Type + next_pattern label), `NextPattern` in scene map; noted `monster_turn_end`+`monster_damage_operator` both dead. Added a standing rule: update CLAUDE.md in the same session as code changes.

---

## 2026-06-10

### Projected-outcome preview (the big one)
- `CurrentRoll.compute_outcome(player_roll, monster_roll)` — pure, side-effect-free resolver (mirrors anti_operator + base×mult on copies), returns a Dict `{player/monster:{per_hit,hits,total,blocked,misses}}`. Verified it matches live combat. This is the shared seam the effect pipeline will hook later.
- Stage 1: `announce.gd` became a shared readout — PREVIEW (`Deal X  Take Y` for the current arrangement, recomputed on `updated_roll` via `CONNECT_DEFERRED` to dodge a one-frame lag) vs LOG; a horizontal swipe *started on the label* toggles them (hide gesture removed, by choice).
- Stage 2: live hover preview. `player_character.preview_rotate` (single value) / `preview_swap` (`Deal X~Y` range over the 6 reroll values — keeps the gamble intact, shows stakes not result). `swap.gd`/`rotate.gd` `_process` polls the hovered zone during a drag and emits `preview_set`/`preview_clear`. Decision recap: swap reroll is unpreviewable-by-design, so only the range is shown.

### Next-pattern lookahead
- `Pattern` gained `enum Type {HEAVY,FLURRY,GUARDED,SPIKE}` + `@export type` (authored intent beats number-inference; Spike + future types aren't inferable). `CurrentRoll.next_pattern` (Pattern ref) published by `monster.update_roll`; `next_pattern.gd` label shows `Next: <Type>`. **Open: set the Type dropdown on every pattern `.tres` (all default HEAVY).** Halo color hint deferred (will map `next_pattern.type`→color).

### GDD / design
- §3.2 precise rotate/swap state model. §6.2 **corrected defense math** (caught my error via the user's counterexample): `armor=min(anti,base−1)×mult`, `evasion=base×min(anti,mult−1)`; best color is roll-dependent and **inverts at high anti**; monsters reframed as rotations of threat shapes. Recorded 3 planned pattern types (Buff-self / Debuff-player / All-in — need new structure) + monster teaching roles (alligator=familiarize, ghost=flow, alien=defense-has-limits, slime=full workout, boss=placeholder). §12.18 snackable-deep audience intent.
- Noted the hidden-defaults gotcha: `pattern.gd` base3/mult4/anti3 silently fill unset `.tres` fields → monsters tankier than they look.

### Fixes
- `hp.gd` setters guard `if label:` (`@export` fires before `@onready`). Pattern cycling (update_roll before `current_round += 1`). Portrait orientation in project.godot. FSM restart-after-loss via ad-hoc `combat_ui.gd start()`. Damage-number on-screen clamp. Gauntlet win-advance keeps player HP (only the monster respawns). Removed dead `monster_entered` signal + `slimebosss/hplabel.gd`.

### Still open
- **Effect pipeline (relics/status) deferred** until the un-geared loop is validated by playtest (#1 GDD risk; the preview was the gating item — now cleared). Design in ADR-001. Relics + the 3 planned pattern types all hook `compute_outcome`.
- Tasks: lazy-load dungeons; proper scene-start/run-reset (replace ad-hoc `start()`); instrumentation for playtest; author real monster rotations + set pattern types.

---

## 2026-06-08

### Study pass 2 — Component & Type Object
- Skimmed **Component** (it's Godot's node system; validates pipeline-as-node) and read **Type Object** (relics/statuses as `Resource`s). Notes appended to `docs/study-notes/game-programming-patterns.md`.
- Key insight: Type Object makes type-specific *data* easy but *behavior* hard → resolved by each relic being an `Effect` subclass that overrides `handle()` (Type Object + per-type behavior via scripted Resource). `Pattern` = pure Type Object; `Effect` = Type Object + behavior.
- Framing locked in: **relic ≈ Type Object** (invariant identity), **status ≈ State** (temporal, has duration). Relic families/tiers → single inheritance via `@export var parent`.
- Added the `CurrentRoll` write-site list to `ADR-001` (sites to migrate; `anti_operator()` = primary transform seam).

---

## 2026-06-06

### Effect system — ADR + architecture study
- Wrote `docs/adr/ADR-001-effect-system-architecture.md`: chose the **event pipeline / Chain of Responsibility** model (behaviors become mutable `Event`s dispatched through ordered `Effect`s; each may read/modify/cancel). Stays **synchronous** — callers need an immediate answer, so not a queue.
- Installed the **engineering** plugin; used its `architecture` skill to produce the ADR.

### Study pass — Game Programming Patterns
- Read **Event Queue** and **Command** chapters; notes saved to `docs/study-notes/game-programming-patterns.md` (phone-readable via GitHub).
- Takeaways: Command (reify an action) → Chain of Responsibility (our pipeline) → Event Queue (skipped, decouples in time). `execute(actor)` ≈ our `handle(event, host)`.
- Decided GDScript types: `Effect` = `Resource`, `Event` = `RefCounted`, `EffectPipeline` = `Node`.
- Rule of thumb: one op/no state → `Callable`; multiple ops or state → class/Resource (so `Effect` is a Resource).
- Reinforced: many signal listeners = fine; many uncoordinated writers to shared state (`CurrentRoll`) = bad → funnel writes through the pipeline.

### Housekeeping
- Added rule to `CLAUDE.md`: **do not run git commands** (sandbox can't write `.git` safely; user drives git in GitHub Desktop).
- Effect-system work belongs on branch `feature/effect-system` (scaffold not started yet).

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
