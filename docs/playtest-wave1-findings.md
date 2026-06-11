# Playtest Wave 1 — Findings (2026-06-11)

Protocol: 4 subjects, walking in a park, one-handed play, designer as live tutor (rules
explained verbally — so the onboarding cliff was NOT tested; the designer was the tutorial).
Subjects: **S1** brother (TQFT PhD — far-tail ceiling probe), **S2** friend (casual-savvy),
**S3** friend (Slay the Spire veteran), **S4** girlfriend (out-of-audience control, chosen
deliberately).

## Validated — do not churn these

- **The model is clean.** It compressed three independent ways: formal model (S1: "two damage
  dimensions, anti collapses onto one"), discovered heuristic (S2), genre analogy (S3: a
  3-card hand — attack, setup, debuff-or-block). Three on-ramps, one game.
- **Player-discovered heuristics are mathematically correct.** S2's "counter their low stat"
  (optimal: reducing the smaller factor removes reduction × larger factor) and S1's "kill this
  turn = take nothing". Beginner strategies that never need unlearning = free tutorial curriculum.
- **The emotional core fires.** All three engaged subjects: 제발 at rerolls (especially near a
  visible kill threshold), 망겜 at bad dealt hands. Chosen-RNG thrill vs unchosen-RNG resentment —
  confirms GDD §7.4 doctrine empirically.
- **Engagement survives mastery.** S1 solved the loop and kept playing (asked to redo, swept).
- **Patterns read as drama.** S3 read the Slime list as a boss script with a kill window and an
  enrage finale, unprompted, and his expected kill round (p3) matches the sim (avg 2.5 rounds).
- **The control was unreached by both layers** (silent, random presses, instruction-seeking,
  polite "liked it"). The game is for who it was designed for. Her one real datum: "어케 이김"
  at the boss = random play reaches the boss.

## Broken — ranked

1. **The teaching gauntlet doesn't exist.** 3/4 struggled WITH a live tutor; random play clears
   three fights (sim deaths: 0 / 1.2 / 2.7 / 20%). Difficulty is flat-then-cliff. Fix is content:
   encounters forcing one foothold each (§11.1.2: Brute→GREEN, Swarm→RED, Bulwark→BLUE), with
   an intensity ramp instead of a wall.
2. **No staging/confirm/undo.** GDD §9.1 specifies it; build commits on gesture. Caused S2's
   rotate-fear (and confounded that data), S3 demanded undo hard. DECISION: staged board, same
   screen, no mode; commit = tap the dropped die again; swap's reroll fires only on commit
   (prevents reroll-scumming); "will reroll" badge while staged. Principle: minimize
   *irreversible* steps, not steps.
3. **Decision UI answers the wrong question.** It shows "what does this arrangement do"; the
   per-turn question is "which of my 8 moves do I want". S1 did head math (computation leak,
   §7.4 violation), S2 wanted rotate-left/right side by side (only 2 — both showable, as state
   ghosts not just numbers). Also: preview authority is not legible — it IS exact (deterministic),
   players assume it's an estimate. Say so on screen.
4. **Swap reads as draw, not gamble.** EV-positive since the player risks their worst die
   (S1: "rotating wastes a reroll"); felt as card draw (S3). BUT resolution drama is real and
   potent (제발). Lever order: (a) threshold legibility first — show "kill on 4+" at the reroll,
   nearly free, may deliver the push-your-luck feel without rule changes; (b) only then decide
   the identity fork: real stakes (both dice reroll / random target) vs embrace-the-economy
   (reframe GDD §3.2). Bad-hand 망겜 fix: frame swap as the *remedy* for a bad deal (floor);
   gear/counterplay depth is the cure at the ceiling (S1's complaint = §5.1 wearing variance
   as a symptom).
5. **Kill-skips-counter degenerates expert play.** Once confirmed, S1 collapsed to racing the
   RED×GREEN product. Cure via content before rules: pattern dramaturgy (kill windows / enrage
   finales make racing an *authored* answer to a *visible* deadline), threat floors, monster HP
   tuned as pattern-exposure (fights last 1.1–2.5 rounds; 4–5 entry patterns go unseen).
   Note: balance_sim's greedy AI is itself a racer — it cannot detect racing fixes.

## UI findings (combat screenshot review)

- **Column pairing — the keystone rule — has no visual encoding.** Dice row and action icons are
  separate rows across a gap; the pairing lives in working memory and falls out (S2's repeated
  "아 알것 같다" = per-turn re-derivation). Fix: one visible container per column (die + action).
- **Color collision.** Dice glow magenta/lime/cyan while action icons use pure RGB for a
  different meaning — §9.2 violated. Anti mode (defense = color of die in ANTI) is unreadable.
  ANTI column should take on its die's color and name the mode ("Evade −1 their Mult").
- **Math unrendered.** No A×B=C anywhere; "Deal X Take Y" floats unanchored. Anchor Deal at the
  monster HP bar, Take at the player's. Show what blocked subtracted.
- **Symmetric combat, asymmetric display.** Mirror the player's column layout on the monster
  side; the symmetry teaches the system silently.
- Minor: state label clips off-screen; dead vertical band mid-screen is where relational info
  should live.

## Strategic decisions

- **Refine, don't restart.** No finding implicates the core rules. Tripwire for revisiting:
  if, after the teaching gauntlet + first gear pieces, engaged players still collapse to the two
  heuristics and stop deliberating, widen the base loop (4th die/slot) — still not a restart.
- **Wave 2 only after wave-1 fixes are built.** Middle-profile subjects (snackable-deep target),
  NO verbal tutoring (tests the tutorial), telemetry over video (per-turn pause time, swap/rotate
  ratio, stage-to-commit gap, death locations), keep some sessions ambulatory (pillar-1 condition).
  Fresh subjects are spent forever once tutored — don't waste them on a known-defective build.
- **Defer decoration, never rule-rendering.** Legibility is part of the core for a game whose
  thesis is transparency. (Wave-1's comprehension data is partially confounded by the unrendered UI.)
- **Structural fact worth keeping (S1):** rotate generates only even permutations; swap is odd.
  Within one turn, some pairings are reachable ONLY via swap — the game already structurally
  forces the gamble sometimes. Patterns can be authored to demand odd-permutation answers.
