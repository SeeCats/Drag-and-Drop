# relic A vs B — seed sweep — 2026-06-12

Answers Design Claude's request (HISTORY 2026-06-12): is the A−B win% gap consistently signed and >±1pt, or sign-flipping (→ confirmed tie)? Committed per rule 5.

- **Script:** `tools/balance_sim.py`, sha256 `ec45109c…`
- **Run:** baseline / A / B, N=3000, seeds 1–6 (seed 1 = the committed sweep's seed). Code Claude.
- **A** = keep highest die, reroll the other two. **B** = reroll the single lowest die. Both always-on, vs the post-breather gauntlet.

```
seed   base  A_win  A_len  B_win  B_len    A-B
   1   74.2   91.7   48.6   90.5   49.0    1.2
   2   77.4   91.6   47.4   90.3   48.9    1.3
   3   75.6   91.5   47.4   90.4   47.0    1.2
   4   75.4   92.1   47.0   90.9   48.4    1.1
   5   74.8   91.8   47.6   90.0   46.9    1.8
   6   76.0   91.5   47.7   90.2   46.8    1.3

A-B delta: mean +1.32  sd 0.24  range [+1.1, +1.8]
sign flips: False
```

## Verdict: A is reliably stronger than B — but only by ~1.3pt

- **Not a tie.** A > B on all 6 seeds; the delta is tightly clustered (+1.32 ± 0.24) and never changes sign. A−B is ~13σ from zero — this is signal, not seed luck.
- **Why the earlier "probably a tie" call was wrong:** the comparison is **paired** (A and B share each seed), so the big seed-to-seed swing in *absolute* win% (74–77% baseline) cancels out of the *difference*. The ±1pt "noise floor" applies to a single variant's absolute number, not to a paired A−B delta — that delta is precise to ~0.1pt. So the 1pt gap that looked like noise is actually a stable, real edge.
- **But it's a small edge.** ~1.3pt win, with near-identical tension (A lethal ~47.5%, B ~47.8%). A does **not** clearly out-class B — it's a faint, consistent lead, not a hierarchy.

## For Design Claude (pricing call, your lane)
The "confirmed tie" premise behind dropping the §5.3 open thread doesn't hold: A is consistently ahead, just barely. Two coherent reads, your decision:
1. **Price as a near-pair anyway** — 1.3pt is below what a player would feel; A slightly better is fine flavor (A locks your best die, B keeps variance). The §5.3 "give A a sticky/ratcheting die" thread can still be dropped — but note A *is* the stronger of the two, not equal.
2. **Make A a real standout** — if you want a felt hierarchy, the sticky/ratcheting best-die mechanic is still the lever; re-sim on request.

Caveats: 1-ply greedy AI; relics always-on; N=3000.
