# Crit tree draft + machinery requirements ledger (Code handoff)

**Author:** Design Claude, 2026-07-15. **Status:** first specialty catalog, drafted as a *machinery probe* (ADR-002 proto-first method applied to content). Numbers are placeholders by explicit owner decision — "balance later"; the **laws are architecture, not tuning**, and are canonical (GDD §8.5). Written for a cold Code-session read.

---

## 1. The crit concept (owner's design)

Crit is **not** a damage multiplier roll at resolution. A **mark** lands on a die or a slot at round start (proc/clock), is **visible all planning phase**, and the player exploits it through arrangement — *the mark is rolled, the exploitation is planned.* Variance lives in where the mark lands; determinism in what you do about it. Preview-exact by construction (marks apply via the PROJECT_ROLL seam, which already wraps both preview and publish).

- A marked **die** carries its bonus wherever it goes — the mark **travels** through swaps/rotations.
- A marked **slot** is furniture — whatever value sits there gets the bonus.
- The **alignment game** (steer a marked die into a marked slot; both bonuses apply, additive) emerges from the commons — no keystone required.
- Render: bonus = ghost pips (a +3 mark shows three); die-marks and slot-marks need **distinct visual channels**.

## 2. The tree (tiers = catalog bands; charges in parentheses; all numbers first-pass epoch-2)

**Common**
- **Glint** — 5/10/15% chance per round (by charge 1/2/3) to mark a random **die**.
- **Hotspot** — 5/10/15% chance per round to mark a random **slot**. *(Anti-slot Hotspot = defensive crit — keep; nobody does defensive crit.)*
- Marks grant **+1** base.

**Magic**
- **Mark power** — marks grant +1/+2/+3 (raises the mark bonus; the "+1 quantum" law was repealed here, magnitude is tier-gated instead).
- **+Die chance** — +5/10/15% to die-mark chance.
- **+Slot chance** — +5/10/15% to slot-mark chance. *(Running both pools is the intended smart-player line: overlap rounds = alignment play.)*

**Rare**
- **Double-apply** — marks have 20/40/60% chance to apply twice (semantics pin pending: bonus counts double on its application).
- **Die clock** — one additional guaranteed die-mark every 5/4/3 rounds.
- **Slot clock** — one additional guaranteed slot-mark every 5/4/3 rounds. *(Clock laws apply: auto-stagger, auto-fire.)*
- **Contagion** — swapping a marked die also marks the swap partner. **Commit-only** (rotate_heal law — staging must not fire it; farming risk), staged spread shown as **ghost mark**. Note: this node revives the dead "pay a keeper" moment (0/48 in the epoch-1 logs) — first real reason to swap a good die.

**Keystone**
- **Constellation** (~charge 5) — every die and every slot rolls mark chance independently (up to 6 marks/round). Amplifier-class: worthless solo, ~6× on invested chance. Endgame convergence ≈ reliable +N everywhere ≈ the §5.3 "+all" shape — sanctioned as the short-lived summit build by owner ruling. *(Open: keep slot-marks single-roll as residual scarcity?)*
- **Retention** (~charge 5) — marks have 20/40/60% chance to not be consumed on use.

## 3. Mark lifecycle (machinery)

Marks are micro-entities with a three-phase lifecycle, and nodes hook different phases:
**created** (procs, clocks, contagion) → **applied** (at resolution; possibly twice) → **consumed or retained**.
Engine needs mark-phase hooks (created/applied/consumed) as dispatchable moments — the effect pipeline recursing one level down.

**Ecology:** Retention + clocks + contagion make mark population a birth-death process with a steady state (inflow: procs+clocks+player-pumped contagion; outflow: consumption × (1−retention)). In the new long-fight regime this gives fights an **internal arc** (sparse early → saturated late) with zero authored escalation. Equilibrium is closed-form checkable.

## 4. Requirements ledger — what this catalog demands from the engine

1. **Boost layer** (the big one): aggregated derived stats (`mark_power`, `die_mark_chance`, `slot_mark_chance`) that multiple effects contribute to, queried at proc/creation time. This is ADR-003's predicted "pull-aggregated Boosts" escape hatch — first content demanding it. Events for actions, **boosts for stats**.
2. **Mark state**: per-round transient state on dice and slots; value-carrying (`{target, value}`); rendered; cleared per persistence scope (ruling pending).
3. **Die identity**: die-marks must travel through swaps/rotations, but the controller holds `_values[]`/`_elements[]` by position — needs **per-die metadata transported by every verb** (parallel arrays shuffled in lockstep, or identity-bearing dice).
4. **Marks survive rerolls** (identity ≠ value; makes "reroll the marked die" a deliberate play).
5. **Projection awareness**: PROJECT_ROLL reads marks so +N lands identically in preview and publish (rides existing seam).
6. **Verb-reactions at commit only**, with **ghost-preview** of pending mark mutations (Contagion is the first customer).
7. **Per-entity proc rolls** (Constellation — trivial loop).
8. **Charge as runtime field** on Effects (`charge`, authored-start convention) + per-node `value_at(charge)` scaling hook.
9. **Mark-phase lifecycle hooks** (§3).
10. **All procs logged** (mark rolls, retention rolls, double-applies) or `validate_runlog.py` goes blind to +N deltas.
11. **Render channels**: die-mark vs slot-mark distinct; pip-count = value; ghost/pending state; **merged saturation treatment** at high mark counts (six simultaneous glows on a 3-column tray = nothing glows).

## 5. Laws pinned this sprint (canonical in GDD §8.5; listed here for the implementer)

- Marks never stack on one target — they **spread** (redundant mark redirects to an unmarked target; fizzle if none).
- Stacking law: copies = frequency/coverage, never magnitude; author every node **at the stack** (sim 1/3/6 copies) and sim each charge curve.
- Clock auto-stagger; ripe clocks auto-fire (no ready-state warehousing).
- Closed verb set: no new inputs; "aiming" exists only as verb-reactions (Contagion).
- Commit-not-staging for all verb reactions.
- Exclusion graph enforced on the item; legendary/relational effects never enter tree catalogs.

## 6. Rulings pending (owner)

1. **Mark persistence scope** — round-scoped kills Retention; fight-scoped (Design lean: keeps the ecology arc per-fight, avoids pre-lit boss openings) vs run-scoped (resonance carryover precedent argues for it).
2. **Apply-twice semantics** — pin as "bonus counts double" (vs "applies to two targets" = a different node).
3. **Constellation residual scarcity** — slot-marks stay single-roll?
4. **Rooms↔rounds exchange rate** (GDD §8.6.1) — gates *all* numbers here; the 5/10/15% chances imply fights of ~7–13 rounds if charge-3 should feel like a mark-or-two per fight.

## 7. Sim modes required (Code lane; per rule 4 commit outputs to docs/sim-results/)

- **Combination-context evaluation** — amplifier-class nodes (Constellation, and the chance×power×double-apply economy) cannot be priced solo.
- **Steady-state ecology** — retention/inflow equilibria across fight lengths.
- **Phase-aware clock composition** — harmonics (LCM rounds) enumerable; sanctioned-nova frequency should be a chosen number.
- **Stack curves** — every node at 1/3/6 copies; charge curves per node.
- Everything stamped **epoch-2**; epoch-1 tables (short-fight gauntlet) are historical — don't mix (§5.3 precedent).
