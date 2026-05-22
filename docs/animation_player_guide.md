# Godot AnimationPlayer — Full Tutorial

A complete reference for using Godot 4's `AnimationPlayer` node: tracks, keyframes, code playback, and integration with the wider animation system.

---

## 1. What is AnimationPlayer?

`AnimationPlayer` is Godot's central node for **timeline-based animation**. It records property changes (and method calls, audio cues, etc.) on a timeline and plays them back. It can animate **any property of any node** in the scene — positions, rotations, colors, shader parameters, custom script variables, even other animations.

**When to use it:**

- UI element animations (fade-ins, slide-ins, button hover effects).
- 2D and 3D character motion (walk cycles, attacks, idle breathing).
- Cutscenes with synchronized audio, camera, and event callbacks.
- Property tweening that needs **authored timing** rather than procedural easing.

**When NOT to use it:**

- One-shot procedural tweens — use `Tween` (created via `create_tween()`) instead. It's lighter and code-driven.
- Frame-by-frame sprite animation only — `AnimatedSprite2D` / `AnimatedSprite3D` are simpler for pure frame swapping.
- Complex state blending — use `AnimationTree`, which sits on top of an `AnimationPlayer`.

---

## 2. Adding AnimationPlayer to a Scene

1. Select the parent node that owns the animation (e.g. your character root).
2. Click **+ Add Child Node** → search "AnimationPlayer" → add.
3. Select the new `AnimationPlayer` node — the **Animation Panel** appears at the bottom of the editor.

The bottom panel is your animation editor: animation dropdown on the left, timeline in the middle, track list below.

---

## 3. Animation Storage

Each animation is a `Resource` (a `.tres` or built-in). You can:

- **Embed** animations in the scene file (default — easiest, but not reusable across scenes).
- **Save to external library** — click the wrench icon → **Manage Animation Libraries** → save the animation to a `.tres` file. This lets multiple scenes share the same animation.

Animation libraries are first-class in Godot 4 — you can load a library at runtime via `AnimationPlayer.add_animation_library(name, library)`.

---

## 4. Creating an Animation

1. In the Animation Panel, click **Animation → New**.
2. Name it (e.g. `idle`, `attack`, `fade_in`).
3. Set its **length** in seconds (top-right of the timeline).
4. Set its **step** (e.g. 0.1s) — keyframes snap to this grid.

The very first animation should typically be called **`RESET`** — Godot uses it to restore default property values when animations are interrupted or the scene loads.

---

## 5. Tracks

A track is a single channel of animation — one property or one event over time. Add a track via the **+ Add Track** button.

### Track types

| Track | Purpose |
|---|---|
| **Property Track** | Animate any property on any node (position, modulate, custom script vars). |
| **3D Position / Rotation / Scale** | Optimized 3D transform tracks. |
| **Blend Shape** | Animate mesh blend shape weights. |
| **Method Call** | Call a function on a node at a given time. |
| **Bezier** | Animate a numeric property with full bezier curve control. |
| **Audio Playback** | Trigger audio clips on an `AudioStreamPlayer*` node. |
| **Animation Track** | Play another animation inside this one (useful for compound animations). |

### Adding a property track quickly

You don't usually need to manually add tracks. Instead:

1. Click the **key icon** (🔑) next to a property in the Inspector while the AnimationPlayer is selected.
2. Godot creates the track and inserts a keyframe automatically.

This is the fastest workflow — change a value, hit the key icon, repeat.

### The "Animation" autokey toggle

The small **red record button** at the top of the timeline enables **autokey**: any property change you make in the inspector while playing back creates a keyframe automatically. Great for quick iteration; turn off when you're done so you don't pollute the animation.

---

## 6. Keyframes

A keyframe stores a value at a moment in time. The animation interpolates between consecutive keyframes.

### Adding a keyframe

- **Inspector route**: change a property, click the key icon next to it.
- **Track route**: right-click the timeline at the desired second → **Insert Key**.
- **Autokey**: as above.

