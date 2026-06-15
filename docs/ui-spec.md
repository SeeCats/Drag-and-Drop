# Combat UI Specification

Owner/maintainer: **Code Claude, user-directed** (Fable/dedicated-UI model suspended 2026-06-12; UI work runs in the Code session for now). Code builds against this *and* keeps it current.
Canonical-location rule applies: concepts defined here are cited elsewhere, never restated. GDD §9 will be reduced to a pointer at this file once the spec stabilizes.

Status: **READY FOR BUILD** — layout, object model, input mechanic, motion, and color all decided; input validated on-device (`docs/prototype/combat-ui-prototypever3.html` — user-renamed during phone transfers). Code Claude builds against §8 acceptance criteria; verification per §8 screenshot protocol. Remaining open items are styling-level, non-blocking.

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

- **T1 — the decision** (always visible while planning): projected outcome of the current arrangement — deal on the knob face, take as the dim segment of the player HP ring, kill/short-by verdict docked under the monster's HP readout. Previews are exact and labeled as exact. Alternative-move outcomes are one *reversible* gesture away: staging IS the preview (flick to see a rotate, drag to see a swap's range, cancel freely) — this consciously supersedes the wave-1 "show rotate-left/right side by side" ghost idea.
- **T2 — the state**: own dice (value + element) inside their slot containers; monster's committed roll mirrored on the same columns; ANTI mode named in words ("Evade −N their hits"); both HP bars with projected post-combat values.
- **T3 — commitment state**: staged vs committed, staged-reroll marker = the slow tumble (§7, no text badge), undo affordance, current phase.
- **T4 — lookahead**: the monster's next pattern as a **recognition-first demand hint** — what it demands of the player (mode icon + word, e.g. "incoming: evade"), NOT raw numbers; exactly one step ahead. Canonical rationale: GDD §6.1 (plan by recognition, conveyor planning); the teaching-gauntlet exam (slime spike) depends on this reading. Numbers may exist behind a tap at most. Also: gauntlet progress.
- **T5 — resolution feedback**: per-hit damage numbers, MISS/Blocked pops, combat log (behind a toggle).

## 3. Zone map (vertical bands)

Heights given at 540×1140; S1 is the elastic band.

| Band | Height | Role | Touch? |
|---|---|---|---|
| safe inset | ~40 | — | no |
| **S0 status** | ~50 | menu button in the LEFT corner (rarest touch gets the hardest reach; mirrored by left-hand toggle), then phase + gauntlet progress; next-pattern demand hint at right (T4, recognition-first) | menu only |
| **S1 sky** | elastic | monster centered in its scouter reticle (HP ring = surviving arc); HP numbers + kill-verdict line + exact tag docked top-right as one block; green callout fan from the reticle down to its chips; full-screen starfield lives behind everything | no |
| **S2 monster roll** | chip row | the monster's committed roll chips, column-aligned, sitting snug ~8px above the tray slots (his numbers cap your columns) | no |
| **S3 tray** | ~330 | slot squares with VP cubes → captions below → knob wearing the **player HP ring** (bright = survives, dim = projected take, track = missing; exact text beneath), Cancel/Confirm flanking wide; teal callout fan from the HP ring up to the columns | YES |

The old S2 threshold strip and the player HP *bar* are **abolished** (staring-phase decisions): the verdict docks at the monster per the per-actor rule, the player's HP became the knob ring, and resolution numbers fly at the actors they hit. Governing rule that killed them both: **no full-width horizontal element may cross the column field** — the gaze flows down the columns and horizontal elements read as fences. (Region edges at the screen's extreme top/bottom are exempt; a console-plate variant was tested and rejected because its top edge re-created the fence.)
| safe inset | ~25 | — | no |

Docking rules for future features: per-dimension things (status icons on a stat, ghosts) live in their column; relational things (thresholds, projections) live in S2; per-actor things (HP, statuses, relics) dock to that actor's band. A feature that fits none of the three is a design problem, not a layout problem.

Size-token rule (user-caught, 06-12): **a size difference must encode a meaning difference.** Same-kind elements share one size token — the two text strips (S0, S2) share 50. Meaningful contrasts (elastic S1, the 330 tray) stay. Don't introduce a new height/width value without naming what the difference means.

## 4. Column spine

