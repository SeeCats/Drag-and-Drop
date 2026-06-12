# Teaching Gauntlet — Draft 1 (turtle↔race spine)

> **Author:** Design Claude · **Status:** draft for review — *no numbers final.* Every candidate
> pattern/HP here is a proposal to be sim-validated before it ships (GDD §7.8: never ship a number
> on intuition). Owns GDD §12.5 #19 (color-conflict early patterns) + #20 (intensity-pacing map).
> Scope: the **un-geared campaign on-ramp** only — the build that wave-2 tests without a live tutor.

## 1. What this teaches: the turtle↔race dial

The core per-turn decision, named for the player: **turtle** (read the enemy's shape, set the right
defense color, survive and chip) vs **race** (skip defense, stack BASE×MULT, kill *this* turn before
the counter lands). This is the player-facing surface of the §6.2 decision modes and the §3.5 knot.

It is *core identity, not a degeneracy* (decided 2026-06-12). The thrill — "maybe **this** is the
turn to kill it" — is the chosen-RNG 제발 wave-1 validated. The failure mode is narrow and specific:
not that racing *exists*, but that racing **dominates** — if stacking BASE×MULT beats the color game
against *most* monsters, the read goes dead and the dial collapses to one end (wave-1 #5: S1 solved
"kills skip the counter" and stopped turtling entirely). So the design rule is **§6.2 guardrail 1 —
keep racing situational** — *not* "cure kill-skip."

**Corollary that drives this whole draft:** a monster teaches the dial only by making **one end
correct and punishing the other.** You learn "race" from a monster that *kills you if you turtle*;
you learn "turtle" from one that *outlasts your race and chips you dead.* Curriculum by contrast.

> Honest caveat baked in: no monster is literally "unraceable" — a great roll (high BASE *and* high
> MULT, plus a BLUE strip) can race almost anything. A turtle-teacher teaches *"when the roll won't
> hand you lethal, defend correctly,"* not "you may never race." The right answer is roll-dependent,
> which is the game. The teaching target is the **average** roll, not the lucky tail.

## 2. The spine maps onto the existing roster (mostly already built)

Current gauntlet order (`Globals/encounter.gd`): **alligator → ghost → alien → slime.** It already
sequences neutral → defense → race → exam. The work is *tightening and naming*, not authoring fresh.

| # | Monster | HP (current) | Dial role | One-line teaching goal |
|---|---|---|---|---|
| 1 | **Alligator** | 24 | *neutral / familiarize* | low, near-identical rounds — learn the verbs at near-zero stakes |
| 2 | **Ghost** | ⚠️ unset (hp.gd default) | **turtle-teacher** | racing usually whiffs → must read armor-vs-evasion (flurry↔heavy) |
| 3 | **Alien** | 10 | **race-or-die** | anti 0 + a lethal spike → turtling does nothing, you *must* close |
| 4 | **Slime** | 25 | **flipper / exam** | correct end flips round-to-round → re-read every turn |

(Slime Boss stays a placeholder `[600,600,600]` and is *not* in the gauntlet — boss design is a
separate future pass, out of scope here.)

## 3. Per-monster: current pattern, the contrast, proposed tweaks

Decode key: `[BASE, MULT, ANTI, mode]`, mode = **armor** (cuts your BASE) / **evasion** (cuts your
MULT). "Deals" = BASE×MULT before your defense. Monster rounds cycle in list order; round 1 = first.

### 1 — Alligator (familiarize) · HP 24
- **p1** FLURRY `[1,3,2,armor]` → deals 3 · **p2** HEAVY `[3,1,2,armor]` → deals 3
- **Reads as:** two near-identical trickle rounds, mild armor. No real threat; the point is to let a
  new player operate rotate/swap and watch the preview update without dying for a misread.
- **Concern (sim it):** HP 24 against trickle output may make this *drag* — a familiarize fight
  shouldn't outstay the lesson. Candidate: **drop HP to ~12–15** so it ends in a few turns. Also its
  `mult=1` round sits in the §7.8 dead zone (worst-feel) — fine for a tutorial punching bag, flag only.

### 2 — Ghost (turtle-teacher) · HP ⚠️ unset → **must be set deliberately**
- **p1** FLURRY `[2,5,1,armor]` → deals 10 · **p3** GUARDED `[2,2,4,evasion]` → deals 4 ·
  **p2** HEAVY `[5,2,1,armor]` → deals 10 · **p4** GUARDED `[2,2,4,armor]` → deals 4
- **The contrast it should teach:** flurry (many small) wants RED-armor; heavy (few big) wants
  GREEN-evasion (at low anti) — the crossover read of §6.2. Sustained ~10/turn means *skipping*
  defense to race chips you out before a 4-round fight ends → turtling is rewarded, racing punished.
