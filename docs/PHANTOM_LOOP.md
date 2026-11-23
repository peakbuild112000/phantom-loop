# PHANTOM LOOP - design doc

**Demo:** <https://peakbuild112000.github.io/phantom-loop/>  
**Repository:** <https://github.com/peakbuild112000/phantom-loop>

## Concept

A time-loop escape room with a robot-shell lore. You are a pilot transferring
between bodies in a derelict facility. Every abandoned shell replays its last
route and then freezes, so puzzles ask you to cooperate with your own past
bodies. Four sectors introduce four robot classes with distinct abilities.

* **Target time:** 50 hours (PHANTOM goal: 50 fragments-hours).
* **Engine:** Godot 4.6.1 stable, GL Compatibility renderer.
* **Platforms:** desktop + WebGL2 (Godot `Web` export).
* **Players:** 1 (co-op is a stretch goal).

## Loop

1. A fresh shell boots at the entry point, facing the room (never a wall).
2. Drive it where you need it, then press `E` / `Enter` or the skip button to
   transfer. There is **no timer**: a transfer only happens when you choose it.
3. The abandoned shell becomes a ghost that replays its route and freezes at
   the end, keeping its plate held.
4. You have **3 copies** (`MAX_GHOSTS`). A fourth transfer is a **game over**
   with a red flash and a `GAME OVER` screen; `R` restarts the run.
5. Walk the current shell through the door. It closes behind you and the next
   sector loads automatically after a short flash transition.

## Simulation rules

* Fixed 60 Hz tick with an accumulator and a maximum of 5 substeps per frame.
* Snapshot = `{ position: Vector3, class: int }` per tick - no input or action
  flag is needed any more, because plates are automatic.
* Replay by snapshot instead of input: deterministic on WebGL, with no reliance
  on physics for playback. When the cursor reaches the end it clamps to the last
  frame, so the shell parks where it stopped.
* Ghosts are kinematic `CharacterBody3D` nodes on layer 2 with mask 0: they can
  never push the player. Plates are evaluated with a direct XZ distance check,
  so there is no physics-frame lag or missed trigger volume.
* Plate rules: `ANY` accepts every class; a class id accepts only that class;
  `KEY` accepts only the gold core when it is close enough.
* Every transfer path (`E`, `Enter`, button) calls the same `_finish_loop()`,
  which checks the copy budget first and switches to the game-over state when
  it is exhausted.
* Room reset: original positions, stopwatch, plate colour, key position, door
  collision, player yaw and drag state.
* Once all plates are active, the door is **latched open** until the player
  crosses it. Crossing re-enables the collision, slides the door shut and starts
  a 0.45 s transition that loads the next sector automatically.
* Mouse look: yaw rotates the player, pitch rotates the camera, clamped to
  +/-1.2 rad so the view cannot flip. On Web, click-drag replaces pointer lock
  so the HUD buttons stay clickable. `_apply_mouse_mode()` runs on boot, on every
  room reset and after every level load: the pointer is never released by a door
  crossing, and Web drag-look is restored from the real button state.

## Sectors

| # | Name | Mechanic | Ghosts needed |
|---|------|----------|---------------|
| 1 | **Antechamber** | 3 automatic plates | 2 |
| 2 | **Heavy Foundry** | Anchor-only plate behind a wall | 2 |
| 3 | **Magnet Bay** | Pull the gold core onto a dark pad | 2 + magnet |
| 4 | **Phase Vault** | Phase wall + Spark remote pad | 2 + phase/spark |

Sector data lives in `scripts/level_data.gd`; adding a sector is one dictionary.

## Robot classes

Selectable at any time with `1`-`4` or the HUD buttons. The choice is stored in
the snapshot, so a parked shell keeps its class and its ability keeps working.

| Key | Class | Ability | Puzzle use |
|-----|-------|---------|------------|
| `1` | **Anchor** | Heavy frame | Only class that can press red heavy plates |
| `2` | **Magnet** | Pulls the gold core within 6 m | Moves the core onto a plate from a distance |
| `3` | **Spark** | Lights remote pads within 3.6 m | Activates pads you cannot stand on |
| `4` | **Phase** | Ignores phase walls (collision mask 1) | Reaches isolated rooms behind thin walls |

Future class ideas: **Drone** (flies over gaps), **Echo** (copies the previous
shell's route) and **Weld** (temporarily bridges a gap).

## Architecture

```
scenes/
  main.tscn            # root, phantom_loop.gd
scripts/
  phantom_loop.gd      # sectors, loop, ghosts, plates, HUD
  level_data.gd        # 4 sector dictionaries
  robot_shell.gd       # procedural 3D model + class colours
shaders/
  ghost.gdshader       # translucent spectral material
tests/
  smoke_test.gd        # headless checks for plates, ghosts, classes
```

All robot, plate, door and key models are generated from meshes in code, so the
project has no external asset dependency. Animation is also procedural: viewmodel
bob/sway with per-class tools, ghost walk cycles driven by recorded speed,
breathing plates, a spinning key, a sliding door and a class-coloured transfer
flash. The old bar connecting the two viewmodel hands was removed - each hand is
now an independent forearm + fist.

## 50-hour plan

| Block | Hours | Content |
|-------|-------|---------|
| Loop + ghost prototype | 8 | snapshot, replay, reset, HUD |
| Sectors 1-4 + classes | 12 | mechanics, level design, 3D models |
| Polish | 10 | shaders, audio, feedback, animation |
| Web co-op | 12 | signaling, ghost sync, lobby |
| Tests + submission | 8 | Godot tests, Web export, README, demo video |

## Stretch goals

- Animated walk cycle for the shells instead of static meshes.
- Seeded room generator with shareable seeds.
- "Fewest shells" leaderboard stored in `user://`.
- Corrupted ghosts: one ghost in N replays a slightly different route.
- Soundtrack that distorts with every transfer (pitch + reverb).
- Co-op mode: every player sees everyone else's ghosts.
