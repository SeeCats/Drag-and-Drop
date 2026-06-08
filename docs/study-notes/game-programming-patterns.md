# Study Notes — Game Programming Patterns

Notes from reading Robert Nystrom's *Game Programming Patterns* (free at https://gameprogrammingpatterns.com), focused on the relic / status-effect system. Phone-friendly summary — see `docs/adr/ADR-001` for the actual decision.

---

## How the patterns relate (the big picture)

The five patterns behind the effect system, and what each one is in our code:

1. **Command** — reify an action into an object you can store/pass/run later → our `Event`.
2. **Chain of Responsibility** — route that action through an ordered list of handlers, each free to act or pass it on → our `EffectPipeline`.
3. **Event Queue** — add a buffer so the action is processed *later* (decouple in time) → deliberately skipped (callers need an answer now).
4. **Component** — build an entity from composable parts instead of one giant class → Godot nodes; `EffectPipeline`/`Hp` as nodes on a Character.
5. **Type Object** — define "kinds" as data instead of subclasses → relics/statuses as `Effect` `Resource`s (and `Pattern`).

Our effect system = **Command + Chain of Responsibility, stayed synchronous**; effects authored as **Type Objects**, attached as a **Component** (node) on each Character.

---

## Event Queue (https://gameprogrammingpatterns.com/event-queue.html)

**Intent:** decouple *when* a message is sent from *when* it's processed.

**Key idea:** sender drops a request in a queue and returns immediately; a processor drains the queue later (FIFO). Decouples sender/receiver both in code *and in time*.

**When to use it:** ONLY when you need to decouple *in time*. If you just need to decouple *who* talks to *whom*, plain Observer (Godot signals / `GlobalSignal`) is simpler. Think push vs pull: sender pushes, receiver pulls on its own schedule → you need a buffer between them.

**Why WE don't use it:** when a behavior happens (swap attempt, reroll, damage calc), the caller needs the answer *right now* ("is this allowed?", "what's the final damage?"). The sender needs a response, and queues are a poor fit when the sender needs a response. So effects resolve **synchronously**.

**Gotchas (and how they hit us):**
- *A central queue is a global variable* — danger scales with the number of writers, not entities. Even with 1 player + 1 monster, many relics writing shared state is risky. → keep the pipeline **per-character**; funnel all writes through it.
- *The world can change under you* — only a problem for *delayed* processing. Synchronous dispatch dodges it, so our events can stay lean and read live state.
- *Feedback loops* — A triggers B triggers A. Synchronous = crashes loudly (easy to find). Rule: don't send events while handling one → defer effect-spawned effects until after dispatch. Add debug logging.

**Many readers vs many writers:** many listeners on a signal = fine (fan-out). Many uncoordinated writers to shared state (e.g. `CurrentRoll`) = bad. Fix isn't "never write" — it's funnel all writes through one ordered path (the pipeline): many *proposers* + one *writer*.

---

## Command (https://gameprogrammingpatterns.com/command.html)

**Tagline:** *a command is a reified method call* — a method call wrapped in an object you can store in a variable, pass around, and run later. (OO replacement for a callback.)

**Configuring input:** replace hard-wired `if pressed_x: jump()` with a command object per button, so the binding becomes *data* you can swap. Tell for spotting it: an interface with one method, no return.

**Directions for actors (most relevant to us):** pass the target into `execute(actor)` instead of hard-coding it. → this is exactly our `handle(event, host)`. One relic resource works on either character because the target is passed in. AI can emit the same command objects the player's input does → monster and player share one path.

**Reusable vs one-shot commands:**
- reusable, stateless, "a thing that *can* be done" → like our **relics** (one configured object, reused).
- one-shot, carries its own data, "a thing that *was* done" → like our transient **events** (made fresh per action).

**Undo/redo (not needed now):** give each command an `undo()` that records old state in `execute()` and restores it. Multiple undo = list of commands + a "current" index. The transferable lesson even without undo: *every state change goes through a command* = the same "funnel all writes" discipline. If we ever want a rewind relic or replay, this is the structure.

**Class vs closure (answers "do I need a class?"):**
- one operation, little state → a `Callable` (GDScript lambda) is enough.
- multiple operations OR shared state → use a class/Resource.
- GDScript makes this sharper: lambda captures are *copies*, so two lambdas can't share a mutable var cleanly. Our `Effect` has `handle`/`on_apply`/`on_remove` + state → **class/Resource is correct**.

