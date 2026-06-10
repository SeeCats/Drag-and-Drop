# Project Drag N Drop — Game Design Document

> **Status:** Working draft (v0.1) reconstructed and expanded from the original pitch deck.
> **Genre:** Single-player mobile roguelite / tactical puzzle combat.
> **Platform:** Mobile (portrait, one-handed), touch-first.
> **Logline:** Split space-time into three dimensions and drag-and-drop energy to out-think monsters in a neon-lit war of space pirates.

*All numbers in this document are first-pass proposals for tuning, not final values. They exist to make the systems concrete and testable.*

---

## 1. Vision

### 1.1 One-paragraph pitch
Depth isn't the problem on mobile — *interfaces built for other inputs are.* You can play a deep game on your phone, but the moment it demands precise timing (dodging a Genshin boss) or dense menuing (the buy→equip→compare→test gear loop in an ARPG), you reach for a PC, because touch is bad at exactly those things. Touch is, however, excellent at **direct manipulation** — dragging and dropping. **Drag N Drop** is built so its *deepest* interaction is the gesture touch does *best*: every fight is a small puzzle solved with a single, deliberate drag-and-drop, resolved instantly with loud neon feedback — and the gear loop is held to the same tactile standard (§1.2 pillar 7). You play a privateer in a galactic war, raiding enemy ships and planets, keeping what you can tear loose, and building an ever-stranger arsenal as you go.

### 1.2 Design pillars
1. **Comfortable posture.** The entire game is playable one-handed, thumb-only, in portrait. UI lives in the bottom two-thirds of the screen.
2. **Simple input, deep output.** A round is committed with essentially one touch sequence. That single decision must branch into a wide space of meaningfully different outcomes.
3. **High strategy.** Reading the enemy and arranging your dimensions correctly is the skill ceiling. There is always a *best* play and it is rarely obvious.
4. **Instant dopamine.** A correct read pays off immediately and legibly — the screen tells you that you won the exchange before you have to think about it.
5. **Build freedom.** Drops from monsters let players sculpt their own win condition rather than chase one optimal build.
6. **Content via self-scaling difficulty.** Players opt into harder fights to raise reward odds, generating their own endgame content (see §8).
7. **Touch-native all the way down — including the gear loop.** Touch is bad at precise timing and dense menus, great at direct manipulation. Combat already honors this (drag a die, commit). The **build/equip/test/compare loop must be just as tactile and friction-free** — drag a piece of gear in, *instantly* see its effect on your dice, drag it out. This is the part most deep mobile games get wrong (the cumbersome ARPG gear-management loop is exactly why players retreat to PC), and it is currently the project's weakest, least-solved area (§12). If gearing is a menu slog, the whole positioning (§1.3) collapses even if the fights sing. Treat this as load-bearing, not polish.

**Signature mechanic — the swap re-roll.** Rearranging your dice is safe (Rotate); *swapping* a die re-rolls it. Every turn is therefore a push-your-luck choice — settle for the hand you have or gamble to dig for a better one. This is front-and-center to the game's identity and is taught early, not hidden (see §3.2).

### 1.3 Why this works on phone (rationale)
Touch fails at two things deep games lean on: precise/fast targeting and timing (action combat), and dense menus with many small targets (ARPG gear management). It excels at one: direct manipulation — dragging big objects. Most deep mobile games feel bad not because they're deep but because they express that depth through the two things touch is worst at, usually as a port of a mouse/controller design. Drag N Drop expresses its depth through the one thing touch is *best* at, so the interface stops being a tax on the player. The discipline this demands: never add a mechanic that needs twitch timing or tiny tap targets, and hold the gear loop to the same drag-native standard as combat (pillar 7) — otherwise the thesis holds in the fight and breaks in the menus. Precedent that this lane wins when executed: **Marvel Snap** (deep, mobile-first, tap/drag core), with Balatro and Hearthstone as softer evidence.

---

## 2. Core Fantasy & Tone

You are a sanctioned pirate — a **privateer** — in a war humanity is losing on paper. Far-future humanity broke from the Great Cosmic Council and declared war on the rest of the galaxy. Catastrophically outnumbered, the human government revived the ancient privateer charter: whatever you strip from the enemy, you keep, legally. The player is one such privateer, and the campaign is their rise from a single salvaged ship to a legend.

**The unifying idea — manipulating space-time *is* how you raid.** This is the spine that ties the mechanic, the fiction, and the art budget into one thing. A privateer doesn't shoot it out broadside-to-broadside; they **tear open space-time, pour raiders through the portal onto the enemy ship, and pull back before the counter-boarding lands.** "Splitting space-time across three dimensions" (§3) is not a sci-fi gimmick bolted onto piracy — it is the *act of raiding itself*. The combat verbs and the fantasy are the same gesture.

This makes the combat stats read **diegetically**, not abstractly:

| Stat | In the fiction |
|------|----------------|
| **BASE** (위력) | how hard each boarding strike hits |
| **MULT** (반복) | how many raiders / waves you push through the portal |
| **ANTI** (수비) | how you brace for their counter-boarding — *armor* (reinforce the hull), *evasion* (phase out through the portal), *strip* (sabotage their defenses before they fire) |
| **Dice colors** | flavors of portal / raid energy |

**Production payoff — one animation, used everywhere.** Because combat is symmetric (both sides use base/mult/anti, §3.4), the **same portal-and-raid animation serves the player's attack and — mirrored and recolored — the monster's attack.** A single VFX rig covers both sides *and* sells the entire space-time theme. The cheap route and the cohesive route are the same route.

**Tone:** Defiant underdog, heist-and-raid energy, high-contrast neon noir. Loud, confident, a little reckless.

**Art direction:** Lean hard into neon and emissive effects. Neon glow is cheap to produce and reads as premium, so the world, UI, enemies, and VFX are all built to exploit it — dark backdrops, saturated rim light, bloom, and color-coded energy. The combat colors (RED / GREEN / BLUE) are the visual backbone and must stay readable at a glance (see §3.3 and §10). **Beat repetition, not the budget:** the raid animation is one rig, but its *reading* varies by outcome — a big BASE hit is a bright, violent surge; a high MULT is a rapid flurry of small portals; a clean evasion is a phase-out shimmer. This masks the recycled animation in the short, frequently-watched fights *and* doubles as combat feedback (§10.2) — the same work serves both.

