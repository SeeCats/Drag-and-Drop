#!/usr/bin/env python3
"""
balance_sim.py - Monte-Carlo balance simulator for Project Drag N Drop.

WHAT IT IS
  A faithful, headless port of the *combat math only* (no Godot needed). It
  reproduces CurrentRoll.anti_operator(), the 3-dice / 3-slot / rotate+swap
  model, the cyclic monster patterns, and the persistent-HP gauntlet, then
  plays thousands of runs with an "optimal-ish" AI and reports statistics:
  win rate, per-fight HP cost, the attrition curve, boss clear vs. arriving HP,
  and a two-metric tuning sweep (win% vs. "one-more-round-lethal%").

  Use it to answer balance questions in seconds instead of playtest-weeks:
  "what's the win rate?", "how much HP does each fight cost?", "does raising
  HP fatten the margins?", "what lifts win% without killing the tension?"

HOW TO RUN
  python3 tools/balance_sim.py

WHAT IT MODELS (ground truth = the live .gd / .tres)
  - resolve(): player anti reduces the monster's roll at index = player anti_type
    (= colour of the die in the ANTI slot), floored by MMIN; then the monster's
    anti reduces the player's roll at index = monster anti_type, floored by PMIN.
    Both attacks are base*mult. Player attacks first; a kill skips the counter.
  - Floors PMIN = MMIN = [1,1,0,0]  (anti can be stripped to 0; base/mult floor at 1).
  - Player: 3 dice, fixed colours [RED,GREEN,BLUE], values re-rolled 1..6 each round.
    Two verbs, ONE per round (forced): rotate (cycle action labels) or swap
    (exchange two dice + RE-ROLL the picked-up die). No "pass".
  - Monsters: cyclic pattern_list; round N uses pattern[(N-1) % len]; HP persists
    across the gauntlet, no heal between fights.

KEEP IN SYNC  <-- IMPORTANT
  The GAUNTLET data below is hand-copied from the .tres files WITH pattern.gd's
  defaults applied (base=3, mult=4, anti=3, anti_type=0). If you change a monster's
  .tres or HP, update GAUNTLET to match or the numbers will be wrong.

CAVEATS (don't over-trust exact numbers)
  - The AI is a 1-PLY GREEDY: it always takes an immediately-reachable kill and
    defends sensibly, but it does NOT use the next-pattern lookahead to plan
    multi-turn setups. So win rates are a strong-but-not-perfect *floor*.
  - Relics are modelled as ALWAYS-ON (see report_sweep). Flat-stat relics
    (+N base/mult/anti) buff the player's factors every resolve and the AI plans
    around them; dice-quality relics (A keep-highest / B mulligan-worst) reshape
    the round's starting hand before the forced move. GDD §5.3 cites these.
"""

import random
import hashlib
import datetime
from statistics import mean

# ---- roll indices: [base, mult, anti, anti_type] ; colours RED=0 GREEN=1 BLUE=2
PMIN = [1, 1, 0, 0]
MMIN = [1, 1, 0, 0]

# ---- gauntlet (live .tres + pattern.gd defaults). Order = Encounter.monster_list.
#      pattern = [base, mult, anti, anti_type]
BASE_GAUNTLET = [
    ("Alligator", 24, [[1, 3, 2, 0], [3, 1, 2, 0]]),
    ("Ghost",     20, [[2, 5, 1, 0], [2, 2, 4, 1], [5, 2, 1, 0], [2, 2, 4, 0]]),
    ("Alien",     10, [[4, 4, 0, 0], [6, 6, 0, 0]]),
    # NOTE: slime has a "breather" round [1,1,4,0] after p1 (narratively the slime
    # winding up its mult) — telegraphed wind-up + fixes the burst variance.
    # p1 knocked down 5x3 -> 4x3 (user, 2026-07-06, system-testing phase; not sim-priced).
    ("Slime",     25, [[4, 3, 3, 0], [1, 1, 4, 0], [3, 5, 3, 1], [2, 2, 4, 1], [6, 6, 0, 0]]),
]
START_HP = 20


# ----------------------------------------------------------------------- model
def player_roll(color, action, value):
    """Map (colour[pos], action[pos], value[pos]) -> [base, mult, anti, anti_type]."""
    pr = [0, 0, 0, 0]
    for p in range(3):
        a = action[p]
        if a == 0:   pr[0] = value[p]
        elif a == 1: pr[1] = value[p]
        else:        pr[2] = value[p]; pr[3] = color[p]
    return pr