- One shared **N-column grid** runs through S1 (monster roll mirror) and S3 (player tray). Columns align vertically: damage above damage, defense above defense. The alignment **is** the encoding of the slot-pairing rule — no extra explanation UI.
- Slot order, fixed forever: **BASE left, MULT middle, ANTI right.** Position is meaning; it never changes at runtime.
- N is data-driven, currently 3. Nothing may be hand-positioned; the layout must survive N=4 (the GDD widen-the-loop tripwire). At N=4, columns are ~120px wide — still above the 80px touch minimum.
- Each S3 column holds: the slot square (touch target) with the dice cube centered in it, and the column's live contribution in words/numbers directly below the square (e.g. `5−2 → 3/hit`; ANTI: mode name + effect) — see §7.1 for the cube rendering.
- The ANTI container tints to its current dice's element. This tint must update live while dice are moving.

## 5. Object & interaction model

**DECIDED:**

- **Zones are furniture; dice are the only movable, grabbable objects.** Zones/slots never accept touch input and never move. (Kills the legacy 6-zone hack; `swap.gd`/`rotate.gd` dual zone-rows collapse into one tray input controller.)
- **Rotate moves the dice**, one column step left or right, slots stationary. Rotating zone meanings under static dice is rejected — it destroys position-as-meaning and breaks the S1/S3 mirror alignment. The variant "zones rotate but snap back to canonical order at round start" is also rejected: combat still resolves on a misaligned board, and the reset adds round-start dice motion that carries no information.
- **Staging before commit** (per playtest decision): any move is first staged (shown, revertible), then committed explicitly. Swap's reroll fires **on commit only** (anti-scumming). The will-reroll marker is the staged die's slow tumble (§7) — no text badge. Principle: minimize *irreversible* steps, not steps.
- Direction-split gestures (horizontal swipe = rotate) are **rejected**: undiscoverable, misfires while walking.

**DECIDED — row + knob.** Condition met 2026-06-11: knob flick passed a real-thumb test (one-handed use with attention divided — user operated it while eating with chopsticks; no misfires reported).

