# Combat UI Specification

Owner: **UI Claude** (per CLAUDE.md coordination block). Code Claude builds against this; Fable spot-checks.
Canonical-location rule applies: concepts defined here are cited elsewhere, never restated. GDD §9 will be reduced to a pointer at this file once the spec stabilizes.

Status: **READY FOR BUILD** — layout, object model, input mechanic, motion, and color all decided; input validated on-device (`docs/prototype/combat-ui-prototype.html`). Code Claude builds against §8 acceptance criteria; verification per §8 screenshot protocol. Remaining open items are styling-level, non-blocking.

---

## 1. Canvas & device constraints

- Logical canvas **540 × 1140** (`project.godot`), `canvas_items` stretch, `expand` aspect. Width is effectively fixed at 540; height varies ~960 (16:9) to ~1230 (21:9+).
- OS safe insets: reserve ~40px top, ~25px bottom. Nothing interactive in the insets.
- Exactly **one elastic band** (S1, see §3) absorbs all height variance. Every other band is fixed-height, anchored top or bottom.
- One-handed portrait, right thumb baseline; left-handed mirror is a settings toggle (GDD §9.3) and must cost zero layout work — the layout is horizontally symmetric.
- Thumb line at ~45% screen height from the bottom: everything below it may be touchable, everything above it is read-only.
- Minimum touch target: **80px** in the smaller dimension. **Visual size ≠ hit size**: small icons (e.g. the 24px menu glyph) get an invisible padded hit area up to the 80px minimum; the rule constrains hit areas, not artwork.
- Occlusion rule: during any drag, live feedback must render **above** the touch point — the hand covers everything below and right of the finger.
- Depth rule: combat UI is **max one level deep** — canonical statement in GDD §9.1 ("One level deep, everywhere").

## 2. Information hierarchy

The UI answers, in priority order: "which of my moves do I want" → "what is the state" → "what is staged" → "what comes next" → "what just happened".

- **T1 — the decision** (always visible while planning): projected outcome of the current arrangement as rendered math (`base × hits = total` after reductions), kill/death thresholds, outcomes of the alternative moves. Previews are exact and labeled as exact.
- **T2 — the state**: own dice (value + element) inside their slot containers; monster's committed roll mirrored on the same columns; ANTI mode named in words ("Evade −N their hits"); both HP bars with projected post-combat values.
- **T3 — commitment state**: staged vs committed, "will reroll" badge on staged swaps, undo affordance, current phase.
- **T4 — lookahead**: monster's next pattern (numbers + threatened defense type); gauntlet progress.
- **T5 — resolution feedback**: per-hit damage numbers, MISS/Blocked pops, combat log (behind a toggle).

## 3. Zone map (vertical bands)

Heights given at 540×1140; S1 is the elastic band.

| Band | Height | Role | Touch? |
|---|---|---|---|
| safe inset | ~40 | — | no |
| **S0 status** | ~50 | menu button in the LEFT corner (rarest touch gets the hardest reach; mirrored by left-hand toggle), then phase + gauntlet progress; next-pattern at right | menu only |
| **S1 enemy** | ~340 (elastic) | sprite, HP + damage projection, its roll on the column spine, next-pattern lookahead | no |
| **S2 relation ledger** | ~120 | deal/take math (T1), exact-tag, kill threshold; resolution numbers fly here | no |
| **S3+S4 tray cluster** | ~330 | one tightly-grouped unit, top to bottom: player HP + projection → dice row in slot containers → knob directly beneath, Cancel/Confirm flanking. Future: energy docks here | YES |
| safe inset | ~25 | — | no |

Docking rules for future features: per-dimension things (status icons on a stat, ghosts) live in their column; relational things (thresholds, projections) live in S2; per-actor things (HP, statuses, relics) dock to that actor's band. A feature that fits none of the three is a design problem, not a layout problem.

## 4. Column spine

- One shared **N-column grid** runs through S1 (monster roll mirror) and S3 (player tray). Columns align vertically: damage above damage, defense above defense. The alignment **is** the encoding of the slot-pairing rule — no extra explanation UI.
- Slot order, fixed forever: **BASE left, MULT middle, ANTI right.** Position is meaning; it never changes at runtime.
- N is data-driven, currently 3. Nothing may be hand-positioned; the layout must survive N=4 (the GDD widen-the-loop tripwire). At N=4, columns are ~120px wide — still above the 80px touch minimum.
- Each S3 column container holds: slot label, the dice (value + element color), and the column's live contribution in words/numbers (e.g. `5−2 → 3/hit`; ANTI: mode name + effect). All inside the touch target.
- The ANTI container tints to its current dice's element. This tint must update live while dice are moving.

## 5. Object & interaction model

**DECIDED:**

