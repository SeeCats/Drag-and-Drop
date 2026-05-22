/*
 * Generates animation_player_guide.docx in this folder.
 * Run:
 *   cd docs
 *   npm install docx
 *   node make_animation_player_docx.js
 */

const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageOrientation, PageBreak,
} = require("docx");

// ---- Style helpers ----
const FONT = "Calibri";
const CODE_FONT = "Consolas";

const border = { style: BorderStyle.SINGLE, size: 1, color: "BBBBBB" };
const borders = { top: border, bottom: border, left: border, right: border };

const p = (text, opts = {}) =>
  new Paragraph({
    spacing: { after: 120 },
    ...opts,
    children: opts.children || [new TextRun({ text, font: FONT })],
  });

const h1 = (text) =>
  new Paragraph({ heading: HeadingLevel.HEADING_1, spacing: { before: 360, after: 200 },
    children: [new TextRun({ text, font: FONT, bold: true, size: 36 })] });

const h2 = (text) =>
  new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 280, after: 160 },
    children: [new TextRun({ text, font: FONT, bold: true, size: 28 })] });

const h3 = (text) =>
  new Paragraph({ heading: HeadingLevel.HEADING_3, spacing: { before: 220, after: 120 },
    children: [new TextRun({ text, font: FONT, bold: true, size: 24 })] });

const bullet = (text) =>
  new Paragraph({ numbering: { reference: "bullets", level: 0 },
    children: [new TextRun({ text, font: FONT })] });

const numbered = (text) =>
  new Paragraph({ numbering: { reference: "numbers", level: 0 },
    children: [new TextRun({ text, font: FONT })] });

const code = (text) => {
  // Multi-line code as a single shaded paragraph per line.
  const lines = text.replace(/\t/g, "    ").split("\n");
  return lines.map((line, i) =>
    new Paragraph({
      spacing: { after: i === lines.length - 1 ? 160 : 0, before: i === 0 ? 60 : 0 },
      shading: { type: ShadingType.CLEAR, fill: "F4F4F4" },
      children: [new TextRun({ text: line || " ", font: CODE_FONT, size: 20 })],
    })
  );
};

const inline = (text, opts = {}) => new TextRun({ text, font: FONT, ...opts });
const inlineCode = (text) => new TextRun({ text, font: CODE_FONT, size: 20, shading: { type: ShadingType.CLEAR, fill: "F0F0F0" } });

// ---- Tables ----
const COL_W = 9360; // US Letter content width @ 1" margins

function makeTable(headers, rows, widths) {
  const total = widths.reduce((a, b) => a + b, 0);
  const headRow = new TableRow({
    tableHeader: true,
    children: headers.map((h, i) =>
      new TableCell({
        borders,
        width: { size: widths[i], type: WidthType.DXA },
        shading: { type: ShadingType.CLEAR, fill: "D9E2F3" },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: h, font: FONT, bold: true })] })],
      })
    ),
  });
  const bodyRows = rows.map((r) =>
    new TableRow({
      children: r.map((cell, i) =>
        new TableCell({
          borders,
          width: { size: widths[i], type: WidthType.DXA },
          margins: { top: 80, bottom: 80, left: 120, right: 120 },
          children: [new Paragraph({ children: [new TextRun({ text: cell, font: FONT })] })],
        })
      ),
    })
  );
  return new Table({
    width: { size: total, type: WidthType.DXA },
    columnWidths: widths,
    rows: [headRow, ...bodyRows],
  });
}

// ---- Content ----
const children = [];

// Title
children.push(new Paragraph({
  alignment: AlignmentType.CENTER, spacing: { after: 200 },
  children: [new TextRun({ text: "Godot AnimationPlayer", font: FONT, bold: true, size: 56 })],
}));
children.push(new Paragraph({
  alignment: AlignmentType.CENTER, spacing: { after: 600 },
  children: [new TextRun({ text: "A Complete Tutorial", font: FONT, italics: true, size: 32, color: "555555" })],
}));

