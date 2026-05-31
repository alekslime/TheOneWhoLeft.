# Gods Blood

A first-person horror shooter built in **Godot 4.6** using GDScript.

You return home from war to find your wife and daughter slaughtered — victims of a cult serving a dying god that feeds on human flesh and souls to sustain itself. What starts as grief becomes a blood-soaked hunt through cursed forests, candlelit tunnels, and corrupted sanctuaries as you tear through the believers standing between you and the thing that took everything from you.

Gods Blood is a game about rage. The world is gothic and brutal, the enemies are fanatical, and the only thing keeping you alive is the fury you can't let go of.

---

## Features

- **First-person shooter** with smooth movement: walk, sprint, slide, dash, jump, and ADS
- **Rage system** — fill your rage meter by killing enemies or taking damage, then activate it for a speed and damage boost
- **Nausea mechanic** — looking at gore builds a trauma meter, triggering visual distortion and voice cues
- **Multiple weapons**, each with unique stats, reload animations, and feel:
  - *Ashen Repeater* — fast hitscan rifle
  - *The Grief* — close-range shotgun with spread
  - *Remnant* — long-range precision weapon
  - *Hollow Round* — explosive projectile with implosion radius
- **Procedural weapon animations** — no external animation files; idle sway, sprint bob, fire kick, reload, and landing impact are all code-driven
- **Enemy roster**: Vicar (ranged), Echo, Ranged Enemy, Remnant Believer, The Bound, Demon, Fast Enemy
- **PSX / CRT visual shaders** for a retro horror aesthetic
- **Gore system** with decals
- **Dynamic music manager** and audio bus layout
- **Pause menu** and HUD with health, ammo, and rage display

---

## Requirements

- [Godot Engine 4.6](https://godotengine.org/) (Forward Plus renderer)
- **Jolt Physics** plugin (configured in project settings — bundled with Godot 4.3+)

---

## Getting Started

1. Clone or download this repository.
2. Open **Godot 4.6** and import the project by selecting the `project.godot` file.
3. The main entry scene is `scenes/player/test_level.tscn` — press **F5** or click **Run** to play.

---

## Controls

| Action | Input |
|---|---|
| Move | WASD |
| Sprint | Left Shift |
| Jump | Space |
| Slide | Left Ctrl |
| Dash | Left Alt |
| Fire | Left Mouse Button |
| Aim Down Sights | Right Mouse Button |
| Melee | F |
| Reload | R |
| Rage | G |
| Cycle Weapon | Q / E or Mouse Wheel |
| Weapon Slots | 1–4 |
| Restart | Enter |

---

## Project Structure

```
gods-blood/
├── enemies/          # Base enemy class and enemy variants (Echo, Bound, Ranged, etc.)
├── Enemies/          # Vicar boss enemy
├── door/             # Animatable door controller
├── grass/            # Grass material and textures
├── menus/            # Pause menu scene and script
├── music/            # Music manager (autoload)
├── pickupable/       # Health, ammo, and medkit pickups
├── scenes/
│   ├── player/       # Player controller, weapon holder, shaders, levels
│   ├── enemies/      # Demon and fast enemy scenes
│   ├── intro/        # Forest intro and Level 1
│   ├── ui/           # HUD, crosshair, stats screen
│   └── Level4.tscn   # Main combat level
├── scripts/          # Game manager, gore system, level manager (autoloads)
├── shaders/          # Death screen shader and overlay
├── ui/               # Rage bar assets
└── weapons/          # All weapon scripts and scenes
```

---

## Autoloads

| Singleton | Purpose |
|---|---|
| `GoreManager` | Tracks and spawns gore decals |
| `GameManager` | Global game state |
| `MusicManager` | Controls music playback across scenes |

---

## License

*No license specified — all rights reserved by the author.*