- **Zones are furniture; dice are the only movable, grabbable objects.** Zones/slots never accept touch input and never move. (Kills the legacy 6-zone hack; `swap.gd`/`rotate.gd` dual zone-rows collapse into one tray input controller.)
- **Rotate moves the dice**, one column step left or right, slots stationary. Rotating zone meanings under static dice is rejected — it destroys position-as-meaning and breaks the S1/S3 mirror alignment. The variant "zones rotate but snap back to canonical order at round start" is also rejected: combat still resolves on a misaligned board, and the reset adds round-start dice motion that carries no information.
- **Staging before commit** (per playtest decision): any move is first staged (shown, revertible), then committed explicitly. Swap's reroll fires **on commit only** (anti-scumming). Staged swap shows a "will reroll" badge. Principle: minimize *irreversible* steps, not steps.
- Direction-split gestures (horizontal swipe = rotate) are **rejected**: undiscoverable, misfires while walking.

**DECIDED — row + knob.** Condition met 2026-06-11: knob flick passed a real-thumb test (one-handed use with attention divided — user operated it while eating with chopsticks; no misfires reported).

- Dice sit in the **horizontal row of slot containers** (column spine per §4, fully restored). Below the row, centered: a **rotate knob**. Gesture = **horizontal flick on the knob**: release point lefter than touch point → rotate left, righter → rotate right, under threshold (~18px) → nothing. The rim visually turns with the finger and snaps ±120° on release. Continuous rotary tracking REJECTED — with one move per turn and only 2 distinct rotations, angle tracking adds misfire surface with zero expressive gain. Repeated flicks step the staged arrangement (flick back = un-stage). **Dragging a dice onto another dice = swap.** Knob is the only rotate handle, dice are the only swap handles — no shared touch targets.
- **Cancel and Confirm flank the knob** — Cancel left, Confirm right (right-thumb-nearest; mirrored by the left-hand toggle). This RESOLVES the commit-gesture question: visible buttons, not tap-the-dice-again.
- **Monster presentation keeps the scouter reticle**: HP ring around the sprite (surviving arc = kill threshold made visible), reticle ticks; its three stat chips sit in a row beneath the ring, column-aligned with the player's slots. The reticle is presentation; pairing is taught by column alignment, not angles.
- **Known design debt — the wrap animation.** On rotate, the end dice must travel to the row's other end. It must visibly arc over the row (not teleport) or rotate reads as chaos. Prototype question #2. The wrap path is animation only — never drawn as standing UI (it costs a band of dead space; learned from mockup).
- **Tight-grouping rule:** the tray is ONE cluster — HP, dice row, knob touch each other with minimal gaps. Controls and the objects they act on must read as a single unit; spacing between unrelated bands is where slack goes, never inside a control cluster. (S3/S4 merged accordingly, see §3.)
- **Deal-on-the-knob (proposed, test in prototype):** the projected deal total rendered on/at the knob face — the only interior spot dice never cross; "tune the dial, read the dial." If adopted, take anchors at player HP and S2 shrinks to a thin threshold strip (kill/short-by-N/exact + resolution-number flight path), reclaiming ~60–80px. Cramming rule that governs this: a datum may be squeezed into a gap only if its position encodes a relationship (e.g. product between its factors); never park info on a motion path; one home per datum.
- **Validation status: ALL THREE PASSED** (2026-06-11, one-handed divided-attention sessions). Knob flick: no misfires. Wrap arc: reads as rotation. Deal-on-knob: confirmed on the element-fixed prototype. Fallback (⟲/⟳ buttons) retired. Deal-on-knob + thin-strip S2 hereby ADOPTED (no longer proposed).
- Archived candidates (for the record): full circular wheel (matched-angles, two-vertices-up — superseded: row+knob keeps its handle separation while restoring the column spine and ~60px of height); home-screen slide-to-fill (cannot express end-swap); handle bar; direction-split swipe (rejected: undiscoverable). Tap-tap remains viable as a redundant channel.

## 6. Color

- Code ground truth is the `Swatch` autoload; this section mirrors it and must be updated in the same session as any Swatch change.
- **DECIDED — unification on the neon family** (history: original palette was strict QCD-style RGB primaries; rejected on legibility/aesthetics — pure primaries on dark read as programmer art):
  1. Neon is canonical everywhere an element appears: RED→magenta, GREEN→electric lime (`B0FF00`), BLUE→cyan — dice wireframes, ANTI slot tint, VFX, all of it. `ELEMENT_COLOR` (pure RGB) retires from UI use.
  2. WHITE element: reserved, dormant (far-future "all-elements" dice idea — not designed now). `NEON_COLOR` must still gain a 4th entry (ghost white placeholder) so element-indexed lookups can never go out of bounds. **Work order for Code Claude** along with the `Swatch` cleanup.
  3. Element colors appear ONLY on things that carry an element. The monster's anti is a stat attack, not an element: its chip gets neutral threat styling + the word (block/miss). This exclusivity is what makes color=element learnable.
  4. The code enum stays RED/GREEN/BLUE (no rename churn); player-facing text never names a color — icons and mode words carry meaning (required by §9.3 accessibility anyway), so the name/display dissonance never reaches players.
- Color is never the only signal: each ANTI mode also carries an icon and a written name (GDD §9.3).

## 7. Motion

Governing rule: **idle states are still; motion is spent only on uncertainty or change.** Continuous ambient motion on decision-surface objects is attention theft (playtest: the always-spinning dice cubes read as distracting).

Dice cube spin states (wireframe cube rendering kept):