---

## 3. Core Combat System

### 3.1 The three dimensions
When the player "splits space-time," the released energy is distributed across three dimensions. Each dimension governs one combat stat:

| Dimension | Korean | Governs | Player-facing meaning |
|-----------|--------|---------|------------------------|
| **Power** | 위력 | How much damage one hit deals | "How hard" |
| **Repeat** | 반복 | How many times that hit lands | "How many" |
| **Defense** | 수비 | How you respond to the enemy's counter | "How safe" |

The fundamental damage identity for one combat round is:

```
Damage dealt = Power × Repeat
```

Splitting energy is the entire decision. Pour everything into Power and a single hard hit can be blunted; spread into Repeat and you chip reliably; bank into Defense and you survive a turn you'd otherwise lose. The tension is that energy is finite and the enemy's defense will eat part of whatever you build.

### 3.2 The dice, the slots, and the two verbs (as built)
The player has exactly **three dice**. Each die has:
- a **fixed color** — one RED, one GREEN, one BLUE (the WHITE element exists in the enum but is currently unused by the player; see §3.7);
- a **value 1–6** that is **re-rolled fresh every round**.

There are **three action slots** — **BASE** (damage per hit), **MULT** (number of hits), **ANTI** (defense). Each round, every die sits in one slot, and the die's *value* feeds that slot. The whole game is deciding which value goes where, using two verbs:

- **Rotate** — cycles which action (BASE/MULT/ANTI) is assigned to which die position. This is how you choose which of your three values becomes damage, hit-count, or defense. Rotate is the *safe* verb: it rearranges what you already have.
- **Swap — exchanges two dice's positions AND re-rolls the die you picked up.** This is a signature mechanic, not a side effect: swap is the *risky* verb. It is the player's only tool to **dig** for a better roll — trade a known value you don't like for a fresh random one, at the cost of disturbing your arrangement. The push-your-luck of "settle for this turn or gamble for a better one" is a core source of tension and must be taught and surfaced explicitly in the UI (e.g., show that a swap will re-roll, and which die). Never let it read as a hidden or accidental behavior.

**State model (precise).** The board is two rows over three **columns** (positions 0–2):

- **Action row** — the labels **BASE / MULT / ANTI**, one per column, each used exactly once.
- **Dice row** — the three dice, one per column. Each die has a **fixed color** (RED / GREEN / BLUE) and a **value 1–6** re-rolled at the start of every round.

A column's action reads the value of the die sharing that column. So each round resolves to:

- `BASE`  = value of the die in the BASE column
- `MULT`  = value of the die in the MULT column
- `ANTI`  = value of the die in the ANTI column
- `anti_type` (defense **mode**) = **color of the die in the ANTI column**

The two verbs move two *different* rows:

- **Rotate (safe)** — slides the **action row**: cycles which label sits over which column. Dice don't move, nothing re-rolls. Use it to re-pair your existing values/colors with BASE/MULT/ANTI.
- **Swap (risky)** — slides the **dice row**: exchanges two dice between columns **and re-rolls the die you picked up**. Action labels don't move. Use it to put a different color/value under a label and gamble a fresh roll.

Consequence: there are **two ways to change your defense mode** — *rotate* the ANTI label onto a different-colored die (no re-roll), or *swap* a different-colored die under the ANTI label (re-rolls). The defense mode is always just "whichever die currently sits under the ANTI label." (Maps directly to code: rotate cycles `action_index_list`; swap reorders the dice and re-rolls one; `anti_type` = color of the die in the ANTI column.)

Committing either verb ends the planning phase and resolves the round. This is the "drag and drop": you drag values into the right shape and the act of dropping commits the turn.

### 3.3 The anti-slot color decides your defense mode
This is the keystone rule. Your **defense type is the color of whichever die currently sits in the ANTI slot**:

| Die color in ANTI slot | Reduces the enemy's… | Defense mode | Best against |
|---|---|---|---|
| 🔴 **RED** | BASE (damage per hit) | **Armor** | Many small hits (low base, high mult) |
| 🟢 **GREEN** | MULT (number of hits) | **Evasion** | Few big hits (high base, low mult) |
| 🔵 **BLUE** | ANTI (their defense) | **Strip / setup** | Tanky enemies; enables your own all-in |

Because reducing MULT removes `anti × base` damage while reducing BASE removes `anti × mult`, armor wins against high-mult attackers and evasion wins against high-base attackers — the math backs the intuition. BLUE is the offensive defense: spending your anti to cut the enemy's anti means they mitigate *your* attack less the same turn, which is the bridge to a one-shot.

### 3.4 Damage resolution (deterministic, symmetric in structure)
Both sides hold the same four numbers: `[base, mult, anti, anti_type]`, and resolution is symmetric **in structure** — with one deliberate carve-out: **strip (anti_type = ANTI) is player-only; monsters defend via armor or evasion but never strip (§6.1).** Resolution each round:

1. **Player's anti reduces the monster's roll** at the index its color points to (BASE/MULT/ANTI), floored at a minimum of 1 (you can never fully zero a factor).
2. **Monster's anti reduces the player's roll** the same way, using the monster's own anti and anti_type.
3. **Both attacks resolve as `base × mult`** against the reduced rolls. Each surviving hit lands as a chunk; hits lost to a MULT reduction display as **MISS** pops, value lost to a BASE reduction displays as **BLOCKED**.

There is **no randomness in resolution** — the only RNG is the dice you roll at the start of the round. Given a roll and a visible monster pattern, the outcome of any arrangement is fully computable.

**Which factor to reduce (the floor matters).** When your anti cuts one of the enemy's factors, the damage you remove is:

> `removed = min(anti, factor − 1) × other_factor`

— the cut you can *actually* make, times the factor you didn't touch. The `factor − 1` is the min-floor (no factor drops below 1), so a large anti is **wasted** against an already-small factor. This produces two regimes, and the optimal target flips between them:

- **Anti large enough to floor a factor → reduce the *bigger* factor.** e.g. enemy `2 × 5`, anti 4: cut the 5 → `2 × 1`, removing **8**; cutting the 2 only removes 5 (three anti wasted on the floor).
- **Anti too small to floor → reduce the factor with the *bigger partner*** (usually the smaller factor). e.g. enemy `3 × 4`, anti 2: cut the 3 → `1 × 4`, removing **8**; cutting the 4 removes only 6.

