"""Checks whether monster anti_type (armor=0 vs evade=1) ever binds in real play.
Recomputes deals from rolls (log 'deal' is HP-capped), compares actual vs
type-flipped outcomes on (a) the hand the player actually committed and
(b) the best deterministic option (pass/rotL/rotR) available from the start hand."""
import json, sys

ELEM = {"RED": 0, "GREEN": 1, "BLUE": 2}
P_MIN = [1, 1, 0]   # player floors (base, mult, anti)
M_MIN = [1, 1, 0]   # monster floors

def outcome(hand, mroll):
    """hand = [[v,color]x3] in column order base,mult,anti. Returns (deal, take)."""
    p = [hand[0][0], hand[1][0], hand[2][0]]
    p_at = ELEM[hand[2][1]]            # player anti_type = ANTI die color index
    m = list(mroll[:3]); m_at = mroll[3]
    m[p_at] = max(m[p_at] - p[2], M_MIN[p_at])       # player anti cuts monster
    p[m_at] = max(p[m_at] - m[2], P_MIN[m_at])       # monster (updated) anti cuts player
    return p[0] * p[1], m[0] * m[1]

def rotations(hand):
    a, b, c = hand
    return [hand, [b, c, a], [c, a, b]]  # pass, rotate one step each way

runs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]

total_rounds = 0
anti_rounds = 0                # monster anti > 0 (type could matter)
realized_diff = []             # committed hand: deal changes if type flipped
best_diff = []                 # best-of-3-rotations deal changes if type flipped
verify_fail = 0

for run in runs:
    for f in run["fights"]:
        for r in f["rounds"]:
            total_rounds += 1
            mroll = r["monster_roll"]
            # verify model vs log (only when not kill-capped)
            d, t = outcome(r["after"], mroll)
            hp_m = r["hp_before"]["monster"]
            if d < hp_m and d != r["deal"]:
                verify_fail += 1
                print("MISMATCH", r["deal"], d, r)
            if mroll[2] <= 0:
                continue
            anti_rounds += 1
            flipped = mroll[:3] + [1 - mroll[3]]
            # (a) realized hand
            d0, _ = outcome(r["after"], mroll)
            d1, _ = outcome(r["after"], flipped)
            if d0 != d1:
                realized_diff.append((d0, d1, r["monster_roll"], r["after"]))
            # (b) best deterministic option from start
            b0 = max(outcome(h, mroll)[0] for h in rotations(r["start"]))
            b1 = max(outcome(h, flipped)[0] for h in rotations(r["start"]))
            if b0 != b1:
                best_diff.append((b0, b1, r["monster_roll"], r["start"]))

print(f"runs={len(runs)} rounds={total_rounds} model-mismatches={verify_fail}")
print(f"rounds with monster anti>0: {anti_rounds}")
print(f"(a) committed hand, deal changes if type flipped: {len(realized_diff)}")
for d0, d1, mr, h in realized_diff:
    print(f"    actual={d0} flipped={d1} (delta {d1-d0:+d}) mroll={mr} hand={h}")
print(f"(b) best pass/rotate option changes if type flipped: {len(best_diff)}")
for b0, b1, mr, h in best_diff:
    print(f"    actual-best={b0} flipped-best={b1} (delta {b1-b0:+d}) mroll={mr} start={h}")