def resolve(pr, mr, mhp, php, relic=None):
    """One round. Returns (monster_hp, player_hp, killed, player_dmg, monster_dmg).
    relic: optional always-on flat-stat buff {base_plus,mult_plus,anti_plus,cap6}."""
    pr = pr[:]; mr = mr[:]
    if relic:                                         # flat-stat relics buff the player's factors
        pr[0] += relic.get('base_plus', 0)
        pr[1] += relic.get('mult_plus', 0)
        pr[2] += relic.get('anti_plus', 0)
        if relic.get('cap6'):                         # optional 6-cap (table's cap-vs-uncap check)
            pr[0] = min(pr[0], 6); pr[1] = min(pr[1], 6); pr[2] = min(pr[2], 6)
    mr[pr[3]] = max(mr[pr[3]] - pr[2], MMIN[pr[3]])   # player anti -> monster factor
    pr[mr[3]] = max(pr[mr[3]] - mr[2], PMIN[mr[3]])   # monster anti -> player factor
    # Damage LEDGER (ADR-002, mirrors CurrentRoll._side): per-hit instances, uniform
    # until effects vary them. Totals derive from the ledger, not base*mult.
    pdmg = sum([pr[0]] * pr[1])
    mh = mhp - pdmg
    if mh <= 0:
        return mh, php, True, pdmg, 0                 # kill -> no counter
    mdmg = sum([mr[0]] * mr[1])
    return mh, php - mdmg, False, pdmg, mdmg


def score(t):
    """Tiered score for the greedy policy: kill >> survive-and-progress >> death."""
    mh, ph, killed, pdmg, mdmg = t
    if killed: return 1e6
    if ph <= 0: return -1e6
    return (pdmg - mdmg) - max(0, 8 - ph) * 4         # net damage, defensive when low


def _rot_left(a):  return [a[1], a[2], a[0]]
def _rot_right(a): return [a[2], a[0], a[1]]


def best_move(color, action, value, mr, mhp, php, relic=None):
    """Pick the forced move (2 rotates + 6 swaps) with the best (expected) score."""
    bm, bv = None, -1e18
    for na in (_rot_left(action), _rot_right(action)):       # rotates: deterministic
        v = score(resolve(player_roll(color, na, value), mr, mhp, php, relic))
        if v > bv: bv, bm = v, ('rot', na)
    for i in range(3):                                       # swaps: expected over reroll
        for j in range(3):
            if i == j: continue
            tot = 0.0
            for r in range(1, 7):
                c = color[:]; val = value[:]; val[i] = r
                c[i], c[j] = c[j], c[i]; val[i], val[j] = val[j], val[i]
                tot += score(resolve(player_roll(c, action, val), mr, mhp, php, relic))
            if tot / 6 > bv: bv, bm = tot / 6, ('swap', i, j)
    return bm


def apply_move(mv, color, action, value):
    if mv[0] == 'rot':
        return color, mv[1], value
    _, i, j = mv
    c = color[:]; a = action[:]; val = value[:]
    val[i] = random.randint(1, 6)                            # reroll picked-up die
    c[i], c[j] = c[j], c[i]; val[i], val[j] = val[j], val[i]
    return c, a, val