Consequence: the best color to land in your ANTI slot depends on the enemy's *current roll* and *your anti value* — a per-turn read off visible numbers, not a fixed archetype lookup. This is emergent depth (discovered in play, not scripted). The live-outcome preview (§9.2) should surface it so players *feel* the floor-math rather than having to compute it.

### 3.5 The central tension (the knot)
Three random values, three colored dice, three slots — and they all compete. Your biggest value wants to be BASE (damage); but you also need a value on MULT (or your damage is multiplied by a small number); and the die you spend on ANTI determines *both* your defense value *and*, by its color, your defense mode. You cannot, for example, put RED's value into BASE **and** use RED to make your defense Armor — it is one die. Choosing your defense mode therefore costs you a specific colored value elsewhere. This coupling is the entire design; everything else is content wrapped around it.

### 3.6 Worked example (real model)
Monster pattern this round: `base 5, mult 2, anti 1, anti_type = BASE` (HP 12). You can see all of it.
Your roll: **RED = 5, GREEN = 4, BLUE = 1.**

- **Safe line (evasion):** rotate so GREEN(4) sits in ANTI → anti_type GREEN cuts the monster's MULT from 2→1. Put RED(5) in BASE, BLUE(1) in MULT. You deal `5 × 1 = 5` (monster's anti 1 cuts your BASE to 4 → `4 × 1 = 4`), monster to 8. Their counter is now only one hit of 5 → you take 5. You survive comfortably but the fight is slow.
- **All-in line (strip):** rotate so BLUE(1) sits in ANTI → cuts the monster's anti from 1→0, so your hit lands full. Put RED(5) in BASE, GREEN(4) in MULT → `5 × 4 = 20 ≥ 12` → **kill before the counter.** The right read here is aggression — and notice it was only possible because this roll handed you a high BASE *and* a high MULT at once. On a worse roll you'd take the safe line, or **swap** to gamble for a better one.