- Round start: tumble → slow → land on the rolled value (roll reveal).
- Idle during planning: completely still.
- Staged swap: the dice that will reroll on commit tumbles slowly — the motion IS the "will reroll" marker (replaces a text badge). All other dice stay frozen.
- Mid-drag: light spin allowed (attention is already on it).

Future juice passes (shake, pops, halos) are bound by the same rule. A reduced-motion setting docks with the existing bloom/flash accessibility options (GDD §9.3).

## 8. Verification protocol

Every implementation pass is checked against this spec via screenshots:

- Fixed 6-state checklist, always the same monster: planning start / mid-drag with preview / staged-uncommitted / player attack resolving / monster attack resolving / win-lose.
- Manual: snip + paste into chat. Planned: F12 debug-screenshot autoload saving PNGs into `screenshots/` (work order for Code Claude; gitignored).
Acceptance criteria — each maps to a screenshot state; Code Claude's build passes when all hold:

**Planning, idle:**
1. Zero dice motion. Nothing on screen animates while the player is thinking.
2. Monster stat chips are column-aligned with the player slots (column centers within ~10px).
3. Monster ring's surviving arc, the strip's kill/short-by line, and the knob's deal number all agree with `compute_outcome` for the current arrangement.
4. ANTI slot is tinted to its dice's element and names its mode in words ("evade −N their hits").
5. Menu glyph sits top-left; its hit area ≥80px despite the small glyph.

**Mid-drag:**
6. Dragged dice follows the finger with light spin; the hovered target column highlights.
7. All preview updates render above the touch point (occlusion rule) and update live.

**Staged:**
8. Staged swap: the moved dice tumbles slowly (the will-reroll marker); all other dice frozen; knob shows the `X~Y` range; strip shows "kill on N+" when a kill face exists.
9. Staged rotate: rim visibly displaced; flicking back un-stages.
10. Cancel restores the pre-stage arrangement in one tap; starting any new gesture replaces the staged move.

**Resolution:**
11. The wrapping dice arcs visibly over the row — never teleports.
12. Damage/miss/block numbers fly through the S2 strip band.
13. A pre-commit "kills — takes nothing" reading is never contradicted by the resolution outcome.

**Structural (any state):**
14. No hardcoded column count or positions — container-driven layout that survives N=4.
15. Layout intact from 16:9 to 21:9; only the monster panel changes height.
16. Cancel/Confirm hit areas ≥80px (visual circles may be smaller).
17. Every overlay/screen reachable during combat returns to combat in one tap (GDD §9.1 depth law).

## 9. Open decisions (live list)

1. ~~Prototype validation~~ RESOLVED — all three verdicts passed; see §5.
2. ~~Deal-on-knob + thin-strip S2~~ ADOPTED — see §5. "Take" anchors at the player HP line.
3. S1 internal split: sprite/ring size vs. stat chip row (fine-tune in Godot, not blocking).
4. ~~Element color unification~~ DECIDED — see §6. (Swatch cleanup + 4th neon entry = Code Claude work order.)
5. Cancel/Confirm visual size within the cluster (hit areas solved by criterion 16; pure styling).
6. Research to-do before wave 2: play Slice & Dice (closest relative — portrait dice combat; study its intent display, unlimited pre-commit undo, information density).

## Changelog

- 2026-06-11 — §6 DECIDED: neon family canonical (RGB primaries retired from UI; WHITE reserved-dormant, 4th NEON entry required defensively; element colors only on element-bearing things; player text never names colors). Status → READY FOR BUILD.
- 2026-06-11 — all prototype verdicts passed (knob, wrap, deal-on-knob); deal-on-knob + thin-strip S2 adopted; §8 acceptance criteria written (17 items); status → VALIDATED; sole blocker = §6 color unification.
- 2026-06-11 — created: canvas, hierarchy, zone map, column spine, object model (fixed zones / moving dice), staging, verification protocol. Input mechanic left open.
- 2026-06-11 (later) — input mechanic working direction: player wheel (knob = rotate handle, dice = swap handles) + monster scouter reticle as its wheel; matched-angles rule replaces column alignment; two-vertices-up orientation. Conditional on knob passing the phone-prototype thumb test. Row candidates archived.
- 2026-06-11 — added §7 Motion: idle = still, motion only for uncertainty/change; dice spin states (roll reveal / frozen idle / staged-reroll tumble replaces the will-reroll text badge / light drag spin).
- 2026-06-11 — menu address (S0 left corner), visual-vs-hit-size rule, depth rule citation (canonical in GDD §9.1), Slice & Dice research to-do.
- 2026-06-11 — S3/S4 merged into one tray cluster (HP → dice row → knob, Cancel/Confirm flanking); tight-grouping rule added; wrap path declared animation-only; open list refreshed (touch-size violation on Cancel/Confirm flagged).
- 2026-06-11 (later still) — superseded by **row + knob**: dice row restores the column spine; knob below the row rotates it, Cancel/Confirm flank the knob (commit question resolved); scouter reticle kept as monster presentation; wrap animation flagged as design debt; deal-on-the-knob + thin-strip S2 proposed for prototype. Full wheel archived.
