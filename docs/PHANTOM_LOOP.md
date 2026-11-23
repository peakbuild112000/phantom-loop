# PHANTOM LOOP - design doc

**Demo:** <https://peakbuild112000.github.io/phantom-loop/>  
**Repository:** <https://github.com/peakbuild112000/phantom-loop>

## Concept

A time-loop escape room with a robot-shell lore. You are a pilot transferring
between bodies in a derelict facility. Every abandoned shell replays its last
route and then freezes, so puzzles ask you to cooperate with your own past
bodies instead of waiting for a timer.

* **Target time:** 50 hours (PHANTOM goal: 50 fragments-hours).
* **Engine:** Godot 4.6.1 stable, GL Compatibility renderer.
* **Platforms:** desktop + WebGL2 (Godot `Web` export).
* **Players:** 1 (co-op is a stretch goal).

## Loop

1. A fresh shell boots at the entry point with 30 seconds of power.
2. Drive it onto a plate and press `E` to dock, or press `Enter` / the skip
   button to transfer early. Timer expiry forces a transfer too.
3. The abandoned shell becomes a ghost that replays its route and freezes at
   the end, keeping its plate held.
4. Stack up to **3** parked shells (`MAX_GHOSTS`) until every condition is true.
   Beyond that, transfers still reset the timer but create no new ghost.
5. Walk the current shell through the door and move to the next room.

## Simulation rules

* Fixed 60 Hz tick with an accumulator and a maximum of 5 substeps per frame.
* Snapshot = `{ position: Vector3, action: bool }` per tick.
* Replay by snapshot instead of input: deterministic on WebGL, with no reliance
  on physics for playback.
* Ghosts are kinematic `CharacterBody3D` nodes on layer 2 with mask 0: plates
  detect them, but they never push the player. When their cursor reaches the end
  of the recording it clamps to the last frame, so they stay parked on their plate.
* Plate activation uses a direct XZ distance check (`_touches_plate`) instead of
  `Area3D.get_overlapping_bodies()`. The tall trigger shape was also increased to
  2 m. Overlaps were one physics frame late / too flat, so held plates sometimes
  never lit up. The check is now identical on desktop and Web.
* Docking (`E` on a plate), `Enter`, the skip button and timer expiry all call
  the same `finish_loop()` transfer path.
* Room reset: original positions, timer, plate state, door collision, and player
  yaw forced to 0 so the new shell always faces the room instead of a wall.
* Once all plates are active, the door is **latched open** until the next loop.
  Without this, the player had to leave the last plate to reach the door, which
  closed it again and made the third loop look empty.
* Mouse look: yaw rotates the player, pitch rotates the camera, clamped to
  +/-1.2 rad so the view cannot flip.

## MVP rooms

| # | Name | Mechanic | Ghosts needed |
|---|------|----------|---------------|
| 1 | **Antechamber** | 3 plates active at once | 2 |
| 2 | **Corridor** | plate + door that closes after 2 s | 2 |
| 3 | **Balance** | carry a key onto a plate while another holds a lever | 3 |
| 4 | **Exit** | combination of the previous three | 3+ |

## Architecture (target)

```
scenes/
  main.tscn          # root, phantom_loop.gd (prototype)
  rooms/room_*.tscn  # future rooms
scripts/
  phantom_loop.gd    # loop, recording, replay, reset
  ghost.gd           # spectral rendering, afterimages
  puzzle/*.gd        # plates, doors, levers, beams
shaders/
  ghost.gdshader
tests/
  loop_test.gd       # verifies one recording = one replayed ghost
```

## Planned robot classes (future levels)

The lore is meant to grow into a class system. Every shell type gets one
distinct ability so later rooms require combining them.

| Shell | Ability | Puzzle use |
|-------|---------|------------|
| **Anchor** (current one) | Heavy, can dock on a plate with `E` | Holds switches in place |
| **Magnet** | Pulls nearby metal props toward itself | Bridges gaps, drags keys |
| **Spark** | Short burst that stuns drones / lights terminals | Disables hazards, remote panels |
| **Mimer** | Copies the last route of the previously parked shell | Repeats a timed path without you |
| **Phase** | Walks through one thin wall per level | Reaches isolated switch rooms |

Implementation hint: add a `ShellClass` enum to the recording snapshot next to
`pos` and `action`; replay code then dispatches to the matching ability instead
of only moving the ghost.

## 50-hour plan

| Block | Hours | Content |
|-------|-------|---------|
| Loop + ghost prototype | 8 | snapshot, replay, reset, HUD |
| Rooms 1-4 | 12 | mechanics, level design, visual cues |
| Polish | 10 | shaders, audio, feedback, animation |
| Web co-op | 12 | signaling, ghost sync, lobby |
| Tests + submission | 8 | Godot tests, Web export, README, demo video |

## Stretch goals

- Seeded room generator with shareable seeds.
- "Fewest loops" leaderboard stored in `user://`.
- Corrupted ghosts: one ghost in N replays a slightly different action.
- Soundtrack that distorts with every loop (pitch + reverb).
- Co-op mode: every player sees everyone else's ghosts.