def play_run(cfg):
    """Play one gauntlet. Returns dict of per-fight records + outcome."""
    php = cfg['start_hp']
    color, action = [0, 1, 2], [0, 1, 2]                     # RED/GREEN/BLUE ; BASE/MULT/ANTI
    shield = cfg.get('shield', False)
    relic = {k: cfg[k] for k in ('base_plus', 'mult_plus', 'anti_plus', 'cap6') if k in cfg} or None
    fights = []
    for name, mhp_max, pats in cfg['gaunt']:
        if name == "Slime" and cfg.get('preslime_floor'):
            php = max(php, cfg['preslime_floor'])            # partial top-up entering boss
        hp_in = php; mhp = mhp_max; midx = 0; rnd = 0
        while True:
            rnd += 1
            if rnd > 300:
                return {'fights': fights, 'status': 'timeout'}
            value = [random.randint(1, 6) for _ in range(3)]
            if cfg.get('keep_highest'):                      # relic A: keep top die, reroll other two
                hi = value.index(max(value))
                value = [v if k == hi else random.randint(1, 6) for k, v in enumerate(value)]
            if cfg.get('mulligan_worst'):                    # relic B: reroll the single lowest die
                value[value.index(min(value))] = random.randint(1, 6)
            mr = pats[midx % len(pats)]; midx += 1
            mv = best_move(color, action, value, mr, mhp, php, relic)
            color, action, value = apply_move(mv, color, action, value)
            mhp, php, killed, pdmg, mdmg = resolve(player_roll(color, action, value), mr, mhp, php, relic)
            if killed:
                nxt = pats[midx % len(pats)]                 # the round you skipped
                fights.append({'name': name, 'hp_in': hp_in, 'hp_out': php,
                               'rounds': rnd, 'next_unmit': nxt[0] * nxt[1]})
                break
            if php <= 0:
                if shield:
                    php = 1; shield = False                  # one-time last stand
                else:
                    fights.append({'name': name, 'hp_in': hp_in, 'hp_out': None, 'rounds': rnd})
                    return {'fights': fights, 'status': 'death', 'where': name}
        # fight cleared, continue gauntlet
    return {'fights': fights, 'status': 'win', 'final_hp': php}


# ------------------------------------------------------------------- reporting
def version_stamp():
    """Self-hash of this script so any committed/pasted output is pinned to a
    version (rule 5). Captures the GAUNTLET table too, since it lives in-file."""
    try:
        h = hashlib.sha256(open(__file__, 'rb').read()).hexdigest()[:12]
    except Exception:
        h = 'unknown'
    return f"# balance_sim.py  sha {h}  |  run {datetime.date.today().isoformat()}"


def cfg_baseline():
    return {'start_hp': START_HP, 'gaunt': BASE_GAUNTLET}


def report_summary(N=10000, seed=7):
    print(version_stamp() + f"  |  summary seed={seed} N={N}")
    random.seed(seed)
    order = [g[0] for g in BASE_GAUNTLET]
    reached = {n: 0 for n in order}; cleared = {n: 0 for n in order}
    deaths = {n: 0 for n in order}; cost = {n: [] for n in order}
    hp_in = {n: [] for n in order}; rounds = {n: [] for n in order}
    wins = 0; final_hp = []
    for _ in range(N):
        r = play_run(cfg_baseline())
        for f in r['fights']:
            hp_in[f['name']].append(f['hp_in']); rounds[f['name']].append(f['rounds'])
            if f['hp_out'] is not None:
                cost[f['name']].append(f['hp_in'] - f['hp_out'])
        if r['status'] == 'win':
            wins += 1; final_hp.append(r['final_hp'])
            for n in order: reached[n] += 1; cleared[n] += 1
        elif r['status'] == 'death':
            i = order.index(r['where'])
            for n in order[:i + 1]: reached[n] += 1
            for n in order[:i]: cleared[n] += 1
            deaths[r['where']] += 1
    print(f"\n=== {N} runs | optimal-ish (1-ply) | overall win {wins / N * 100:.1f}% ===")
    print(f"{'fight':10s} {'reached%':>8s} {'cleared%':>8s} {'kills-you%':>10s} "
          f"{'avgHPin':>7s} {'avgHPcost':>9s} {'rounds':>6s}")
    for n in order:
        cr = cleared[n] / reached[n] * 100 if reached[n] else 0
        ac = mean(cost[n]) if cost[n] else 0
        print(f"{n:10s} {reached[n]/N*100:8.1f} {cr:8.1f} {deaths[n]/N*100:10.1f} "
              f"{mean(hp_in[n]):7.1f} {ac:9.1f} {mean(rounds[n]):6.1f}")
    if final_hp:
        sliver = sum(1 for h in final_hp if h <= 5) / len(final_hp) * 100
        print(f"win HP: avg {mean(final_hp):.1f}, min {min(final_hp)}; "
              f"wins finishing <=5 HP: {sliver:.1f}%")
    # boss clear vs arriving HP
    random.seed(seed)
    win_in, loss_in = [], []
    for _ in range(N):
        r = play_run(cfg_baseline())
        for f in r['fights']:
            if f['name'] == 'Slime':
                (win_in if f['hp_out'] is not None else loss_in).append(f['hp_in'])
    allp = [(h, 1) for h in win_in] + [(h, 0) for h in loss_in]
    print("Slime clear vs HP-on-arrival:", end=" ")
    for lo, hi in [(1, 8), (9, 12), (13, 16), (17, 20)]:
        g = [c for h, c in allp if lo <= h <= hi]
        if g: print(f"[{lo}-{hi}: {mean(g)*100:.0f}%]", end=" ")
    print()