- **The load-bearing number:** **Ghost HP is currently unset** (falls to the `hp.gd` default — a
  silent, unaudited value for the monster whose whole job is "you can't reliably race me"). This is
  the single most important tuning knob in the gauntlet. Candidate: **set HP so the *greedy racer*
  clears it well under 50%** (see §4 metric) — likely ~22–28, sim to find it. Until it's set on
  purpose, Ghost isn't a turtle-teacher, it's an accident.
- **Optional:** the two GUARDED rounds (p3/p4) preview the strip/Guarded idea early; keep but
  consider whether two guard rounds dilute the flurry↔heavy core lesson for a *second* fight.

### 3 — Alien (race-or-die) · HP 10
- **p1** SPIKE `[4,4,0,—]` → deals 16 · **p2** SPIKE `[6,6,0,—]` → deals 36
- **The contrast it should teach:** anti 0 means your BLUE-strip is pointless *and* your armor/evasion
  only blunt one factor of a huge product — defense can't save you. HP 10 means you *can* close fast.
  So the lesson is "stop defending, commit to the kill." The 36 on p2 is the **whiff-punisher**: race
  and miss → you eat a near-lethal swing. This is exactly the §6.2 "real downside" guardrail.
- **Concern (sim it):** is the punish *honest and survivable-with-a-read*, or a coin-flip mug? Player
  HP at this gauntlet stage decides whether eating 16 (p1) then facing 36 (p2) is "scary but a good
  roll closes it" vs "RNG decides." Sim the **race-line death rate** and tune the spike, not the mean.

### 4 — Slime (flipper / exam) · HP 25
- **p1** HEAVY `[5,3,3,armor]` →15 · **b** breather `[1,1,4,armor]` →1 · **p2** FLURRY `[3,5,3,evasion]`
  →15 · **p3** GUARDED `[2,2,4,evasion]` →4 · **p4** SPIKE `[6,6,0,armor]` →36
- **The contrast it should teach:** every round wants a *different* answer — heavy, then a free
  breather (§7.8 / §7.4 rest beat), then flurry, then guard, then an enrage spike. The correct dial
  position **moves**, so the player must re-read instead of autopiloting. Wave-1 S3 already read this
  as "boss script with a kill window + enrage" unprompted — the shape works.
- **Concern:** this is the right *final exam* but a heavy lift for fight #4 of an un-geared on-ramp.
  Watch in playtest whether the spike (p4, 36) reads as an *authored deadline* (race it down before
  it lands, via the §6.1 lookahead) or as an unfair cliff. Pacing, not numbers, is the risk here.

## 4. Sim requests for Code Claude (§7.8, rule 5)

The greedy 1-ply AI in `balance_sim.py` **is a racer** (wave-1 #5) — which makes it the right probe
for *this* question: a healthy turtle-teacher should **defeat the racer often**; a race-teacher
should **let the racer win.** So per-monster **racer-win%** is the teaching-health metric.

Requested run, each monster solo (not the full gauntlet), N=3000:

1. **Racer-win% per monster** at its candidate HP. Targets (directional): Alligator high (trivial),
   **Ghost low (<~50% — proves you can't just race it)**, Alien high (race is correct), Slime mid.
2. **Ghost HP sweep** (e.g. 18/22/26/30): find the HP where racer-win% crosses ~45–50% — that's the
   "must turtle" threshold. This is the headline number.
3. **Alien spike lethality:** race-line death-rate vs player HP at this stage — confirm the p2 `36`
   punishes a *whiff* without mugging a *good read*.
4. **Alligator HP 12 vs 15 vs 24:** turns-to-kill, to stop the familiarize fight dragging.

Commit raw per rule 5 to `docs/sim-results/`. I'll price the results into final patterns/HP.

## 5. Out of scope / open

- **Boss** (Slime Boss placeholder) — separate pass; needs a real rotation (§6.3), not in the on-ramp.
- **Gear** — none of this assumes equipment; the gauntlet's job is to prove the *un-geared* dial is a
  live decision (§12.1 #1). If it isn't even with this curriculum, that's the §5.1 widen-the-loop
  signal, not a content bug.
- **Lookahead presentation** — the Slime spike lesson leans on the §6.1 one-step lookahead reading as
  *"incoming: you'll want to race/defend,"* not raw numbers (see the ui-spec flag, 2026-06-12). The
  exam only fully works once that hint is recognition-first.
- **Wrong-end punishment must stay legible** (§6.2 guardrail 3): "its guard is 0, just race it" should
  be a read the player *makes from visible info*, never a hidden trap.