### 3.7 The WHITE element / open mechanic
WHITE exists in the element enum and color tables but has no combat role in the current build (the player's three dice are RED/GREEN/BLUE; `anti_type` only meaningfully targets BASE/MULT/ANTI). It is a free design slot: candidates include a wild die that can act as any color, a fourth "anti_type" that does something novel, or a resource for a meta-mechanic. **Decide its purpose or cut it** — leaving it half-defined invites confusion.

---

## 4. Player Progression Systems

### 4.1 Health, energy, and run state
A **run** is a single campaign attempt through the act/dungeon structure (§7). The player carries:
- **HP** — persists across rooms within a dungeon, restored at defined rest points.
- **Energy pool / dice count** — the size and quality of the hand drawn each round; grows with gear.
- **Equipment loadout** — the set of items installed in equipment slots (§4.2).
- **Relics / passives** — run-modifying effects collected from events and bosses (§4.3).

### 4.2 Equipment & slots
- Completing a dungeon awards **one piece of equipment of the player's choice** from that dungeon's reward pool.
- The player has a limited number of **equipment slots**. Builds are defined by which equipment occupies those slots.
- **Slots expand at Acts 2, 4, and 6:** completing a dungeon in those acts grants an **additional equipment slot**, widening the build over the run.

Equipment categories (proposed):
- **Dice modifiers** — change the hand: more dice, higher-value dice, recurring colors.
- **Track modifiers** — change how a dimension behaves: position-based bonuses, conversion (excess Power → Repeat), caps raised.
- **Defense tech** — new color behaviors, dual-color dice, retained defense across rounds.
- **Triggered effects** — on-kill, on-overkill, on-first-die, on-perfect-read payoffs that reward precise play.

### 4.3 Relics / passives
Smaller run-long modifiers found via events and elite/boss kills. Unlike equipment, relics don't take slots; they tilt the math (e.g., "+1 to the first Magenta die placed each round," "overkill damage carries to the next monster"). Relics are the texture that makes two runs of the same act feel different.

### 4.4 Meta-progression (cross-run)
Between runs, the player spends a soft currency (salvage / "prize" from the privateer fiction) on:
- Unlocking new equipment and relics into the run pools.
- Starting-loadout options and difficulty modifiers.
- Cosmetic neon palettes for ship and UI.

*Open question — see §12:* how strong meta-progression should be. The design leans toward **mostly horizontal** (more options) over **vertical** (raw power) to protect the strategy pillar.

---

## 5. The Build Game (deep dive)

The promise of pillar 5 ("build freedom") is that monster drops let players sculpt a personal win condition. With a base loop of only 3 dice and 3 slots, **the build layer is what grows the decision space** (see the §5.1 caveat) — equipment changes the dice, the values, the slots, or the resolution rules. Build identities form around which factor the player wants to break:

- **BASE-spike builds** — push for one enormous hit; rely on BLUE-strip so the hit lands full. Need gear that raises base or guarantees a high die.
- **MULT / volley builds** — many small hits; want gear that raises mult floors or adds dice; punished by RED-armor enemies.
- **ANTI / attrition builds** — win exchanges turn after turn; gear that retains anti or boosts its value; convert safe turns into BLUE setups.
- **Reroll / dig builds** — lean into swap's re-roll: gear that makes rerolling cheaper, safer, or stackable so you can sculpt the perfect roll.
- **Color-fixing builds** — gear that lets a die change color or adds a WHITE/wild die, breaking the §3.5 coupling so you can pick value *and* defense mode freely.

A healthy meta has no single dominant build because each is hard-countered by a recognizable enemy archetype (§6.2), so the player is rewarded for tailoring within their identity rather than autopiloting.

### 5.1 The base-loop caveat (most important balance risk)
With three dice and three slots, the arrangement space is small enough that an experienced player solves the optimal turn almost instantly. **Until equipment expands the loop, fights risk feeling mechanical.** Two levers protect the early game: (1) make the swap-reroll gamble matter (genuine dig-or-settle tension every round), and (2) introduce build pieces early and often so the rule-space — not just the numbers — keeps growing. Prototype the un-geared loop honestly before assuming the gear will save it.

### 5.2 Gear customization surface — decision checklist
Before designing the gear *UI* (pillar 7), decide what gear is allowed to *change*. Every item below is a real hook point in the current system. **Triage each Want / Maybe / Cut**, ⭐ the 2–4 that should define a build's identity, and be stingy — a smaller surface is easier to make tactile and to balance. ⚠️ = touches a core invariant or pillar.

**A. The dice themselves**
- Add a 4th die (and a 4th slot?) — biggest expansion of the decision space (§5.1).
- Raise a die's value range (e.g. 2–7) or flat +N to a die.
- Weighted / loaded dice (biased toward high or specific values).
- Add a WHITE / wild die — resolves the open WHITE question (§3.7); acts as any color.
- Let a die change color — ⚠️ partially breaks the §3.5 coupling (the core knot).
- Dual-color die — ⚠️ same caution.
- A die that does NOT reroll on swap — ⚠️ softens the signature swap gamble.

**B. The slots / actions**
- Add a slot / a 4th action type (beyond BASE/MULT/ANTI).
- A slot with a passive bonus ("BASE slot always +1").
- Position-based bonuses (leftmost/rightmost slot does extra) — gives ordering meaning.

**C. The mapping & coupling rules** ⚠️ *(the heart of the game)*
- Set anti_type independently of the anti-slot die's color — ⚠️ removes the central tension; reserve for a marquee build-defining piece only.
- A second ANTI (defend two factors at once).
- Convert overflow (excess BASE spills into MULT).

**D. The verbs (rotate / swap / reroll)**
- Extra action per turn — the "hold/pass" power-up (§7.4 / §3.2).
- A free swap that doesn't reroll (pure reposition).
- Extra / cheaper / safer reroll (e.g. keep the higher of old/new).
- Choose-the-value reroll — ⚠️ erodes push-your-luck.
- Rotate also does X (e.g. buffs the die landing in BASE).

**E. Resolution math & triggers**
- `base × mult` modifiers (+N base, ×2 if mult is 1, +N if all-same-color…).
- On-kill effects (overkill carries to next monster, heal, salvage).
- On-block / on-miss / on-evade effects (reward correct defense reads).
- First-hit / last-hit bonuses (ordering & combo builds).
- Change the min-floors (`[1,1,1,0]`) — ⚠️ letting a factor hit 0 enables full lockouts.

**F. Defense (anti) behavior**
- New anti modes beyond armor/evasion/strip.
- Anti that also deals damage (thorns / counter).
- Anti carryover (unused mitigation persists) — ⚠️ changes attrition math (§7.4).
- Lifesteal / heal-on-hit — ⚠️ fights the scarce-healing economy; rare & costed only.

**G. Information / lookahead**
- See 2 patterns ahead (vs. default 1, §6.1) — ⚠️ info overload risk on phone.
- Reveal an enemy weakness / exact stats early.
- Preview the value a reroll will land on — ⚠️ removes the gamble.

**H. Survivability / HP / run**
- Max HP increases.
- Heal at floor transitions (vs. only between dungeons) — ⚠️ loosens attrition tension (§7.4).
- Extra equipment slots beyond the Acts 2/4/6 baseline.
- Damage cap / one-time shield (anti-spike insurance).

**I. Meta / economy**
- Salvage gain, shop prices, reroll-the-shop.
- Legendary / drop odds (ties into §7.5 risk events).
- Relic synergy hooks (gear that buffs other gear / a color / a build tag).

**Decisions to lock before UI work:**
1. Which 2–4 surfaces define build identity (the ⭐ items)? Everything else is supporting texture.
2. How many of these are live at the *base* loop vs. unlocked only by gear (§5.1)?
3. **Data shape:** can every Want item be expressed as data on an equipment resource (like `Pattern` is) so designers add gear without code? This gates how fast the gear loop can iterate.
4. The hard "don'ts": which invariants are off-limits to gear entirely (e.g. never fully break the color coupling at common rarity; never let an anti floor reach 0 cheaply)?

---

## 6. Enemies & Encounters

### 6.1 Enemy stat model (as built)
A monster is a `Pattern` resource: `[base, mult, anti, anti_type]`, plus HP. Each monster holds a `pattern_list` and steps through it **cyclically** (`current_round % size`), setting its roll at the start of every round. That round's roll is **fully visible to the player** during planning — this is not a per-turn telegraph you might misread, it is complete information, and because the pattern repeats, a player who has seen the monster once knows the entire upcoming sequence. Skill is *planning against a known script under a random hand*, not reading a hidden intent.

Design implication: difficulty comes from **pattern shape and timing** (e.g., a big BASE spike every 3rd round you must prepare evasion for) and from **how well your roll can answer it**, not from surprise.

**A monster is a rotation, not a stat-block.** Its identity is the *sequence* of shapes in its `pattern_list`, not any single round's numbers. This matters because of a staleness trap: if a monster's shape never changes (e.g. always low mult), the **read** — "which factor do I counter?" — is solved on turn 1 and the defense color is the same forever (the awkward "GREEN every turn" problem). The knot survives (can you *afford* that color this roll?), but the *read-the-enemy* feeling flatlines. Fix: an interesting monster **rotates which factor it threatens** round to round — base this turn, mult next, a spike on the third — so you must re-read every round, and the one-step lookahead / conveyor planning (below) actually earns its keep (both are pointless against a monster that does the same thing every round). A *static* pattern isn't banned — it's a deliberate **rest fight** (§7.4) where defense is autopilot and only your offense allocation varies with the roll. Rule of thumb: a harder or more interesting monster has a **more demanding rotation**, not bigger fixed numbers.

**One-step lookahead.** The player also sees the monster's **next** pattern, not just the current one. This is what gives the forced single action (§3.2) a second job: your one move each turn should both resolve this round *and* migrate your persistent color/slot layout toward what's coming — turning "forced to act every turn" from a punishment into rolling, conveyor-style planning. Show the next pattern as *what it demands* (a glanceable "incoming: you'll want GREEN" hint), not raw numbers, so players plan by recognition rather than re-analyzing four stats every turn. Show only **one** step ahead — more floods a portrait screen and kills the snap-decision feel.

**Monsters defend only — strip is a player-only mode.** A monster's `anti_type` is always **BASE (armor)** or **MULT (evasion)**, never **ANTI (strip)**. Monsters reduce your damage or your hit-count; they never strip your anti. Two reasons: it keeps **anti-vs-anti** ordering weirdness out of resolution (`anti_operator()` applies the player's reduction before the monster's, so a mutual strip would be order-dependent and unintuitive), and it makes tearing open the enemy's guard part of the *player's* identity. Min-floors are `[1,1,0,0]` on both sides; the player's anti-floor of 0 is now just defensive cleanliness, since nothing ever strips the player.

### 6.2 Threat shapes (the vocabulary of rotations)
A monster's rotation (§6.1) is built from per-round **threat shapes**. These describe what a *single round* demands — a monster cycles through several of them; it is **not** "a Brute" for the whole fight. Use them as building blocks for sequences, not as labels stamped on whole monsters.

**The defense math (why the color isn't fixed).** Your ANTI prevents either:
- **RED / armor** (cut enemy base): `min(anti, base−1) × mult`
- **GREEN / evasion** (cut enemy mult): `base × min(anti, mult−1)`

Pick whichever is larger. The two have *different caps*: armor is capped by the enemy's **base** (can't shave a hit below 1) and scales with mult; evasion is capped by the enemy's **mult** (can't remove below 1 hit) and scales with base. So the best color depends on **your anti magnitude**, with a crossover:
- **Low anti** (below both caps): cut the *bigger* factor → Heavy (big base) wants GREEN, Flurry (big mult) wants RED.
- **High anti** (past the caps): armor → `(base−1)×mult`, evasion → `base×(mult−1)`; armor wins iff **base > mult** — so it **inverts**: Heavy wants RED, Flurry wants GREEN.

