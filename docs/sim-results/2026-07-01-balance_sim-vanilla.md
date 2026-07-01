# balance_sim run — 2026-07-01 (vanilla / baseline, N=2000)

Raw output committed per CLAUDE.md rule 4. Vanilla = `cfg_baseline` (start_hp 20, `BASE_GAUNTLET`, no relics). Requested as a fresh 2000-run pull + history check.

- **Script:** `tools/balance_sim.py`
- **Version:** sha `41ed8788dfe7`, 307 lines
- **Seed:** summary `seed=7`, N=2000 — deterministic, re-runnable
- **Run by:** Code Claude (sim runs are Code's lane)
- **Caveat (script header):** `BASE_GAUNTLET` is hand-copied from the `.tres` + `pattern.gd` defaults — if a pattern/HP changes, update the table or numbers drift. AI is greedy 1-ply (optimal-ish) → win% is a strong *floor*.
- **⚑ KEEP IN SYNC flag:** the sim still models a **forced move ("no pass")** each round (`best_move` never considers a no-op). The GDD was just revised (2026-06-30/07-01) to **allow passing** by default. Numeric impact is negligible (the greedy AI takes the best rotate/swap anyway; passing rarely beats a move), so this vanilla number stands, but the sim's model comment + `best_move` should add a pass option whenever the sim is next revised. (Reroll-each-round already matches the game as of the per-round-reroll fix.)

## Result

```
# balance_sim.py  sha 41ed8788dfe7  |  run 2026-07-01  |  summary seed=7 N=2000

=== 2000 runs | optimal-ish (1-ply) | overall win 76.3% ===
fight      reached% cleared% kills-you% avgHPin avgHPcost rounds
Alligator     100.0    100.0        0.0    20.0       2.9    2.0
Ghost         100.0     98.7        1.3    17.1       4.0    1.8
Alien          98.7     97.8        2.1    13.1       0.8    1.1
Slime          96.5     79.0       20.2    12.4       5.8    2.5
win HP: avg 7.8, min 1; wins finishing <=5 HP: 38.3%
Slime clear vs HP-on-arrival: [1-8: 51%] [9-12: 85%] [13-16: 87%] [17-20: 93%]
```

## History comparison (vanilla)

| Run | N | overall win% | win HP avg | <=5 HP wins | Slime kills-you% |
|-----|---|-------------|-----------|-------------|------------------|
| 2026-06-12 (summary) | 10000 | 76.1 | 8.0 | 36.8% | 20.0 |
| 2026-06-12 (sweep `baseline`) | 5000 | 75.3 | 8.0 | 36.4% | — |
| **2026-07-01 (this)** | 2000 | **76.3** | 7.8 | 38.3% | 20.2 |

Stable across runs — no balance drift since 2026-06-12 (expected; the gauntlet table is unchanged). Slime remains the sole real threat (~20% of runs die there; ~79% clear).