// 1
children.push(h1("1. What is AnimationPlayer?"));
children.push(p("AnimationPlayer is Godot's central node for timeline-based animation. It records property changes (and method calls, audio cues, and more) along a timeline and plays them back. It can animate any property of any node in the scene — positions, rotations, colors, shader parameters, custom script variables, even other animations."));
children.push(h3("When to use it"));
[
  "UI element animations (fade-ins, slide-ins, button hover effects).",
  "2D and 3D character motion (walk cycles, attacks, idle breathing).",
  "Cutscenes with synchronized audio, camera, and event callbacks.",
  "Property tweening that needs authored timing rather than procedural easing.",
].forEach(t => children.push(bullet(t)));
children.push(h3("When not to use it"));
[
  "One-shot procedural tweens — use Tween (created via create_tween()) instead.",
  "Pure frame-by-frame sprite animation — AnimatedSprite2D / AnimatedSprite3D are simpler.",
  "Complex state blending — use AnimationTree, which sits on top of an AnimationPlayer.",
].forEach(t => children.push(bullet(t)));

// 2
children.push(h1("2. Adding AnimationPlayer to a Scene"));
[
  "Select the parent node that owns the animation (e.g. your character root).",
  "Click + Add Child Node and search “AnimationPlayer”.",
  "Select the new AnimationPlayer node — the Animation Panel appears at the bottom of the editor.",
].forEach(t => children.push(numbered(t)));
children.push(p("The bottom panel is your animation editor: animation dropdown on the left, timeline in the middle, track list below."));

// 3
children.push(h1("3. Animation Storage"));
children.push(p("Each animation is a Resource (.tres or built-in). You can embed animations in the scene file (default) or save them to an external library so multiple scenes can share them. Click the wrench icon and choose Manage Animation Libraries to save."));
children.push(p("Animation libraries are first-class in Godot 4 — you can load a library at runtime:"));
children.push(...code(`AnimationPlayer.add_animation_library(name, library)`));

// 4
children.push(h1("4. Creating an Animation"));
[
  "In the Animation Panel, click Animation → New.",
  "Name it (e.g. idle, attack, fade_in).",
  "Set its length in seconds (top-right of the timeline).",
  "Set its step (e.g. 0.1s) — keyframes snap to this grid.",
].forEach(t => children.push(numbered(t)));
children.push(p("The very first animation should typically be called RESET — Godot uses it to restore default property values when animations are interrupted or the scene loads."));

// 5
children.push(h1("5. Tracks"));
children.push(p("A track is a single channel of animation — one property or one event over time. Add tracks with the + Add Track button."));
children.push(h3("Track types"));
children.push(makeTable(
  ["Track", "Purpose"],
  [
    ["Property Track", "Animate any property on any node (position, modulate, custom script vars)."],
    ["3D Position / Rotation / Scale", "Optimized 3D transform tracks."],
    ["Blend Shape", "Animate mesh blend shape weights."],
    ["Method Call", "Call a function on a node at a given time."],
    ["Bezier", "Animate a numeric property with full bezier curve control."],
    ["Audio Playback", "Trigger audio clips on an AudioStreamPlayer* node."],
    ["Animation Track", "Play another animation inside this one."],
  ],
  [3120, 6240]
));
children.push(h3("Adding a property track quickly"));
[
  "Click the key icon next to a property in the Inspector while the AnimationPlayer is selected.",
  "Godot creates the track and inserts a keyframe automatically.",
].forEach(t => children.push(bullet(t)));
children.push(h3("Autokey toggle"));
children.push(p("The red record button at the top of the timeline enables autokey: any property change you make while it's on creates a keyframe automatically. Turn it off when you're done iterating so you don't pollute the animation."));

// 6
children.push(h1("6. Keyframes"));
children.push(p("A keyframe stores a value at a moment in time. The animation interpolates between consecutive keyframes."));
children.push(h3("Adding a keyframe"));
[
  "Inspector route: change a property, click the key icon next to it.",
  "Track route: right-click the timeline at the desired second → Insert Key.",
  "Autokey route: as above.",
].forEach(t => children.push(bullet(t)));
children.push(h3("Editing keyframes"));
[
  "Click a keyframe to select it — the Inspector shows its Time, Value, and Easing.",
  "Drag keyframes horizontally to retime them.",
  "Right-click for cut, copy, paste, duplicate, or delete.",
].forEach(t => children.push(bullet(t)));
children.push(h3("Interpolation modes (per track)"));
children.push(makeTable(
  ["Mode", "Behavior"],
  [
    ["Nearest", "Step. No interpolation. Good for sprite frame swaps."],
    ["Linear", "Straight-line interpolation."],
    ["Cubic", "Smooth curves."],
    ["Linear Angle / Cubic Angle", "Wraps around at 360° for rotations."],
  ],
  [3120, 6240]
));
children.push(h3("Update modes (per track)"));
children.push(makeTable(
  ["Mode", "Behavior"],
  [
    ["Continuous", "Value updates every frame (default)."],
    ["Discrete", "Value only applied at keyframe times."],
    ["Capture", "Captures the property's current value at the start, interpolates to the first keyframe."],
  ],
  [3120, 6240]
));
children.push(h3("Easing"));
children.push(p("The easing value on a keyframe shapes the curve approaching that key:"));
[
  "1.0 → linear.",
  "> 1.0 → ease-in (slow start, fast end).",
  "< 1.0 → ease-out (fast start, slow end).",
  "Negative values invert the curve.",
].forEach(t => children.push(bullet(t)));
children.push(p("For richer curves, use a Bezier track instead — it gives you Bezier handles like a graph editor."));