*Example, enemy base 5 / mult 2:* anti 2 → armor saves 4, evasion saves 5 → **GREEN**; anti 4 → armor saves 8, evasion saves 5 → **RED**. Same enemy, opposite answer, decided by your roll.

| Round shape | What it threatens | Your response |
|---|---|---|
| **Heavy** (high base, low mult) | one big hit | small anti → GREEN (negate the hit); large anti → RED (chip the fat base across both hits) |
| **Flurry** (low base, high mult) | many small hits | small anti → RED (flat cut × every hit); large anti → GREEN (evasion deletes many hits; armor is capped by the tiny base) |
| **Guarded** (high anti) | mitigates *your* attack | BLUE to strip, or just out-scale it — this is an **offense** problem, not a defense one |
| **Spike** (a burst round in the cycle) | a sudden lethal jump | pre-position the round *before* it lands, via lookahead (§6.1) |
| **Fragile** (high output, low HP) | a race | ignore defense; BLUE-strip all-in on a strong roll |

For **both** Heavy and Flurry the correct color is *conditional on your current anti value*, not fixed — and it literally inverts at high anti. That conditionality is the feature: it keeps "read the enemy" a live decision instead of a memorized lookup, and it's exactly what a static monster (§6.1) loses. It also means the defense read stays alive even against a *constant* monster, because the best color flips with whatever anti die your roll hands you. A good rotation then strings these shapes so the player's right answer keeps moving on top of that.

