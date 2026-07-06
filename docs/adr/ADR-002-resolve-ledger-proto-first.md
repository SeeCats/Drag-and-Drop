# ADR-002: Commit to the per-hit resolve ledger; prototype relics before choosing effect machinery

**Status:** Accepted 2026-07-06 (supersedes ADR-001's machinery commitment; keeps its analysis as lineage)
**Date:** 2026-07-06
**Deciders:** C (project owner)

## Context

ADR-001 (2026-06-06, Accepted) chose an event pipeline (Chain of Responsibility) for relics/statuses. It was written before the combat rework: its migration map named code that no longer exists (`anti_operator`, `RewardChoice.tscn`, `update_player_dice`), and — more fundamentally — before a single real relic existed to test the choice against. The project has since validated a working method for exactly this situation: **prototype before committing** (the combat UI rework was proto-gated, and the protos changed the design).

What has changed since ADR-001:

- Resolution is already **pure**: `CurrentRoll.compute_outcome(player_roll, monster_roll)` is a side-effect-free function used by BOTH the FSM (`combat_state._on_turn_resolving`) and the planning preview (`combat_rework._resolve()` folds the swap gamble's 1..6). This is the transform seam ADR-001 wanted `anti_operator` to become — it exists now.
- Application is a dumb staggered replay (`combat_state._apply_attack`): misses, then `hits × take_damage(per_hit)`, bailing on death. Juice (SFX, damage numbers) hangs off per-hit signals.
- **Preview exactness is a design pillar** (GDD §1.2 pillar 2, ui-spec T1 "previews are exact and labeled as exact"). Any effect architecture that makes the preview lie is wrong regardless of its other merits.
- The effect catalogue is still unknown. The owner's stress-test example — *"deal 1 additional for every damage instance that dealt an odd integer"* — is per-hit-conditional, which today's model cannot even express: damage instances are not reified anywhere. `compute_outcome` returns a closed formula (`per_hit`, `hits`, `total`); `_apply_attack` re-derives the instances at application time. There is no list for an effect to inspect.

Forces: catalogue open-ended and unknown; preview exactness non-negotiable; solo project (machinery has carrying cost); mutual-kill semantics deliberately undecided (no idea yet what can proc mid-attack).

## Decision

Split the commitment into what the evidence already forces and what it doesn't:

**1. COMMIT — the per-hit resolve ledger (the seam).**
Resolution produces an explicit, ordered list of damage instances per side — a *ledger* (e.g. `[{amount, ...}, ...]` plus miss entries) — built **purely** inside the resolve step. `_apply_attack` becomes a verbatim replayer: walk the ledger, apply each instance to `Hp`, emit the juice signal, bail on death (death-bail = clamp semantics, unchanged). Effects, whatever machinery they end up using, intercept **ledger construction only** — never application.

- This is the minimum shape that makes per-instance effects expressible at all (the odd-integer relic becomes a map over ledger entries).
- It preserves preview exactness for free: the preview runs the same pure ledger build, so every *deterministic* effect previews exactly. (Today the ledger is trivially `hits × per_hit` — uniform. Its value is being the stable interface effects mutate.)
- Total/deal/take derive from the ledger (sum), not from `base×mult` — the identity becomes a special case, not a load-bearing assumption.

**2. DEFER — the effect machinery, until a relic prototype pass.**
Do NOT scaffold ADR-001's `Effect`/`Event`/`EffectPipeline` yet. Instead, prototype 3–5 real relics as **bare functions** over the ledger build on a branch, chosen to span the behavior classes: the odd-instance relic (per-instance conditional), skip-highest-reroll (round-start transform), swap-lock (action gate), on-hit-gain-shield (reaction). Let their actual shapes pick the machinery — pipeline (ADR-001 C), plain ordered function list, or hybrid (ADR-001 B). The pipeline remains the leading candidate; it just doesn't get built on prediction.

**3. STAY UNDECIDED — explicitly.**
Mutual-kill/tie semantics (parked since 2026-06-25) stay parked: nothing is known yet about what can proc mid-attack. Nondeterministic/reactive effects' preview policy (badge? restrict early relics to deterministic?) is decided when the first such relic is proto'd, not before. Event taxonomy (`RollEvent`, `MoveEvent`, ...) is reified per-seam only when a proto'd effect forces that seam.

## Options Considered

### Option A: Proceed with ADR-001 as written (build the pipeline now)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium–High upfront |
| Fit to evidence | Predicted, not demonstrated |
| Preview exactness | Unaddressed by ADR-001 (its events wrap actions, not the resolve ledger) |
| Risk | Machinery shaped by imagined relics; per-instance effects still inexpressible without the ledger anyway |

**Pros:** Decision already made; one mental model; unbounded openness on paper.
**Cons:** Builds ceremony before any consumer exists; ADR-001's own event list doesn't contain the thing the odd-relic needs (a damage-instance event/ledger); contradicts the project's proto-first lesson.

### Option B: Ledger seam now + proto-first machinery (**chosen**)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Low now (small resolve/apply refactor), machinery cost paid later with evidence |
| Fit to evidence | Commits only to what the stress-test example + preview pillar force |
| Preview exactness | Structural (shared pure ledger build) |
| Risk | Proto relics might demand a reshape of the ledger — acceptable, that's the point of protos |

**Pros:** Smallest irreversible step; per-instance effects become expressible; preview stays honest; machinery chosen against real relics.
**Cons:** Effects written as bare functions get rewritten once machinery lands; two-phase work.

### Option C: Pull-query hybrid now (ADR-001's option B)
Rejected for the same reason as A, mirrored: commits to *pre-cut seams* while the catalogue is unknown — the exact dimension we have no evidence on.

## Trade-off Analysis

The deciding force is epistemic honesty: the only requirement with concrete evidence is "per-instance conditional effects must be expressible" (owner's example) plus the standing preview pillar — both are satisfied by the ledger alone. Everything ADR-001 chose beyond that (priorities, PRE/POST phases, Resource effects) answers questions no real relic has asked yet. The proto pass converts those questions from predictions into observations at the cost of rewriting a handful of bare-function relics — cheap, and exactly the trade the UI rework already proved worthwhile.

## Consequences

- **Easier:** per-instance effects; exact previews under effects; juice stays signal-driven (replay emits per instance); balance sim can mirror the ledger cheaply.
- **Harder:** resolve/apply refactor touches the FSM's most trafficked path (`compute_outcome`, `_apply_attack`, damage-number publishing) — needs the §8 screenshot pass after; totals must everywhere derive from the ledger.
- **Revisit:** machinery ADR (ADR-003) after the proto pass; mutual-kill when a mid-attack proc first exists; preview badge policy at the first nondeterministic relic.

## Action Items

1. [ ] Mark ADR-001 Superseded (analysis + pattern lineage remain referenced).
2. [ ] Ledger refactor on a branch: `compute_outcome` → returns per-side ledgers (+ derived totals); `_apply_attack` → replay-only; damage-number/blocked publishing reads the ledger. Verify: run_log deltas unchanged, §8 screenshots, sim spot-check A/B/C still hand-verifiable.
3. [ ] Mirror the ledger in `balance_sim.py` resolve() (keep KEEP-IN-SYNC scope honest).
4. [ ] Proto pass: odd-instance relic, skip-highest, swap-lock, on-hit-shield as bare functions; write up what shapes they forced.
5. [ ] ADR-003: choose machinery from the proto evidence.
