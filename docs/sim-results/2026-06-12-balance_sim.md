# balance_sim run — 2026-06-12

Raw output committed per CLAUDE.md shared rule 5 (sim output cited in GDD/spec decisions must have its raw run on file). These numbers back the playtest-wave1 findings, GDD §5.3/§7.7/§7.8, and the relic-lever discussion (one_time_shield as the strongest validated shape).

- **Script:** `tools/balance_sim.py`
- **Version:** sha256 `8b64b2c41b42f269…`, 263 lines
- **Seeds:** summary `seed=7` (N=10000), sweep `seed=1` (N=5000 each) — deterministic, re-runnable
- **Run by:** Code Claude (cross-lane exception this session; per rule 5 this is normally Design Claude's to commit)
- **Caveat (from the script header):** `BASE_GAUNTLET` is hand-copied from the `.tres` files incl. `pattern.gd`'s hidden defaults — if a pattern `.tres` or HP changes, update the table or these numbers drift. The AI is greedy 1-ply (optimal-ish), and is itself a "racer," so it cannot detect kill-skip racing fixes.

```
=== spot check (hand-verifiable resolution) ===
 A (4, 16, False, 16, 4) GREEN cuts mult 5->2; armor1 cuts base 5->4 => deal 16, take 4
 B (-4, 20, True, 24, 0) BLUE strips anti 4->1; evasion cuts mult 5->4 => deal 24, KILL
 C (-26, 20, True, 36, 0) no anti => deal 36, KILL

=== 10000 runs | optimal-ish (1-ply) | overall win 76.1% ===
fight      reached% cleared% kills-you% avgHPin avgHPcost rounds
Alligator     100.0    100.0        0.0    20.0       2.9    2.1
Ghost         100.0     98.8        1.2    17.1       4.0    1.8
Alien          98.8     97.3        2.7    13.1       0.8    1.1
Slime          96.1     79.2       20.0    12.5       5.7    2.5
win HP: avg 8.0, min 1; wins finishing <=5 HP: 36.8%
Slime clear vs HP-on-arrival: [1-8: 50%] [9-12: 82%] [13-16: 89%] [17-20: 94%]

=== sweep (5000 runs each) ===
variant              win%  avgHP  <=5HP%  1more-lethal%
baseline             75.3    8.0    36.4           51.3
HP_up_26 (level)     88.6   11.6    20.2           41.1
partial_heal_14      87.4    9.3    19.1           48.6
ghost_peak_nerf      79.9    8.1    35.0           52.5
one_time_shield      88.2    7.0    45.4           57.4
shield+ghostnerf     91.3    7.3    43.1           56.0
1more-lethal% = of WINS, the boss's next attack (unmitigated) >= your finishing HP
GOAL: raise win% while HOLDING/RAISING 1more-lethal%. (HP_up is the bad lever.)
```
