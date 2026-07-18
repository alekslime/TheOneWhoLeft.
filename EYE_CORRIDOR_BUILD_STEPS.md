# Eye Corridor — Build Steps (Godot 4.x)

Two files are ready to drop into your project:
- `eye_wall.gdshader` → put in `res://shaders/`
- `eye_controller.gd` → put in `res://scripts/` (or a new `res://final_area/` folder)

## 1. Build the eye geometry

Don't sculpt full eyeballs. Use a **half-sphere** (`SphereMesh` with `radial_segments`
low, e.g. 12, and only render the top half — or just push a full low-poly sphere
half-buried into the corridor wall so only the "eye-facing" half shows).

For each eye:
1. Add a `MeshInstance3D`, mesh = `SphereMesh` (radius ~0.4–1.0 depending on scale,
   vary sizes per eye for the "countless eyes, different scales" look from your ref image).
2. Add a `ShaderMaterial` on surface 0, shader = `eye_wall.gdshader`.
3. UV1 on a SphereMesh already gives you a usable 0–1 equirect UV — that's what the
   shader's `world_uv` expects, so no unwrap work needed.
4. Push/rotate the sphere so it's half-embedded in the corridor wall mesh (like a
   half-buried ball), with the UV "front" facing into the corridor.

## 2. Wiring per-eye behavior (reuse your CandleTunnel pattern)

You already have exactly this structure in `CandleTunnel.tscn` — 24 numbered child
nodes, each with a trigger Area3D. Copy that pattern:

```
EyeCorridor (Node3D)
├── Eye1 (MeshInstance3D)  <- eye_controller.gd attached
│   └── EyeTrigger (Area3D, optional — only needed for scripted force-opens)
├── Eye2 ...
└── ...
```

Attach `eye_controller.gd` directly to each `MeshInstance3D`. It auto-finds the
player via `get_tree().get_root().find_child("Player", true, false)` — the same
lookup convention your `door_controller.gd` already uses for `_get_audio()`, so it's
consistent with the rest of your codebase. If you'd rather not do a tree search every
time, drag the Player node into the exported `player` field in the Inspector instead.

## 3. What it does automatically

- **Opening/closing**: each eye checks whether the player is facing *away* from it
  (i.e., facing further down the corridor, toward the door) — if so, it opens.
  This is the inversion from your design doc: looking toward the goal is what
  wakes the horror, not looking away.
- **Pupil tracking**: the pupil offsets toward the player's position in the eye's
  local space, clamped so it doesn't clip outside the iris.
- **Stress/bloodshot veins**: not automatic — call `eye.set_stress(value)` from
  wherever you're tracking hesitation/backtracking (e.g. from `level_manager.gd`,
  incrementing a value each time the player reverses direction, then decaying it
  over time).
- **Scripted overrides**: call `eye.force_open()` / `eye.force_closed()` from a
  trigger area for any beat you want to script by hand rather than leave reactive
  (e.g. the final approach to the door, where you said the door should stop
  changing — you'd force every eye in view fully open at that point for the
  "horrifying stillness").

## 4. Lighting (per your design: "only one light source, the door")

- Remove/hide any fill lights in this corridor in the editor.
- Put a single warm `OmniLight3D` or `SpotLight3D` at the door, moderate range,
  soft falloff.
- Optionally add a very dim, cold rim light near the camera (low energy, blue-ish)
  just so the eyes aren't pure silhouettes — real horror games do this to keep
  detail readable without breaking the "only one true light source" rule.

## 5. Performance note

If you end up with 40+ eyes, don't put a script + ShaderMaterial on every single
instance — that's 40 separate `_process` calls and 40 draw calls. Options if it
gets heavy:
- Use `MultiMeshInstance3D` for the far-background eyes (dumb, non-reactive,
  just animate open_amount via a shared time-based uniform for ambient "blinking").
- Reserve the scripted, tracking `eye_controller.gd` version for the ~6–10 eyes
  closest to the camera / most visually prominent, where the reactive behavior
  actually gets noticed.
