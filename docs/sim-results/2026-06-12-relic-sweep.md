# balance_sim relic sweep — 2026-06-12

Re-implements the hypothetical-relic variants that were lost with their session (the GDD §5.3 table was flagged "directional-unverified"). Committed per CLAUDE.md rule 5. **Verdict: the directional table is essentially confirmed** — every `+N` row lands within ~1pt; only relic A differs (see below).

- **Script:** `tools/balance_sim.py`, sha256 `ec45109c0a03b590…`
- **Run:** `report_sweep(N=3000, seed=1)`. (Default is N=5000, but all 19 variants at 5000 exceed the sandbox's 45s cap; N=3000 is stable to ~±1pt — `+N` rows reproduce the directional table almost exactly, which is the cross-check.)
- **Run by:** Code Claude (cross-lane sim commit; GDD §5.3 prose is Design Claude's to reconcile — see flag below).

## Relic models (how each is simulated, always-on)

- **+N base / +N anti / +N all** — flat buff added to the player's factor(s) every `resolve`; the AI plans with the buff. `+N all` = base+mult+anti each +N (multiplicative, uncapped). `+2 base cap6` clamps the buffed factor at 6 to test the cap claim.
- **relic B "reroll low"** — each round, reroll the single lowest die once and keep the result (mulligan the worst die).
- **relic A "keep high"** — each round, keep the single highest die and reroll the other two (**user-chosen interpretation, 2026-06-12**: "reroll two lowest"). Note this makes A a per-round hand-quality boost roughly on par with B, *not* the lone standout the directional guess (95%) implied.
- **A+B** — A first (keep highest, reroll two), then B rerolls the lowest of the result.

## Output

```
=== sweep (3000 runs each) ===
variant              win%  avgHP  <=5HP%  1more-lethal%
baseline             74.2    7.9    36.7           52.4
HP_up_26 (level)     88.5   11.6    20.9           41.4
partial_heal_14      87.5    9.3    19.2           49.3
ghost_peak_nerf      78.9    8.0    35.8           52.8
one_time_shield      87.7    6.9    46.3           58.6
shield+ghostnerf     90.9    7.2    43.6           56.0
relicB rerollLow     90.5    9.6    28.2           49.0
relicA keepHigh      91.7    9.8    27.6           48.6
relicA+B             96.8   10.8    27.5           46.3
+1 anti              82.9    8.6    31.6           52.3
+2 anti              86.5    9.2    26.0           49.6
+3 anti              88.5    9.5    24.3           49.9
+1 base              89.6    9.7    29.5           46.4
+2 base              96.7   12.3    21.0           35.1
+3 base              99.2   14.2    19.8           28.6
+2 base cap6         96.0   11.7    21.5           38.8
+1 all               97.6   12.3    25.0           38.1
+2 all               99.9   17.0    12.4           17.4
+3 all              100.0   19.4     3.4            3.4
1more-lethal% = of WINS, the boss's next attack (unmitigated) >= your finishing HP
```

## Verified vs GDD §5.3 directional table

| Relic | directional win% | verified win% | directional tension | verified tension | verdict |
|---|---|---|---|---|---|
| B reroll-low | 90 | 90.5 | 49 | 49.0 | confirmed |
| A keep-high | 95 | **91.7** | 51 | 48.6 | **weaker than guessed; ≈ B** |
| A+B | 98 | 96.8 | 49 | 46.3 | confirmed |
| +N anti | 83/87/89 | 82.9/86.5/88.5 | 51/49/51 | 52.3/49.6/49.9 | confirmed (self-caps ~88) |
| +N base | 90/97/99 | 89.6/96.7/99.2 | 45/36/30 | 46.4/35.1/28.6 | confirmed |
| +N all | 98/100/100 | 97.6/99.9/100 | 38/16/3 | 38.1/17.4/3.4 | confirmed |

- **Design lessons hold:** floor-capped `+N anti` self-caps ~88% and preserves tension (~50%); `+N base` is strong but bleeds tension as it scales; `+N all` solves and guts tension; dice-quality relics (A/B) lift win% while holding tension ~48%.
- **6-cap barely matters (confirmed):** `+2 base` 96.7% vs `+2 base cap6` 96.0% = 0.7pt on win% (<1pt, as claimed). Tension moves a bit more (35.1→38.8).
- **One real correction for Design:** under the chosen "reroll two lowest" model, relic **A (91.7%) is ~tied with B (90.5%)**, not the +19pt standout the lost guess implied. If A is meant to be the strongest single dice relic, the mechanic needs to be stronger than "keep one, reroll two" (e.g. a sticky/ratcheting best die).

## Caveats
1-ply greedy AI (a floor); relics modelled always-on; vs the post-breather gauntlet. Baseline here 74.2% (N=3000) vs §5.3's cited 76% — within MC/seed variance.