### 6.3 Elites & bosses
Elites and bosses are distinguished by **more demanding rotations** (§6.1) — longer or nastier sequences of threat shapes, tighter spikes, and adaptive tricks (e.g., a boss that punishes the player's *most-used* color, forcing you off autopilot) — **not merely bigger fixed numbers.** A boss that just has huge static stats is a stat check; a boss with a vicious *rotation* is a fight. They gate progress (§7.2) and drop the best rewards.

---

## 7. Content Structure — Campaign

### 7.1 Acts (the early game)
The early campaign is **~6 short acts** designed to teach the system in layers so new players ramp into mastery:

- Each act contains **3 dungeons**.
- Each act delivers a slice of story, equipment upgrades, and one or two new mechanics introduced gently.
- Completing a dungeon → **choose one equipment** from its pool.
- **Acts 2, 4, 6** → completing a dungeon also grants an **extra equipment slot**.

Suggested teaching curve:
1. **Act 1** — Power × Repeat, basic drag-and-drop, Magenta defense.
2. **Act 2** — Green defense + Swarm enemies; first extra slot.
3. **Act 3** — Cyan defense + Bulwark enemies; the offense-as-defense gamble.
4. **Act 4** — Position/order gear; Shifter enemies; extra slot.
5. **Act 5** — Multi-color and triggered effects; combo builds.
6. **Act 6** — Full toolkit, hardest bosses; final extra slot; bridge to endgame.

### 7.2 Dungeon structure
Each dungeon is **3 floors**:
- Each floor is a small map of **rooms** containing monsters or events.
- To advance to the next floor, the player must defeat that floor's **elite monster**.
- The **final floor contains both an elite and a boss.**
- Branching room choices let players trade safety for reward (an event vs. a fight vs. a treasure room).

### 7.3 Events & non-combat rooms
Events provide texture and choices: gambles, shops (spend salvage), forge/upgrade stations, relic offers, and story beats. They are the pacing valve between fights and a key source of build-defining relics. **For pacing to work, an event must be a *different kind of thinking* than a fight** — a narrative choice, a shop, a simple gamble — not another tight combat-style optimization, or it relocates stress instead of relieving it. Some events should be *purely* positive (a gift, a story beat at no cost) so the player gets a real exhale, not just a softer decision.

### 7.4 Stress, Pacing & HP Economy
The game runs **two different stresses on two different clocks**, paced independently:

- **Cognitive stress** (turn/fight clock) — the per-turn decision effort. Capped by keeping **fights short**, so the player never holds maximum concentration for long.
- **Attrition stress** (dungeon clock) — **healing inside a dungeon is scarce**, so HP doesn't come back and every fight matters. This keeps a low, constant dread running across the whole dungeon even though each individual fight is brief.
- **HP resets to full between dungeons.** Tension is per-dungeon; one bad early fight can't doom the whole run. (This is what makes the long ~6-act campaign survivable under scarce in-dungeon healing.)

**The cardinal rule — never peak both stresses at once.** The genuinely miserable state is a hard puzzle fight *while* at low HP with no heal in sight. Place easy fights and relief events so the player is rarely maxed on both axes for long. In playtesting, watch the *stacking*, not the average.

**Computation load vs. decision load.** Two kinds of mental effort, only one of which is the enemy:
- *Computation* (arithmetic, simulating outcomes) is pure tax — exhausting and unfun. **Offload it ruthlessly to the UI:** live outcome previews for every candidate action, results shown before commit, damage-after-reduction rendered for the player. If the player ever multiplies in their head, fatigue is leaking. Corollary: **keep numbers small** (values 1–6, HP in low tens) so `base × mult` stays glanceable; once gear inflates numbers, the UI must do *all* the arithmetic.
- *Decision* (weighing a real tradeoff — armor-and-survive vs. strip-and-gamble) is the actual game. Spend the player's whole mental budget here.

**No rest turns is the core fatigue risk.** With no default pass button (see below) and a forced action every turn, there are none of the "obvious" autopilot turns most turn-based games use to let the brain coast. Fix it through **encounter intensity pacing**: not every monster is a hard knot — design plenty of fights with an obvious dominant move (brain rest) and spike intensity on elites/bosses. Compose a fatigue rhythm the way a level designer alternates tense and loose rooms. Dice variance gives some of this for free; lean into it deliberately.

**HP is spendable, not just losable.** Pure "every point is precious" tips players into joyless over-caution and they stop taking the fun gambles. Let events trade HP for power ("pay 6 HP for this relic") so HP becomes a currency the player actively deploys, not only a meter they dread draining. Because HP refills between dungeons, spending it down inside one is a real, recoverable decision.

**Scarce healing sharpens every RNG moment — so RNG must always be *chosen*.** A bad swap-reroll or a big hit costs HP you can't recover, which stings. That's good *only if* the player opted into the risk. Lean on the full-information design: the player must always be able to *see and prevent* the catastrophic hit. The feeling must be "I took that because I chose greed over safety," never "a number I couldn't see mugged me."

**No pass button by default.** Forced churn is the intended anti-stagnation lever; the next-pattern lookahead (§6.1) is what makes the forced move purposeful (position your color/slot layout for what's coming). A pass/"hold" may exist as a **build-specific power-up**, not a baseline verb.

### 7.5 Risk events: gamble shapes
Risk/reward events all trade something for better loot, but *how* they're structured changes the felt stress far more than the raw numbers do. Two structures, very different profiles:

**Resource-cost gambles** — e.g. *"pay 5 HP for a 15% chance to upgrade the drop to legendary."*
- Stress is mostly *psychological*, and larger than the number implies. **Certain upfront cost + probabilistic back-end reward is the most regret-heavy shape there is** (slot-machine framing: you pay for sure, usually get nothing). Loss aversion makes a flat HP cost feel ~2× its size.
- It's *state-dependent*: trivial at full HP early, dangerous at low HP late — so it stacks worst exactly when attrition is already peaked (violates the §7.4 cardinal rule). The metric that matters is *when it's offered*, not the cost.
- Rules to keep the thrill without the corrosion:
  - **Flip the framing** to certain-reward / risked-cost ("make the drop legendary — 15% chance it costs 5 HP") — same math, far less regret.
  - **Higher proc + higher cost** trains less disappointment than low/low at similar EV.
  - **No total losses** — on a fail give *something* (a rare, or refund half the HP).
  - **Gate from low-HP offers**, or make the cost a % of current HP.
  - **One or two per dungeon max** — more turns the dungeon into a casino and the gambling economy outweighs the combat economy.

**Difficulty-cost gambles** — e.g. *"the boss gains +1 base damage; legendary drop chance is doubled."* Generally the **healthier** shape:
- The cost is **contestable by skill** (counter +1 base by putting RED in ANTI), so it's *competence* stress, not gambling regret — the good kind for this audience.
- It's **deterministic and visible** (the player sees the boss pattern and opts in with full info) — no variance-regret on the cost side.
- It **settles on the spot** — once the boss is dead the cost is gone; no attrition debt carried through the dungeon.
- It **spikes intensity at the boss**, exactly where pacing already wants the peak, and the penalty *constrains build choice* on that fight rather than just inflating a number.
- Watch-outs:
  - **Bigger failure tail** — losing the harder boss can cost the whole dungeon, so it's a high-stakes bet. Make the commit **irreversible and fully informed** (show the pattern before opting in).
  - **State the *effective* cost, not the raw modifier.** "+1 base" scales by the boss's mult (`base × mult`): +1 base on a mult-4 boss is +4/round. Communicate the real number.
  - **Define "doubled" vs. "guaranteed."** Doubling a small proc is a modest carrot for a dungeon-losing risk; a guaranteed legendary justifies a steeper cost. Pick deliberately.
  - **Ladder vs. §8.** This is the endgame penalty-for-reward mechanic appearing in the campaign; keep campaign versions mild so the endgame's *stacked* penalties stay distinct.

**Rule of thumb:** prefer costs the player *plays through* (difficulty, build constraints) over costs they *carry* (HP, lasting debuffs); prefer *risked cost / certain reward* over *certain cost / risked reward*; and always make the gamble a fully-informed choice.

### 7.6 Perceived vs. real difficulty (deceptive difficulty — the honest kind)
**Target: the player judges a fight ~50/50 while actually winning ~90%.** Humans are loss-averse (a loss stings ~2× a win) and bad at probability — we remember losses and forget routine wins — so a *genuinely* even fight feels brutal and a true 85–90% win rate is *remembered* as a coin flip. Designing for high *perceived* tension and low *actual* failure is good craft (Sid Meier's Civilization fudged combat odds in the player's favor for exactly this reason).

**But there are two ways to open that gap, and only one is allowed here.**

- ❌ **Fudge the numbers** (display ≠ reality, secret low-HP buffers, fudged hit chances). Effective in many games, but it carries a **betrayal risk** — when players catch the lie they stop trusting the game's information (the XCOM "95% and I missed" problem). For *this* game it's disqualifying: the whole design rests on full information + deterministic resolution + "a correct read is a *guaranteed* payoff" (§3.4). Fudging saws off that branch, and our players — trained to reason from visible numbers — are the most likely to catch it. **§3.4 stays sacred. Never lie about a number.**
- ✅ **Present honest-but-intimidating situations.** Never lie; aim the player's misjudgment at the *situation*, not the math. The threat is real and fully visible, but a correct read almost always has an out. The ~90% comes from "a competent line survives," not from a hidden buffer. This is the Into the Breach model (perfect information, boards that look unwinnable and almost always aren't), and it's the model we use.

**The lever is already built in: visible big numbers + the floor-math (§3.4).** A `2 × 8` attack reads as "16 incoming, I'm dead" to a novice and is a trivially gutted threat to anyone who's internalized the system. The deception lives entirely in the gap between novice intuition and the real optimal line — which means it's not a lie, it's a **skill gap**, and closing it *is* the game. The same gap doubles as skill expression and the "feel clever" dopamine (§10.2).

**Caveat — it expires with mastery.** A master eventually perceives the true ~90%, the threats stop scaring them, and the engineered tension evaporates. That's a clock, not a flaw: the campaign is where deceptive difficulty does its work; the **endgame penalty dungeons (§8) are what re-supply *honest, opt-in* tension** once players see through the early illusion.

---

## 8. Content Structure — Endgame (self-scaling dungeons)

After the campaign, the player runs **interstellar dungeons** to craft specific target equipment. The twist that generates effectively unlimited content:

> Each time you defeat a monster, you may take on an **added penalty** in exchange for a **higher reward ceiling** for the dungeon.

Players stack penalties (tougher modifiers, stat handicaps, nastier enemy patterns) to push reward odds for the exact item they want. This converts difficulty into a player-authored content treadmill: the game gets exactly as hard as the player chooses to make it, and the loot scales to match. It also gives theorycrafters a sink: a build is "good" insofar as it can carry deep penalty stacks.

**Design guardrails:**
- Penalties should be **legible and pre-committed** (you see what you're signing up for).
- Reward scaling should favor **odds and selection**, not raw power, to protect the meta.
- A soft "you can stop now" off-ramp each floor prevents loss-aversion spirals.

---

## 9. Controls & UX

### 9.1 Layout
- **Portrait, one-handed.** All interactive elements live within comfortable thumb reach (bottom ~65% of screen). The enemy and telegraph sit up top for reading; the dice tray and three dimension tracks sit at the bottom for doing.
- **Primary verbs:** drag a die, drop a die, swap, reorder, confirm. Nothing else is required to play a round.
- **One commit.** A single confirm resolves the round; an undo is available *before* commit only.

### 9.2 Readability
- Color-coded everything: RED/GREEN/BLUE mean the same thing on a die, in the ANTI slot, in the resolve VFX, and on the enemy's visible roll.
- Numbers are always shown live as the player arranges: projected `Power × Repeat`, projected damage after enemy defense, projected incoming after player defense. The player should never have to do mental math to see the outcome of the current arrangement — they should only have to *decide*.

### 9.3 Accessibility
- Color is never the *only* signal: each anti color also carries an icon (e.g., RED = shield/armor, GREEN = dodge/stutter, BLUE = crack/strip) for colorblind players, since the anti-slot color carries critical meaning.
- Left-handed mirror mode.
- Adjustable bloom/flash intensity for photosensitivity, without hiding gameplay information.

---

## 10. Art, Audio & Feedback

### 10.1 Visual direction
Neon-emissive on dark backdrops, exploiting cheap-but-premium glow. The space-pirate-vs-galaxy fiction justifies dramatic lighting, ship interiors, and alien fleets. Each dimension and defense color owns a hue and that hue is used everywhere it appears.

### 10.2 Game feel
The dopamine pillar is delivered in the **resolve** step. A correct read should produce an immediate, unmistakable success beat: screen-reactive flash in the winning color, satisfying impact on each Repeat hit, an escalating audio sting for big multipliers, and clean "you won this exchange" framing *before* any numbers need parsing. Overkills and perfect reads get extra celebration.

### 10.3 Audio
Synthwave / darksynth bed that intensifies with combat momentum; distinct, color-mapped SFX per defense type; a recognizable "split" sound when energy is released each round.

---

## 11. Technical & Production Notes

- **Engine:** **Godot 4.6** (already the project engine). Combat runs on a `CombatState` FSM with global signals; rolls live on the `CurrentRoll` autoload.
- **Architecture:** Resolution is already deterministic — `anti_operator()` then symmetric `base × mult` attacks. Keep it a pure function of the committed roll + monster pattern so fights stay reproducible for testing. Note the current `swap()` re-rolls a die: keep that intentional and documented, not incidental.
- **Content pipeline:** Enemies, equipment, relics, and penalties are **data-defined** (tables/ScriptableObjects) so designers can tune and add content without code.
- **Build target:** 60fps on mid-range phones; portrait only at launch.
- **Live concerns:** seeded daily/weekly challenge dungeons reuse the endgame penalty system for retention at low content cost.

### 11.1 Prototype scope (vertical slice)
Smallest build that proves the fun (most of this already exists):
1. The round loop: 3 dice (RED/GREEN/BLUE), rotate + swap, all three anti-slot defense modes. **(built)**
2. Three enemy patterns that demand different anti colors (Brute→GREEN, Swarm→RED, Bulwark→BLUE) plus one Spiker with a periodic burst round.
3. Live projected-outcome UI: show the result of the current arrangement *and* preview the swap-reroll gamble clearly.
4. The key test: with no equipment, is each turn still a real decision, or is the optimum obvious? If it's obvious, the loop needs more (more dice/slots, or a sharper reroll gamble) **before** building content on top.

---

## 12. Open Questions / To Decide

Consolidated tracker of everything still unresolved, grouped by *what kind of answer it needs*. Settled topics (telegraphs, one-action-per-turn, swap-reroll, no-pass-default, lookahead, HP economy, gamble shapes) are not listed.

### 12.1 Must be answered by prototype / playtest (not by discussion)
1. **Base-loop depth before gear — the #1 risk.** Does 3 dice × 3 slots stay a real decision un-geared? Everything rests on this; see §5.1. If the un-geared optimum is obvious, fix the loop before stacking content.
2. **Fatigue, measured.** Watch the *pause rhythm* in playtests — most turns snapped, occasional long deliberations = healthy; a long stare every turn = decision paralysis (too much un-offloaded computation or too many max-intensity fights back-to-back).
3. **"All-in feels passive?"** Does waiting for a lethal roll feel like agency or like waiting on RNG? The swap-reroll dig is the intended antidote — verify it actually feels that way.

### 12.2 Design decisions not yet made
4. **WHITE element.** Still undefined and half-wired into the code's action enum. Give it a role (wild die? novel anti_type? meta-resource?) or cut it.
5. **Meta-progression strength:** horizontal (more options) vs. vertical (raw power). Current lean: mostly horizontal, to protect the strategy layer. Confirm.
6. **Per-dimension soft caps:** needed to prevent one-stat degeneracy, or do enemy archetypes self-correct it?
7. **Monetization:** premium, cosmetic-only, or battle-pass over challenge dungeons? Must not touch the strategy layer.
8. **Hand economy / persistence:** values re-roll fully each round and only color/slot *layout* persists (as built). Confirm that's intended; decide whether gear ever changes it (e.g., lock a die, add a 4th).
9. **Run length & session unit:** ~6 acts × 3 dungeons × 3 floors vs. a 5–15 min target. HP resets between dungeons, so a *dungeon* is the natural checkpoint — confirm and add mid-dungeon save/resume.

### 12.3 Tuning numbers to pin down
10. **"+1 base" effective cost** scales by the boss's mult (`base × mult`); state the real per-round number, not the raw modifier (§7.5).
11. **"Doubled" vs. "guaranteed" legendary** on difficulty-cost events — decide which; they justify very different costs (§7.5).
12. **base × mult balancing curve.** Multiplicative damage is a tuning minefield as numbers grow (+1 swings hugely at low values, trivially at high). Decide how/whether numbers inflate, and keep the UI doing all arithmetic if they do.
13. **Endgame economy:** how penalty stacks map to reward odds without becoming a grind wall — and keep campaign difficulty-events (§7.5) milder than the endgame's *stacked* penalties so the two don't flatten into each other.

### 12.4 Strategic concerns
14. **Market thesis — RESOLVED, reframed (§1.1/§1.3).** Not "games are shallow" but "deep mobile games are bottlenecked by interfaces built for other inputs; touch excels at direct manipulation, so we make the deep interaction the drag gesture." The thesis now *depends on* item 15 below.
15. **The gear-loop UX is the make-or-break, and is currently unsolved (acknowledged).** Pillar 7 demands the build/equip/test/compare loop be as tactile and friction-free as combat — drag gear in, instantly see its effect on the dice, drag it out. The cumbersome ARPG gear-management loop is precisely what the positioning promises to beat, so a menu-slog here collapses the whole pitch. **This is the highest-leverage unsolved design+UX problem in the project.** (Wants its own design pass — say the word.)
16. **Differentiation — conceptually RESOLVED, pending validation.** Three distinct, honest axes: (a) the combat *knot* — color-coupled defense is a combat fingerprint no genre leader has; (b) touch-native depth (the drag is the deep act); (c) one-handed / portrait, unlocking usage contexts landscape games can't serve. The "why this not that" has real substance. **Contingent on item 1 (base-loop must actually have legs) and item 15 (one-handed/touch promise must survive into the gear & menu screens)** — same unknowns, different hat. Marketing articulation deferred.
17. **Theme cohesion — RESOLVED (§2).** Bridged: *manipulating space-time **is** how you raid* (tear a portal, board the ship, pull back). The mechanic, the fantasy, and the art budget collapse into one act, and the symmetric combat lets a single portal-raid animation serve both player and monster attacks. Remaining work is execution-only: vary the animation's *reading* by outcome to beat repetition (also serves as combat feedback).

18. **Audience / posture — INTENT SET: snackable-deep (not a contradiction).** "Snackable" (short, interruptible, low-friction, one-touch) and "brain-heavy" (deep per-decision) are *different axes*, not opposites. Depth only breaks snackable when it adds **hidden state to hold in your head** or **arithmetic to do in your head** — both already deleted by full information + deterministic resolution + UI-does-the-math (§3.4, §7.4, §9.2). So depth here is *transparent*, not taxing. Precedent that this quadrant exists: **Into the Breach** (deterministic, perfect-information, short tactical puzzles; shipped on mobile) and, more loosely, Marvel Snap. The open question is therefore **not** "can they coexist" (they can) but the **two risks that decide whether we land it**:
    - (a) **The onboarding cliff.** Snackable-deep games play easy turn-to-turn but have a steep *first-session* comprehension cost — the color-coupling knot (§3.5) is a lot to load up front. Treat the first ~10 minutes as a *designed artifact*, not a tutorial afterthought (§7.1).
    - (b) **Intensity density.** Snackable survives only if *most* turns are light with knots as visible, opt-in spikes (§7.4). If tuning drifts so every fight is a max-depth puzzle, it stops being snackable even if no single turn got harder. Watch the **density** of hard turns, not their peak difficulty.

    Both are measurable in playtest (pause-rhythm, §12.1.2). This is the ambitious-but-deliberate landing spot; it depends on the same unknowns as items 1 (base-loop legs) and 15 (gear loop staying tactile).

### 12.5 Content work queued (drafts I can produce on request)
19. **Early monster patterns engineered to force color-conflict dilemmas** — the thing that keeps the small loop tense.
20. **Encounter intensity-pacing map** — which fights are brain-rest vs. spikes, per dungeon.

---

## 13. Glossary

- **Slot / action** — one of BASE (위력, damage per hit), MULT (반복, number of hits), ANTI (수비, defense); the three things a die's value can feed.
- **Dice** — three per player, each a fixed color (RED/GREEN/BLUE) with a value 1–6 re-rolled each round.
- **anti_type** — what your ANTI reduces on the enemy, set by the *color* of the die in the ANTI slot: RED→their base (armor), GREEN→their mult (evasion), BLUE→their anti (strip/setup).
- **Rotate / Swap** — the two verbs. Rotate reassigns actions across dice; Swap exchanges two dice positions and **re-rolls the picked-up die**.
- **Pattern** — a monster's `[base, mult, anti, anti_type]`; monsters cycle a fixed, fully-visible list of these.
- **Act** — a campaign chapter; ~6 total, each with 3 dungeons.
- **Dungeon** — a 3-floor unit ending in elite + boss; awards one equipment.
- **Slot** — an equipment mount; expands at Acts 2/4/6.
- **Interstellar dungeon** — endgame, self-scaling content where penalties buy higher reward odds.
- **Relic** — a slotless run-long passive modifier.

---

*End of v0.1. This document reconstructs the original pitch and extends it into a full first-pass design. Every concrete number is a starting point for playtesting, not a commitment.*
