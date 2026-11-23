# PHANTOM LOOP - design doc

**Demo:** <https://peakbuild112000.github.io/phantom-loop/>  
**Repository:** <https://github.com/peakbuild112000/phantom-loop>

## Concept

A time-loop escape room with a robot-shell lore. You are a pilot transferring
between bodies in a derelict facility. Every abandoned shell replays its last
route and then freezes, so puzzles ask you to cooperate with your own past
bodies. Eight sectors introduce four robot classes, jumping, and environmental
puzzles with precise class/terrain combinations.

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
   with a red flash and a `GAME OVER` screen; `R` repeats the same sector.
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
  never push the player. Plates use a direct XZ distance check plus a 1.4 m
  vertical tolerance, so elevated pads are real puzzles but need no trigger
  volume. There is no physics-frame lag or missed overlap.
* Gravity is 18 m/s² and `Space` sets an 8 m/s impulse only on a floor step.
  Footsteps are emitted every 1.7 m of horizontal travel, which keeps their
  rhythm identical on desktop and Web.
* Moving gates are `mover` dictionaries driven by `sin(_elapsed * speed + phase)`.
  Because `_elapsed` resets every loop, their timing is deterministic for ghosts.
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
| 5 | **Step Ladder** | Jump up two blue steps to a pad at y=2.6 | 2 + jump |
| 6 | **Grated Cell** | Spark through a cage grate; Phase through a full-width wall | 1 + spark + phase |
| 7 | **Magnet Ridge** | Jump to a high pad, then lead the core through a 2 m slit | 1 + jump + magnet |
| 8 | **Sweeping Gate** | Jump a 0.8 m bar, then time a rising 2.6 m gate | 2 + jump + timing |

Sector data lives in `scripts/level_data.gd`; adding a sector is one dictionary
with `walls`, `movers`, `plates` and an optional `key`.

## Audio and start menu

Sounds are short PCM buffers synthesised at runtime into `AudioStreamWAV`
(`_synth`), played by ten `AudioStreamPlayer` nodes: two alternating footsteps,
jump, land, plate, door, transfer, win, lose and UI. No external audio files are
shipped.

The menu is a `CanvasLayer` with a `GradientTexture2D` background over the live
3D room, a neon frame, the title, the control legend and a START button. `Enter`
or `Space` starts; finishing sector 8 returns to it with `RUN COMPLETE`.

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
  phantom_loop.gd      # sectors, loop, ghosts, plates, HUD, menu, audio
  level_data.gd        # 8 sector dictionaries
  robot_shell.gd       # procedural 3D model + class colours
shaders/
  ghost.gdshader       # translucent spectral material
tests/
  smoke_test.gd        # headless checks for plates, jump, audio, menu
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
| Sectors 5-8 + jump | 10 | elevation, timing gates, class/terrain puzzles |
| Polish | 8 | shaders, procedural audio, menu, feedback |
| Web co-op | 12 | signaling, ghost sync, lobby |
| Tests + submission | 8 | Godot tests, Web export, README, demo video |

## Stretch goals

- Animated walk cycle for the shells instead of static meshes.
- Seeded room generator with shareable seeds.
- "Fewest shells" leaderboard stored in `user://`.
- Corrupted ghosts: one ghost in N replays a slightly different route.
- Soundtrack that distorts with every transfer (pitch + reverb).
- Co-op mode: every player sees everyone else's ghosts.
