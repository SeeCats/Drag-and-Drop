# Run-log counterfactual analysis — monster anti_type, tension rounds, price-refusal

**Author:** Design Claude, 2026-07-02.
**Data:** `2026-07-02-run_log.jsonl` (committed alongside) — 11 real runs by the designer, 2026-07-01 12:14–12:47, 91 rounds, fixed monster order (Alligator→Ghost→Alien→Slime) and fixed monster rolls. 9 cleared / 2 died (both to Slime, both entering at ≤7 HP).
**Method:** the resolver was reconstructed from `compute_outcome` semantics (player anti cuts monster at the ANTI die's color index, then the monster's *updated* anti cuts the player; floors [1,1,0]). **Validation: 0 mismatches against all 91 logged rounds** (logged `deal`/`take` are HP-capped; comparison done only where uncapped). Main script committed as `2026-07-02-analyze_antitype.py`; the two follow-up scripts are inlined below. Not `balance_sim.py` — this is play-data analysis (n=1 player, the designer), so treat rates as indicative, not tuned truth.

---

## 1. Does monster anti_type (armor=0 vs evade=1) matter? — YES, mechanically; NO, as a conscious read

This **overturns** the prior-session claim "type is a phantom / proven no-op / 0-of-91 empirical" (that figure was asserted, never computed). The symmetry proof behind it is correct *over all 6 dice arrangements* — but rotate only reaches 3 of them deterministically; the other 3 (odd permutations) cost a swap + reroll. The type decides which parity half your optimum lives in.

Of 78 rounds with monster anti > 0, flipping armor↔evade changes:

| Metric | Result |
|---|---|
| deal on the hand the player actually committed | **37/78 (47%)**, Δ up to ±6 |
| best pass/rotate option's value | **22/78 (28%)**, mean \|Δ\| ≈ 2.5 on deals of ~5–25 |
| which action is best | 6/78 (~8%) |
| whether a deterministic kill is reachable this turn | **4/78 (~5%)** |

Consequences: (a) "removing a proven no-op cannot shift balance by definition" is **false** — scalar-izing the type is a real rebalance; (b) the player *does* play around the type constantly, but via the DEAL preview (§7.4: UI does the arithmetic), never as a named read.

**Design verdict (Design lane): keep the mechanic, kill the fantasy.** Keep field + resolver; rewrite §6.2 so the type is framed as outcome-shaping math the preview carries, not a player diagnosis skill; demote UI vocabulary to flavor. §6.2 edit drafted, **not yet applied** (pending user approval).

## 2. The number-vs-color tension (§3.5) — real, frequent, and resolved by gambling

Of 91 rounds: 41 race turns (deterministic kill reachable — take irrelevant, correctly tension-free), 19 with one rotation dominating both axes (§7.4 rest beats), and **31 genuine tension rounds** (deal-max rotation ≠ take-min rotation, non-lethal) — 62% of non-race turns.

Stakes: picking best-defense sacrifices mean **6.8 deal** (max 18); picking best-offense eats mean **4.4 extra HP** (max 12), on a 20 HP pool.

Player resolution in tension rounds: offense-side 2, defense-side 7, neither 1, **swapped 21** — the dominant response is to gamble out of the dilemma (partly via the "evict-keep" move below, which gets formation + dig in one action).

## 3. Swap usage and the never-paid price

48 swaps total. Grabbed-die values: **31×1, 14×2, 3×3 — zero swaps ever rerolled a 4+.** Policy by hand minimum: min=1 → swap 79%; min=3 → swap 1/15; min≥4 → never.

Breakdown: 15 swapped the two attack dice (anti color preserved, pure dig); 14 grabbed the anti occupant and dropped it on the desired die (desired color enters ANTI *value intact*, reject rerolls — the "evict-keep" move); 19 rerolled into the anti slot (anti value gambled).

**Finding:** the designed moment "the best formation costs rerolling a keeper" (odd-parity arrangements pricing at a good die's reroll) **fired 0 times in 91 rounds of the designer playing.** Either the payoff (ordering gain ≈ anti×|x−y|, the invisible §1 effect) never clears the price (reroll of a 4/5 ≈ −1..−1.5 EV + variance), or loss-aversion/legibility blocks a sometimes-correct play. Undetermined — sim question below.

## 4. Sim requests for Code Claude (rule: Design specifies, Code runs)

1. **anti_type policy value:** across the gauntlet at N=thousands, does flipping monster anti_type change optimal-policy win% / lethal-margin%? (Grounds the "keep vs scalar-ize" call beyond n=1 play data.)
2. **Tension-round policies:** in non-lethal tension states (deal-max ≠ take-min over rotations), compare (a) always-swap/gamble-out, (b) take best horn, (c) always evict-keep, (d) grab-min-only — win% + lethal-margin%. Is gamble-out dominant (a §6.2-guardrail-1 problem) or situational?
3. **Pay-a-keeper EV:** policy that grabs 4+ dice when formation/ordering gain clears reroll EV vs. grab-min-only. Report how often it pays and the win% it buys. If ≈0, the designed moment is dead at current numbers and monster anti needs teeth; if positive, the moment is alive-but-hidden (presentation problem, not tuning).

## Inlined follow-up scripts

```python
# tension rounds (metric 2): options = 3 rotations of start; tension = deal-max != take-min, non-lethal
# player choice classified vs. the frontier; swaps counted as "gambled out"
# (full outcome() identical to 2026-07-02-analyze_antitype.py)
dmax = max(opts.values(), key=lambda v: v[0]); tmin = min(opts.values(), key=lambda v: v[1])
lethal = dmax[0] >= hp_monster
tension = (not lethal) and best_deal_key != best_take_key and no option is max-deal AND min-take
```

```python
# swap usage (metric 3): per swap, grabbed value = start[from][0]
# anti involvement: 2 in (from, to); "evict-keep" = from==2 (grabbed anti occupant);
# "reroll into anti" = to==2; else non-anti pair (formation preserved)
```

*(Exact runnable versions of both are trivial re-derivations from the committed main script; kept abbreviated here to stay readable.)*