- Dice sit in the **horizontal row of slot containers** (column spine per §4, fully restored). Below the row, centered: a **rotate knob**. Gesture = **horizontal flick on the knob**: release point lefter than touch point → rotate left, righter → rotate right, under threshold (~18px) → nothing. The rim visually turns with the finger and snaps ±120° on release. Continuous rotary tracking REJECTED — with one move per turn and only 2 distinct rotations, angle tracking adds misfire surface with zero expressive gain. Repeated flicks step the staged arrangement (flick back = un-stage). **Dragging a dice onto another dice = swap.** Knob is the only rotate handle, dice are the only swap handles — no shared touch targets.
- **Cancel and Confirm flank the knob** — Cancel left, Confirm right (right-thumb-nearest; mirrored by the left-hand toggle), spread wide of the knob (fat-thumb crosstalk). This RESOLVES the commit-gesture question: visible buttons, not tap-the-dice-again.
- **The knob must look turnable** (user-caught when the HP ring made it read as a gauge): grip ticks around the face rim + a bright orientation **notch**. The notch sits turned ±120° while a rotate is staged (this is how criterion 9's "visibly displaced" is rendered) and the whole face follows the finger mid-flick. The HP ring wraps *outside* the face and is never touchable; the hit area is the face only.
- **Player HP = the ring around the knob** (the dial is your body — the thing you turn is the thing that bleeds). Bright arc = survives, dim = projected take, dark track = missing; exact numbers in text directly beneath. The horizontal HP bar is abolished (gaze-fence rule, §3).
- **Monster presentation keeps the scouter reticle**: HP ring around the sprite (surviving arc = kill threshold made visible), reticle ticks; its three stat chips sit in a row beneath the ring, column-aligned with the player's slots. The reticle is presentation; pairing is taught by column alignment, not angles.
- **Known design debt — the wrap animation.** On rotate, the end dice must travel to the row's other end. It must visibly arc over the row (not teleport) or rotate reads as chaos. Prototype question #2. The wrap path is animation only — never drawn as standing UI (it costs a band of dead space; learned from mockup).
- **Tight-grouping rule:** the tray is ONE cluster — HP, dice row, knob touch each other with minimal gaps. Controls and the objects they act on must read as a single unit; spacing between unrelated bands is where slack goes, never inside a control cluster. (S3/S4 merged accordingly, see §3.)
- **Deal-on-the-knob (proposed, test in prototype):** the projected deal total rendered on/at the knob face — the only interior spot dice never cross; "tune the dial, read the dial." If adopted, take anchors at player HP and S2 shrinks to a thin threshold strip (kill/short-by-N/exact + resolution-number flight path), reclaiming ~60–80px. Cramming rule that governs this: a datum may be squeezed into a gap only if its position encodes a relationship (e.g. product between its factors); never park info on a motion path; one home per datum.
- **Validation status: ALL THREE PASSED** (2026-06-11, one-handed divided-attention sessions; prototype: `docs/prototype/combat-ui-prototypever3.html`). Knob flick: no misfires. Wrap arc: reads as rotation. Deal-on-knob: confirmed on the element-fixed prototype. Fallback (⟲/⟳ buttons) retired. Deal-on-knob + thin-strip S2 hereby ADOPTED (no longer proposed).
- Archived candidates (for the record): full circular wheel (matched-angles, two-vertices-up — superseded: row+knob keeps its handle separation while restoring the column spine and ~60px of height); home-screen slide-to-fill (cannot express end-swap); handle bar; direction-split swipe (rejected: undiscoverable). Tap-tap remains viable as a redundant channel.

## 6. Color

- Code ground truth is the `Swatch` autoload; this section mirrors it and must be updated in the same session as any Swatch change.
- **DECIDED — unification on the neon family** (history: original palette was strict QCD-style RGB primaries; rejected on legibility/aesthetics — pure primaries on dark read as programmer art):
  1. Neon is canonical everywhere an element appears: RED→magenta, GREEN→electric lime (`B0FF00`), BLUE→cyan — dice wireframes, ANTI slot tint, VFX, all of it. `ELEMENT_COLOR` (pure RGB) retires from UI use.
  2. WHITE element: reserved, dormant (far-future "all-elements" dice idea — not designed now). `NEON_COLOR` (and `HALF`) now carry a 4th entry — ghost-white placeholder — so element-indexed lookups never go out of bounds; `from_name` gained `neon_white`. **DONE (Code Claude, 2026-06-12, `Swatch`).**
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

**Starfield (adopted):** a full-screen starfield behind everything — stars live in the gaps, never inside an information container (slots, chips, buttons are opaque). Its motion is the **tempo channel**: near-still during planning, hard streak during the resolve beat (the one place "swoosh" is allowed), settle on return to planning. Docks with reduced-motion.

### 7.2 Ownership grammar (callout fans)

Each actor visibly *holds* its row with thin callout lines in its own vital color — connection chosen over common-region after head-to-head mocks (the console-plate alternative re-created the horizontal-fence problem).

- Monster: scouter-green fan from the reticle's lower arc to each of its chips, small dot at each landing.
- Player: teal fan from the HP ring's upper arc to each column's foot.
- **Line budget: six.** These are the only standing lines allowed on screen; anything else wanting a connector must displace something.
- Color-family law (extends §6): **scouter green = facts about the monster; element neon = dice only; teal = player vitals; neutral gray-blue = player machinery.** No family ever borrows another's hue.
- Never draw arrows between a chip and a slot — the vertical relation is same-dimension pairing, not attack targeting; arrows would mis-teach.

### 7.1 Dice rendering — vanishing-point treatment (tone layer, toggleable)

All three wireframe cubes share one perspective **vanishing point at the monster's live position** (not a constant — the enemy band is elastic). Spawned from a user sketch 2026-06-12.

- **Classification: pure tone.** The pairing information is already carried by the column alignment (§4); the VP adds "aimed at the target" as flavor, so it must cost nothing in legibility. Implement behind a toggle; fallback = parallel extrusion (same depth, no asymmetry). Wave-2 fresh-eyes question: "do the dice look like they point at the monster?"
- **Geometry:** the cube is centered on its slot — the slot square is the cube's cross-section (front half toward the viewer, back half toward the VP). The slot square is fixed (touch target, ≥80px logical); **the cube shrinks to fit** including its extrusion — cubes never dictate layout. Slot squares are square, with visible gaps between columns.
- **Value label at the perceived center:** `slot_center + 0.4 × front_face_offset` along the depth axis (the bright front face pulls the perceived center forward), over a small dark backing disc so edges never cross the digit. The label stays upright always.
- **Tumble overrides aim:** a tumbling cube (roll reveal, staged reroll, drag spin) ignores the VP; it re-aims on settle. Extrusion re-aims smoothly while a cube slides columns (rotate/wrap).
- **Drag z-grammar:** picking a dice up pulls it out of the slot plane toward the viewer (front face grows); dropping sinks it back.
- **Convergence rays are never standing UI** (same law as the wrap path). At most: a sub-second commit flourish along the attack direction.
- **Optical-alignment check (user-flagged):** perspective can make true alignment *look* false — the outer cubes' inward-leaning mass may read as pinched columns even on a perfect grid. The screenshot pass judges *perceived* alignment, and the eye outranks the coordinates. Approved fixes operate on the cube only (lateral compensation inside the square, shallower depth, or the parallel fallback); slots and chips never move off the shared grid.
- §4 amendment: the per-column contribution caption sits **directly below the slot square** (moved out of the container when the value moved to the cube center; still column-aligned).

## 8. Verification protocol

Every implementation pass is checked against this spec via screenshots:

- Fixed 6-state checklist, always the same monster: planning start / mid-drag with preview / staged-uncommitted / player attack resolving / monster attack resolving / win-lose.
- Manual: snip + paste into chat. Planned: F12 debug-screenshot autoload saving PNGs into `screenshots/` (work order for Code Claude; gitignored).
Acceptance criteria — each maps to a screenshot state; Code Claude's build passes when all hold:

**Planning, idle:**
1. Zero dice motion. Nothing on screen animates while the player is thinking.
2. Monster stat chips are column-aligned with the player slots (column centers within ~10px).
3. Monster ring's surviving arc, the verdict line under its HP, the knob's deal number, and the player HP ring's dim segment all agree with `compute_outcome` for the current arrangement.
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
12. Damage/miss/block numbers pop at the actor they hit — around the monster's ring for your hits, at the knob ring for incoming.
13. A pre-commit "kills — takes nothing" reading is never contradicted by the resolution outcome.

**Structural (any state):**
14. No hardcoded column count or positions — container-driven layout that survives N=4.
15. Layout intact from 16:9 to 21:9; only the monster panel changes height.
16. Cancel/Confirm hit areas ≥80px (visual circles may be smaller).
17. Every overlay/screen reachable during combat returns to combat in one tap (GDD §9.1 depth law).
18. The next-pattern hint is recognition-first: mode icon + word ("incoming: evade"), exactly one step ahead, no raw stat dump, and the text never names a color (§6.4).
19. Bars and arcs are proportionally truthful: bright = post-damage remainder, dim = projected loss, empty = already missing — every drawn length matches its stated number ("never lie about a number" applies to geometry, not just text; user-caught when a mock's bar contradicted its own label).
20. No full-width horizontal element crosses the column field in any state (the gaze-fence rule).
21. Ownership fans present and correct: green reticle→chips, teal HP-ring→columns, dim, six lines total, right color families (§7.2); no chip→slot arrows anywhere.

## 9. Open decisions (live list)

1. ~~Prototype validation~~ RESOLVED — all three verdicts passed; see §5.
2. ~~Deal-on-knob + thin-strip S2~~ ADOPTED — see §5. "Take" anchors at the player HP line.
3. S1 internal split: sprite/ring size vs. stat chip row (fine-tune in Godot, not blocking).
4. ~~Element color unification~~ DECIDED — see §6. (Swatch 4th-neon-entry work order DONE 2026-06-12; `ELEMENT_COLOR`→`NEON_COLOR` swap in UI display code happens with the layout build.)
5. Cancel/Confirm visual size within the cluster (hit areas solved by criterion 16; pure styling).
6. Research to-do before wave 2: play Slice & Dice (closest relative — portrait dice combat; study its intent display, unlimited pre-commit undo, information density).
7. **Knob discoverability = wave-2 criterion** (Fable, 06-12): the chopsticks test proves comfort for a *taught* user, not discovery by an untutored one. Wave-2 telemetry must show untutored players find the flick; if not, the tap-tap redundant channel (§5 archive) gets promoted.
8. Demand-hint visual form (T4): icon chip vs. pattern-type halo. Halo path is blocked by the Godot 4.6 RichTextEffect outline gotcha (CLAUDE.md); icon chip is the safe default.
9. **Scouter: convey absolute max-HP on the ring.** A normalized ring can't distinguish max-10 from max-20 (both = a full circle), yet total HP matters for kill planning. Candidates: (a) HP-quantized reticle ticks — tick count/density = max HP (reuses the scouter's existing ticks; my lean); (b) ring radius/thickness scales with max HP (bigger monster = bigger ring; costs layout stability); (c) fixed degrees-per-HP so arc length = absolute HP (needs a cap / overflow ring). Affects `RadialBar._draw`. Undecided.

## Changelog

- 2026-06-12 — staring-phase finalization (UI Claude, all user-driven): S2 strip + HP bar abolished (gaze-fence rule, criterion 20); verdict docked under monster HP; player HP = knob ring; knob dial affordance restored (grip ticks + orientation notch); full-screen starfield adopted (tempo channel); §7.2 ownership fans (connection beat console-plate in head-to-head); chips snug above slots; slime sky-centered; criteria 3/12 updated, 20–21 added.
- 2026-06-12 — §7.1 added (UI Claude): vanishing-point dice rendering (user idea) — VP at live monster position, slot-centered shrink-to-fit cubes, label at perceived center, tumble-overrides-aim rule; classified pure tone (pairing info already carried by §4 column alignment — user's call), toggleable w/ parallel-extrusion fallback + wave-2 fresh-eyes question. §4 caption moved below the slot square.
- 2026-06-12 — §6 mirror sync (Code Claude): `Swatch.NEON_COLOR` + `HALF` gained the 4th (ghost-white/WHITE) entry, `from_name` gained `neon_white` — the §6.2 work order is built. `ELEMENT_COLOR`→`NEON_COLOR` swap in UI display scripts deferred to the layout build.
- 2026-06-12 — coherence pass (UI Claude): T4 lookahead made recognition-first per GDD §6.1 (criterion 18 added; demand-hint form = open item 8); T3 badge staleness fixed (tumble, matching Fable's §5 fix — reviewed and approved); T1 updated for adopted deal-on-knob (staging-as-preview supersedes ghost previews); zone table S2 → thin strip (adoption consequence, was stale); knob-discoverability wave-2 criterion logged (open item 7); GDD §9 reduced to laws + pointers.
- 2026-06-11 — §6 DECIDED: neon family canonical (RGB primaries retired from UI; WHITE reserved-dormant, 4th NEON entry required defensively; element colors only on element-bearing things; player text never names colors). Status → READY FOR BUILD.
- 2026-06-11 — all prototype verdicts passed (knob, wrap, deal-on-knob); deal-on-knob + thin-strip S2 adopted; §8 acceptance criteria written (17 items); status → VALIDATED; sole blocker = §6 color unification.
- 2026-06-11 — created: canvas, hierarchy, zone map, column spine, object model (fixed zones / moving dice), staging, verification protocol. Input mechanic left open.
- 2026-06-11 (later) — input mechanic working direction: player wheel (knob = rotate handle, dice = swap handles) + monster scouter reticle as its wheel; matched-angles rule replaces column alignment; two-vertices-up orientation. Conditional on knob passing the phone-prototype thumb test. Row candidates archived.
- 2026-06-11 — added §7 Motion: idle = still, motion only for uncertainty/change; dice spin states (roll reveal / frozen idle / staged-reroll tumble replaces the will-reroll text badge / light drag spin).
- 2026-06-11 — menu address (S0 left corner), visual-vs-hit-size rule, depth rule citation (canonical in GDD §9.1), Slice & Dice research to-do.
- 2026-06-11 — S3/S4 merged into one tray cluster (HP → dice row → knob, Cancel/Confirm flanking); tight-grouping rule added; wrap path declared animation-only; open list refreshed (touch-size violation on Cancel/Confirm flagged).
- 2026-06-11 (later still) — superseded by **row + knob**: dice row restores the column spine; knob below the row rotates it, Cancel/Confirm flank the knob (commit question resolved); scouter reticle kept as monster presentation; wrap animation flagged as design debt; deal-on-the-knob + thin-strip S2 proposed for prototype. Full wheel archived.