### Editing keyframes

- Click a keyframe to select it. The Inspector then shows:
  - **Time** — exact position on the timeline.
  - **Value** — the property value at this key.
  - **Easing** — how interpolation curves toward this key.
- **Drag** keyframes horizontally to retime them.
- **Right-click** for cut/copy/paste/duplicate/delete.

### Interpolation modes (per track)

Set on the track's small icon row (left of the track):

- **Nearest** — step (no interpolation). Good for frame swaps.
- **Linear** — straight-line interpolation.
- **Cubic** — smooth curves.
- **Linear Angle / Cubic Angle** — wraps around at 360° for rotations.

### Update modes (per track)

- **Continuous** — value updates every frame (default).
- **Discrete** — value only applied at keyframe times.
- **Capture** — at the start of the animation, captures the property's current value as the implicit start, then interpolates *to* the first keyframe. Useful for blending into an animation from arbitrary state.

### Easing

The **easing** value on a keyframe shapes the curve approaching that key:

- `1.0` — linear.
- `> 1.0` — ease-in (slow start, fast end).
- `< 1.0` — ease-out (fast start, slow end).
- Negative values — invert the curve.

For richer curves, use a **Bezier track** instead — it gives you Bezier handles like a graph editor.

---

## 7. Loop Modes

Top-right of the timeline, the loop button cycles through:

- **None** — plays once, stops at the end.
- **Linear** — loops from end back to start.
- **PingPong** — plays forward, then backward, repeating.

Loop mode is a property of the animation itself, not the player.

---

## 8. The RESET Animation

Convention: a special animation named `RESET` that contains a single keyframe per track at t=0, capturing the **default pose** of all animated properties.

Godot uses `RESET`:

- To restore defaults when the editor isn't playing animations.
- As a fallback when the AnimationPlayer is reset programmatically.
- For ImportAnimations on glTF/FBX imports.

**Build it manually:**
1. Create animation named `RESET`.
2. Set all your tracks' properties to their default state in the scene.
3. For each track, right-click t=0 → **Insert Key**.

---

## 9. Code Playback

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    anim.play("idle")

func attack() -> void:
    anim.play("attack")
    await anim.animation_finished     # signal-based wait
    anim.play("idle")
```

### Common methods

| Method | What it does |
|---|---|
| `play(name, custom_blend=-1, custom_speed=1.0, from_end=false)` | Start an animation. `custom_blend` overrides default blend time. |
| `play_backwards(name, custom_blend=-1)` | Play in reverse from the end. |
| `stop(keep_state=false)` | Stop. With `keep_state=true`, the last value sticks; otherwise it falls back to RESET. |
| `pause()` | Freeze at current position without resetting. |
| `queue(name)` | Play after the current animation finishes. |
| `seek(time, update=false)` | Jump to a specific time. |
| `clear_queue()` | Drop queued animations. |
| `has_animation(name)` | Check if an animation exists. |

### Useful properties

| Property | Notes |
|---|---|
| `current_animation` | Read or assign — assigning starts playback. |
| `current_animation_position` | Time in seconds within the current animation. |
| `current_animation_length` | Total length of the playing animation. |
| `speed_scale` | Multiplier on playback speed (negative reverses). |
| `assigned_animation` | The currently *staged* animation (may not be playing). |
| `playback_default_blend_time` | Cross-fade duration when switching animations. |
| `playback_active` | True if playing. |

### Signals

- `animation_started(anim_name)`
- `animation_finished(anim_name)`
- `animation_changed(old_name, new_name)`
- `current_animation_changed(name)`

### Blending between animations

If `playback_default_blend_time > 0`, `play("new")` cross-fades from the current animation to the new one over that duration. Useful for character locomotion (walk → run blend).

You can also set per-pair blend times in the AnimationPlayer's **Playback Options** → **Blend Times**.

---

## 10. Method Call Tracks

Method tracks invoke a function on a node at a specific time.

1. Add a track → **Call Method Track**.
2. Pick the target node.
3. Right-click the timeline → **Insert Key** → pick a method from the node's script.

**Use for:**
- Triggering hit-detection at the impact frame of an attack.
- Spawning particles at a specific moment.
- Playing audio one-shots (though Audio Playback Tracks are usually cleaner).
- Emitting custom signals during a cutscene.

**Caution:** Method tracks tightly couple animations to script API. If you rename a method, the track silently breaks. Prefer signals or audio tracks where possible.

---

## 11. Audio Playback Tracks

1. Add an `AudioStreamPlayer` / `AudioStreamPlayer2D` / `AudioStreamPlayer3D` node.
2. Add an **Audio Playback Track**, target that node.
3. Drag audio clips onto the timeline at the moment they should play.

You can stretch the clip rectangle to control where playback starts and stops.

---

## 12. Practical Examples

### Fading a UI element in

```gdscript
# RESET animation: modulate.a = 0
# fade_in animation: modulate.a goes 0 → 1 over 0.3s with cubic interpolation