---

## Component (https://gameprogrammingpatterns.com/component.html)

**Intent:** let one entity span multiple domains without coupling them. Split each domain (input, physics, graphics…) into its own component; the entity becomes a thin container of components. Composition over inheritance (avoids the "deadly diamond"; à la carte vs fixed combos).

**For us:** mostly confirmation — **this IS Godot's node system.** A Character with `Hp`, `Cube`, and (soon) `EffectPipeline` nodes is the Component pattern. Validates "pipeline as a node on the Character."

**The useful part — how components communicate (we use all three):**
- *Shared container state* — read/write the entity's shared fields (≈ `CurrentRoll`). Decoupled but **order-dependent** + shared-mutable-state hazard → why effect **priority** matters.
- *Direct references* — fast but tightly couples the pair. Use sparingly.
- *Messages* — container rebroadcasts to components (GoF **Mediator**) ≈ our `EffectPipeline` / `GlobalSignal`. Can be queued → Event Queue.

**Strategy vs Component:** a Strategy is *stateless* behavior; a Component *holds state/identity* — same axis as stateless `Callable` vs stateful `Effect` Resource.

---

## Type Object (https://gameprogrammingpatterns.com/type-object.html)

**Intent:** create new "classes" flexibly by making ONE class whose **instances** each represent a different type. The "type" becomes data, not code. (This is the pattern our relics-as-`Resource` is built on.)

**The shift:** instead of `Dragon`/`Troll` subclasses, have one `Monster` + one `Breed`; each monster holds a *reference* to a `Breed` (shared data: health, attack). Add new kinds by instantiating `Breed` with new values / loading from data — no recompile. `Pattern` already does this; `Effect` is the same idea for relics.

**The crucial caveat — data is easy, behavior is hard:** Type Object replaces an overridden method with a *member variable*. Great for type-specific *data* (a number, a string), hard for type-specific *behavior* ("skip highest die", "block swap"). Nystrom's workarounds: a fixed menu of behaviors selected by data (≈ function pointers / vtables), or full data-driven scripting (Interpreter/Bytecode).
**Our resolution:** GDScript `Resource`s carry a script, so each relic is a small **`Effect` subclass overriding `handle()`** — Type Object (authored `.tres`, no recompile) *plus* real per-type behavior, using the engine's own dispatch. So: `Pattern` = pure Type Object (data only); `Effect` = Type Object + behavior.

**Inheritance between type objects (relic families/tiers):** give a type a `parent` and inherit non-overridden fields. *Copy-down* (copy at creation) = fast, frozen; *dynamic* (walk to parent each read) = live-updatable, slower. In Godot: `@export var parent: Effect` + pick the parent `.tres`. Use **single inheritance** (sweet spot); avoid multiple.

**Relic vs status = Type Object vs State:**
- **Relic ≈ Type Object** — invariant, "what the thing *is*," lasts the whole run.
- **Status ≈ State** — temporal, "what's true *right now*," added/removed with a duration.
Both are `Effect` subclasses (one mechanism), but the lens helps reasoning: relic = identity; status = a passing condition.

---

## GDScript type mapping for our system

| Role | Base type | Why |
|------|-----------|-----|
| `Effect` (relic/status) | `Resource` | Authored data asset; inspector + `.tres` + `duplicate()`; data + behavior (Type Object). Same family as `Pattern`. |
| `Event` (the action passing through) | `RefCounted` | Transient, created per action, auto-freed; no asset/serialization baggage. |
| `EffectPipeline` (holder) | `Node` | Lives on a Character in the scene tree; has lifecycle + tree access. |

Hierarchy reminder: `RefCounted` = auto-freed value objects (Events) · `Resource` extends RefCounted, adds save/load + inspector + `duplicate()` (Effects) · `Node` = lives in the scene tree (Pipeline).

---

## Reading list

- [x] Event Queue — read
- [x] Command — read
- [x] Component — skimmed (it's Godot's node system)
- [x] Type Object — read (relics/statuses as `Resource`s)
- [ ] Observer — https://gameprogrammingpatterns.com/observer.html (what `GlobalSignal` already is)
- [ ] Chain of Responsibility (GoF, not in this book) — the literal shape of `EffectPipeline.dispatch()`
- [ ] Reference repo: wyvernshield-triggers — priority-based modifier triggers, closest to our design
- [ ] Godot custom Resources docs — `duplicate()`, `resource_local_to_scene`