// 7
children.push(h1("7. Loop Modes"));
children.push(p("Top-right of the timeline, the loop button cycles through:"));
[
  "None — plays once, stops at the end.",
  "Linear — loops from end back to start.",
  "PingPong — plays forward, then backward, repeating.",
].forEach(t => children.push(bullet(t)));
children.push(p("Loop mode is a property of the animation itself, not the player."));

// 8
children.push(h1("8. The RESET Animation"));
children.push(p("Convention: a special animation named RESET that contains a single keyframe per track at t=0, capturing the default pose of all animated properties."));
children.push(p("Godot uses RESET to restore defaults when the editor isn't playing animations, as a fallback when the player is reset programmatically, and for import animations on glTF/FBX imports."));
children.push(h3("Build it manually"));
[
  "Create animation named RESET.",
  "Set all your tracks' properties to their default state in the scene.",
  "For each track, right-click t=0 → Insert Key.",
].forEach(t => children.push(numbered(t)));

// 9
children.push(h1("9. Code Playback"));
children.push(...code(`@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    anim.play("idle")

func attack() -> void:
    anim.play("attack")
    await anim.animation_finished
    anim.play("idle")`));
children.push(h3("Common methods"));
children.push(makeTable(
  ["Method", "Description"],
  [
    ["play(name, custom_blend, custom_speed, from_end)", "Start an animation."],
    ["play_backwards(name, custom_blend)", "Play in reverse from the end."],
    ["stop(keep_state)", "Stop. keep_state=true holds the last value."],
    ["pause()", "Freeze without resetting."],
    ["queue(name)", "Play after the current animation finishes."],
    ["seek(time, update)", "Jump to a specific time."],
    ["clear_queue()", "Drop queued animations."],
    ["has_animation(name)", "Check if an animation exists."],
  ],
  [4500, 4860]
));
children.push(h3("Useful properties"));
children.push(makeTable(
  ["Property", "Notes"],
  [
    ["current_animation", "Read or assign — assigning starts playback."],
    ["current_animation_position", "Time in seconds within the current animation."],
    ["current_animation_length", "Total length of the playing animation."],
    ["speed_scale", "Multiplier on playback speed (negative reverses)."],
    ["assigned_animation", "The currently staged animation (may not be playing)."],
    ["playback_default_blend_time", "Cross-fade duration when switching animations."],
    ["playback_active", "True if playing."],
  ],
  [3600, 5760]
));
children.push(h3("Signals"));
[
  "animation_started(anim_name)",
  "animation_finished(anim_name)",
  "animation_changed(old_name, new_name)",
  "current_animation_changed(name)",
].forEach(t => children.push(bullet(t)));
children.push(h3("Blending between animations"));
children.push(p("If playback_default_blend_time > 0, play(\"new\") cross-fades from the current animation to the new one over that duration. You can also set per-pair blend times in the AnimationPlayer's Playback Options → Blend Times."));

// 10
children.push(h1("10. Method Call Tracks"));
children.push(p("Method tracks invoke a function on a node at a specific time."));
[
  "Add a track → Call Method Track.",
  "Pick the target node.",
  "Right-click the timeline → Insert Key → pick a method from the node's script.",
].forEach(t => children.push(numbered(t)));
children.push(h3("Good uses"));
[
  "Triggering hit detection at the impact frame of an attack.",
  "Spawning particles at a specific moment.",
  "Playing audio one-shots (Audio Playback Tracks are usually cleaner).",
  "Emitting custom signals during a cutscene.",
].forEach(t => children.push(bullet(t)));
children.push(p("Caution: method tracks tightly couple animations to script API. Renaming a method silently breaks the track. Prefer signals or audio tracks where possible."));

