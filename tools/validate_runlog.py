#!/usr/bin/env python3
"""
validate_runlog.py - integrity checker for user://run_log.jsonl.

Reconstructs every round through the resolver (mirrors CurrentRoll.compute_outcome,
ledger form per ADR-002) and cross-checks the logged numbers. Catches: resolver drift
between game and tools, HP-chain breaks, swap reveals that don't match the dice, and
rotate actions that don't match the shift they claim.

HOW TO RUN
  python3 tools/validate_runlog.py [path-to-run_log.jsonl]
  Default path: %APPDATA%/Godot/app_userdata/Drag_Drop/run_log.jsonl (Windows).

CHECKS PER ROUND
  - deal/take == resolver output from `after` dice + `monster_roll` (exact when the
    victim survived; clamped-not-exceeding when someone died — HP floors at 0).
  - kill-skip: monster died -> take == 0.
  - swap: `after[to]` value == the logged `rerolled` reveal.
  - rotate: `after` == `start` cycled by the claimed shift. Both schemas accepted:
    {"from","to"} (2026-07-06 input rework) and legacy {"dir"}.
  - HP chain: round hp_before == previous round hp_after; fight hp_in == first
    hp_before; hp_out == last player hp_after; cleared/died final_hp consistent.

Exit code 0 = all clean (CI-friendly); 1 = any violation.
"""

import json
import os
import sys

E = {"RED": 0, "GREEN": 1, "BLUE": 2, "WHITE": 3}
PMIN = [1, 1, 0, 0]
MMIN = [1, 1, 0, 0]


def resolve(pr, mr):
    """Mirror of CurrentRoll.compute_outcome: anti both ways on copies, ledger totals."""
    p, m = pr[:], mr[:]
    m[p[3]] = max(m[p[3]] - p[2], MMIN[p[3]])
    p[m[3]] = max(p[m[3]] - m[2], PMIN[m[3]])
    return sum([p[0]] * p[1]), sum([m[0]] * m[1])


def rotate_shift(action):
    """Slots the values moved right, from either rotate schema."""
    if "to" in action:
        return (action["to"] - action["from"]) % 3
    return 1 if action.get("dir", 1) >= 0 else 2


def check_round(rd, problems, where):
    vals = [d[0] for d in rd["after"]]
    els = [E[d[1]] for d in rd["after"]]
    raw_deal, raw_take = resolve([vals[0], vals[1], vals[2], els[2]], rd["monster_roll"])
    m_died = rd["hp_after"]["monster"] == 0
    p_died = rd["hp_after"]["player"] == 0
    healed = rd.get("healed", 0)  # mid-round HP gains (effects) offset the apparent take

    if m_died:
        if raw_deal < rd["deal"]:
            problems.append(f"{where}: kill deal {rd['deal']} exceeds resolver {raw_deal}")
        if rd["take"] != max(-healed, 0):
            problems.append(f"{where}: monster died but take={rd['take']} (kill must skip counter)")
    else:
        expected_take = max(raw_take - healed, 0)
        if raw_deal != rd["deal"]:
            problems.append(f"{where}: deal {rd['deal']} != resolver {raw_deal}")
        if p_died:
            if expected_take < rd["take"]:
                problems.append(f"{where}: death take {rd['take']} exceeds resolver {expected_take}")
        elif expected_take != rd["take"]:
            problems.append(f"{where}: take {rd['take']} != resolver {raw_take} - healed {healed}")

    action = rd["action"]
    if action["type"] == "swap" and rd["after"][action["to"]][0] != action.get("rerolled"):
        problems.append(f"{where}: swap reveal {action.get('rerolled')} != after[{action['to']}]")
    if action["type"] == "rotate":
        sh = rotate_shift(action)
        expected = [rd["start"][(i - sh) % 3] for i in range(3)]
        if rd["after"] != expected:
            problems.append(f"{where}: rotate {action} doesn't match start->after shift")


def check_run(idx, run, problems):
    php = run["start_hp"]
    for f in run["fights"]:
        where_f = f"run{idx} {f['monster']}"
        if f["rounds"] and f["rounds"][0]["hp_before"]["player"] != f["hp_in"]:
            problems.append(f"{where_f}: hp_in {f['hp_in']} != first hp_before")
        if f["hp_in"] != php:
            problems.append(f"{where_f}: hp_in {f['hp_in']} != carried hp {php}")
        prev = None
        for j, rd in enumerate(f["rounds"]):
            where = f"{where_f} rd{j}"
            if prev is not None and rd["hp_before"] != prev:
                problems.append(f"{where}: hp_before != previous hp_after")
            check_round(rd, problems, where)
            prev = rd["hp_after"]
        if f["rounds"]:
            last = f["rounds"][-1]["hp_after"]["player"]
            if f["hp_out"] is not None and f["hp_out"] != last:
                problems.append(f"{where_f}: hp_out {f['hp_out']} != last hp_after {last}")
            php = last
    if run["outcome"] == "died" and run["final_hp"] != 0:
        problems.append(f"run{idx}: died but final_hp={run['final_hp']}")


def default_path():
    appdata = os.environ.get("APPDATA", "")
    return os.path.join(appdata, "Godot", "app_userdata", "Drag_Drop", "run_log.jsonl")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else default_path()
    if not os.path.exists(path):
        print(f"no run_log at {path}")
        return 1
    runs = [json.loads(line) for line in open(path, encoding="utf-8")]
    problems = []
    for idx, run in enumerate(runs):
        check_run(idx, run, problems)
        rounds = sum(len(f["rounds"]) for f in run["fights"])
        print(f"run{idx:3d} {run['ts']}  {run['outcome']:9s} died_to={str(run['died_to']):9s} "
              f"final_hp={run['final_hp']:3d} rounds={rounds}")
    print(f"\n{len(runs)} runs, {sum(sum(len(f['rounds']) for f in r['fights']) for r in runs)} rounds checked")
    if problems:
        print(f"PROBLEMS ({len(problems)}):")
        for p in problems:
            print(" -", p)
        return 1
    print("ALL CLEAN")
    return 0


if __name__ == "__main__":
    sys.exit(main())
