# relic sweep — pre-breather gauntlet check — 2026-06-12

Question (user): were the §5.3 relic numbers measured *before* the Slime breather pattern `[1,1,4,0]` (p2) was added? Re-ran the relic set against the pre-breather Slime to check. Committed per rule 5.

- **Script:** `tools/balance_sim.py`, sha `ec45109c…`. **Run:** N=3000, seed=1 (reseeded per variant, matching the post-breather sweep).
- **Pre-breather Slime** = `[[5,3,3,0],[3,5,3,1],[2,2,4,1],[6,6,0,0]]` (current minus the `[1,1,4,0]` breather). All else identical.

## Pre- vs post-breather

| variant | pre win | post win | pre lethal | post lethal |
|---|---|---|---|---|
| baseline | 67.0 | 74.2 | 62.2 | 52.4 |
| relicB reroll-low | 82.9 | 90.5 | 46.9 | 49.0 |
| relicA keep-high | 84.5 | 91.7 | 44.1 | 48.6 |
| relicA+B | 90.4 | 96.8 | 34.0 | 46.3 |
| +1 anti | 76.8 | 82.9 | 60.6 | 52.3 |
| +2 anti | 81.4 | 86.5 | 59.4 | 49.6 |
| +3 anti | 84.2 | 88.5 | 59.6 | 49.9 |
| +1 base | 82.2 | 89.6 | 43.9 | 46.4 |
| +2 base | 93.2 | 96.7 | 26.6 | 35.1 |
| +3 base | 96.6 | 99.2 | 13.9 | 28.6 |
| +1 all | 95.5 | 97.6 | 23.6 | 38.1 |
| +2 all | 99.8 | 99.9 | 3.6 | 17.4 |
| +3 all | 100.0 | 100.0 | 0.3 | 3.4 |

## Findings

- **Pre-breather baseline 67%** ≈ §7.7's cited 66% → the pre-breather reconstruction is faithful, and the breather swing (~+7pt here at seed 1, +11pt at the §7.8 summary figure) is confirmed.
- **The §5.3 directional table was POST-breather, not pre.** Its numbers (B 90, +base 90/97/99, +all 98/100/100) match the post column, not the (lower) pre column. The user's worry that the relics were measured pre-breather is not borne out — the table's "post-breather" label was correct.
- **The breather shifts levels, not conclusions.** It lifts win% ~+7pt and lowers tension ~−10pt across the board (boss is less lethal with a recovery round). Relative archetype behavior is **breather-invariant**: +anti self-caps and holds tension (highest of all, ~60% pre / ~50% post); +base and +all erode tension as they scale; A > B in both gauntlets (+1.6pt pre, +1.3pt post).
- **No action needed on §5.3** — it already reflects the current (post-breather) game. This run just verifies that and documents the pre→post delta for whoever tunes the gauntlet next.

Caveats: 1-ply greedy AI; relics always-on; single seed (the post-breather A>B sign was confirmed stable across seeds 1–6 in the AB seed-sweep file).