$AnimationPlayer.play("fade_in")
```

### Character attack with hit window

```
attack animation timeline:

  0.00s -- pose: windup
  0.15s -- pose: strike
  0.18s -- method call: deal_damage()
  0.30s -- pose: recovery
  0.45s -- (end)
```

```gdscript
func _on_attack_pressed() -> void:
    if anim.current_animation != "attack":
        anim.play("attack")
        await anim.animation_finished
        anim.play("idle")
```

### Looping idle with breathing

Create `idle` animation, length 2.0s, loop = Linear:
- Track: `Sprite2D:position:y` keyframes at 0.0s = 0, 1.0s = -2, 2.0s = 0
- Interpolation: Cubic

Set `playback_default_blend_time = 0.2` so transitions in/out of idle look smooth.

---

## 13. AnimationTree Handoff

When you need state machines, blend trees, or 1D/2D blending of multiple animations, add an `AnimationTree` node and point its `anim_player` property at this `AnimationPlayer`. The tree consumes the player's animations as raw clips and exposes a richer playback graph.

From that point on, **don't call `.play()` directly** — drive the tree's parameters instead:

```gdscript
$AnimationTree["parameters/playback"].travel("attack")
$AnimationTree.set("parameters/locomotion/blend_position", input_dir)
```

---

## 14. Tips & Common Pitfalls

- **Property paths are strings.** If you rename a node, animations targeting it silently break. The bottom panel shows broken tracks in red.
- **Auto-keyframe is dangerous.** Leave it off unless you're actively recording.
- **Animations override property values.** While an animation is playing, you usually can't change the animated property from code — the player will overwrite you every frame.
- **Use `Discrete` update mode** for things like sprite frame indexes — `Continuous` interpolation on an integer frame looks ugly.
- **`RESET` is your friend.** Without one, stopping animations leaves properties at their last interpolated value.
- **Animations don't run while paused.** They respect `Node.process_mode`. Set the AnimationPlayer to `PROCESS_MODE_ALWAYS` for UI animations that should play during pause menus.
- **Editor preview shows the current animation.** Disable the preview (eye icon) before saving the scene so you don't accidentally commit a "mid-animation" pose as the scene's default state.

---

## 15. Quick Reference Card

| Goal | Action |
|---|---|
| Animate a property | Select node, change value, click 🔑 next to property. |
| Save animation for reuse | Wrench icon → Manage Animation Libraries → save as `.tres`. |
| Wait for animation in code | `await anim.animation_finished` |
| Cross-fade between two animations | Set `playback_default_blend_time` and call `play()`. |
| Restore defaults | Create `RESET` animation with keys at t=0. |
| Call function during animation | Add Method Call Track. |
| Loop animation | Loop button (top-right of timeline) → Linear. |
| Branch/blend animations | Add AnimationTree, drive its parameters. |

---

*End of guide.*
