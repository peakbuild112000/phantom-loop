# PHANTOM LOOP - design doc

**Demo:** <https://peakbuild112000.github.io/phantom-loop/>  
**Repository:** <https://github.com/peakbuild112000/phantom-loop>

## Concept

A time-loop escape room. Every attempt is recorded and replayed by a ghost.
Puzzles need several simultaneous actions, so the player has to cooperate with
copies of themselves.

* **Target time:** 50 hours (PHANTOM goal: 50 fragments-hours).
* **Engine:** Godot 4.6.1 stable, GL Compatibility renderer.
* **Platforms:** desktop + WebGL2 (Godot `Web` export).
* **Players:** 1 (co-op is a stretch goal).

## Loop

1. Enter a room, 30-second timer starts.
2. Observe the plates and mechanisms.
3. Solve part of the puzzle, fail, or let the timer expire.
4. The attempt becomes a ghost that replays on every later loop.
5. Stack ghosts until every condition is true at the same time.
6. Move on to the next room.

## Simulation rules

* Fixed 60 Hz tick with an accumulator and a maximum of 5 substeps per frame.
* Snapshot = `{ position: Vector3, action: bool }` per tick.
* Replay by snapshot instead of input: deterministic on WebGL, with no reliance
  on physics for playback.
* Ghosts are kinematic `CharacterBody3D` nodes: they trigger logical `Area3D`
  nodes but do not push the player.
* Room reset: original positions, timer, plate state, door collision.
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