def report_sweep(N=5000, seed=1):
    def ghost_low_variance():
        g = [list(m) for m in BASE_GAUNTLET]
        g[1] = ("Ghost", 20, [[2, 4, 1, 0], [2, 2, 4, 1], [4, 2, 1, 0], [2, 2, 4, 0]])  # 10s->8s
        return g
    variants = {
        "baseline":          {'start_hp': 20, 'gaunt': BASE_GAUNTLET},
        "HP_up_26 (level)":  {'start_hp': 26, 'gaunt': BASE_GAUNTLET},
        "partial_heal_14":   {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'preslime_floor': 14},
        "ghost_peak_nerf":   {'start_hp': 20, 'gaunt': ghost_low_variance()},
        "one_time_shield":   {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'shield': True},
        "shield+ghostnerf":  {'start_hp': 20, 'gaunt': ghost_low_variance(), 'shield': True},
        # --- hypothetical relics (GDD §5.3), always-on, vs post-breather baseline ---
        "relicB rerollLow":  {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'mulligan_worst': True},
        "relicA keepHigh":   {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'keep_highest': True},
        "relicA+B":          {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'keep_highest': True, 'mulligan_worst': True},
        "+1 anti":           {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'anti_plus': 1},
        "+2 anti":           {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'anti_plus': 2},
        "+3 anti":           {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'anti_plus': 3},
        "+1 base":           {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 1},
        "+2 base":           {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 2},
        "+3 base":           {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 3},
        "+2 base cap6":      {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 2, 'cap6': True},
        "+1 all":            {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 1, 'mult_plus': 1, 'anti_plus': 1},
        "+2 all":            {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 2, 'mult_plus': 2, 'anti_plus': 2},
        "+3 all":            {'start_hp': 20, 'gaunt': BASE_GAUNTLET, 'base_plus': 3, 'mult_plus': 3, 'anti_plus': 3},
    }
    print(version_stamp() + f"  |  sweep seed={seed} N={N}")
    print(f"\n=== sweep ({N} runs each) ===")
    print(f"{'variant':18s} {'win%':>6s} {'avgHP':>6s} {'<=5HP%':>7s} {'1more-lethal%':>14s}")
    for name, cfg in variants.items():
        random.seed(seed)
        wins = 0; finals = []; loom = 0
        for _ in range(N):
            r = play_run(cfg)
            if r['status'] == 'win':
                wins += 1; finals.append(r['final_hp'])
                nxt = r['fights'][-1].get('next_unmit', 0)
                if r['final_hp'] < nxt: loom += 1
        wr = wins / N * 100
        brink = sum(1 for h in finals if h <= 5) / len(finals) * 100 if finals else 0
        loomp = loom / len(finals) * 100 if finals else 0
        avg = mean(finals) if finals else 0
        print(f"{name:18s} {wr:6.1f} {avg:6.1f} {brink:7.1f} {loomp:14.1f}")
    print("1more-lethal% = of WINS, the boss's next attack (unmitigated) >= your finishing HP")
    print("GOAL: raise win% while HOLDING/RAISING 1more-lethal%. (HP_up is the bad lever.)")


def spot_check():
    print("=== spot check (hand-verifiable resolution) ===")
    print(" A", resolve([5, 4, 3, 1], [2, 5, 1, 0], 20, 20),
          "GREEN cuts mult 5->2; armor1 cuts base 5->4 => deal 16, take 4")
    print(" B", resolve([6, 5, 3, 2], [2, 2, 4, 1], 20, 20),
          "BLUE strips anti 4->1; evasion cuts mult 5->4 => deal 24, KILL")
    print(" C", resolve([6, 6, 1, 0], [6, 6, 0, 0], 10, 20),
          "no anti => deal 36, KILL")


if __name__ == "__main__":
    spot_check()
    report_summary()
    report_sweep()