// 11
children.push(h1("11. Audio Playback Tracks"));
[
  "Add an AudioStreamPlayer / AudioStreamPlayer2D / AudioStreamPlayer3D node.",
  "Add an Audio Playback Track, target that node.",
  "Drag audio clips onto the timeline at the moment they should play.",
].forEach(t => children.push(numbered(t)));
children.push(p("You can stretch the clip rectangle to control where playback starts and stops."));

// 12
children.push(h1("12. Practical Examples"));
children.push(h2("Fading a UI element in"));
children.push(p("RESET animation: modulate.a = 0. fade_in animation: modulate.a goes 0 → 1 over 0.3s with cubic interpolation."));
children.push(...code(`$AnimationPlayer.play("fade_in")`));
children.push(h2("Character attack with hit window"));
children.push(p("Attack animation timeline:"));
[
  "0.00s — pose: windup",
  "0.15s — pose: strike",
  "0.18s — method call: deal_damage()",
  "0.30s — pose: recovery",
  "0.45s — end",
].forEach(t => children.push(bullet(t)));
children.push(...code(`func _on_attack_pressed() -> void:
    if anim.current_animation != "attack":
        anim.play("attack")
        await anim.animation_finished
        anim.play("idle")`));
children.push(h2("Looping idle with breathing"));
children.push(p("Create idle animation, length 2.0s, loop = Linear:"));
[
  "Track: Sprite2D:position:y with keyframes at 0.0s = 0, 1.0s = -2, 2.0s = 0.",
  "Interpolation: Cubic.",
  "Set playback_default_blend_time = 0.2 so transitions in/out of idle look smooth.",
].forEach(t => children.push(bullet(t)));

// 13
children.push(h1("13. AnimationTree Handoff"));
children.push(p("When you need state machines, blend trees, or 1D/2D blending of multiple animations, add an AnimationTree node and point its anim_player property at this AnimationPlayer. The tree consumes the player's animations as raw clips and exposes a richer playback graph."));
children.push(p("From that point on, don't call .play() directly — drive the tree's parameters:"));
children.push(...code(`$AnimationTree["parameters/playback"].travel("attack")
$AnimationTree.set("parameters/locomotion/blend_position", input_dir)`));

// 14
children.push(h1("14. Tips & Common Pitfalls"));
[
  "Property paths are strings. Renaming a node silently breaks animations that target it — broken tracks show in red in the bottom panel.",
  "Auto-keyframe is dangerous. Leave it off unless you're actively recording.",
  "Animations override property values. While an animation plays, you usually can't change the animated property from code — the player will overwrite you every frame.",
  "Use Discrete update mode for things like sprite frame indexes — Continuous interpolation on an integer frame looks ugly.",
  "RESET is your friend. Without one, stopping animations leaves properties at their last interpolated value.",
  "Animations don't run while paused. They respect Node.process_mode. Set PROCESS_MODE_ALWAYS for UI animations that should play during pause menus.",
  "Editor preview shows the current animation. Disable the preview (eye icon) before saving the scene so you don't accidentally commit a mid-animation pose as the scene's default state.",
].forEach(t => children.push(bullet(t)));

// 15
children.push(h1("15. Quick Reference Card"));
children.push(makeTable(
  ["Goal", "Action"],
  [
    ["Animate a property", "Select node, change value, click key icon next to the property."],
    ["Save animation for reuse", "Wrench icon → Manage Animation Libraries → save as .tres."],
    ["Wait for animation in code", "await anim.animation_finished"],
    ["Cross-fade between two animations", "Set playback_default_blend_time and call play()."],
    ["Restore defaults", "Create RESET animation with keys at t=0."],
    ["Call function during animation", "Add Method Call Track."],
    ["Loop animation", "Loop button (top-right of timeline) → Linear."],
    ["Branch / blend animations", "Add AnimationTree, drive its parameters."],
  ],
  [3600, 5760]
));

// ---- Build doc ----
const doc = new Document({
  creator: "Claude",
  title: "Godot AnimationPlayer Tutorial",
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: FONT, color: "1F3864" },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: FONT, color: "2E75B6" },
        paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: FONT, color: "404040" },
        paragraph: { spacing: { before: 220, after: 120 }, outlineLevel: 2 } },
    ],
  },
  numbering: {
    config: [
      { reference: "bullets",
        levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers",
        levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ],
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      },
    },
    children,
  }],
});

Packer.toBuffer(doc).then(buf => {
  const out = path.join(__dirname, "animation_player_guide.docx");
  fs.writeFileSync(out, buf);
  console.log("Wrote " + out);
});
