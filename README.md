# PHANTOM LOOP 👻

**Demo:** <https://peakbuild112000.github.io/phantom-loop/>  
**Repository:** <https://github.com/peakbuild112000/phantom-loop>  
**Engine:** Godot 4.6.1 stable

A time-loop escape room built for **PHANTOM**, the Hack Club hackathon. You are
a pilot jumping between 3D robot shells. Every shell you abandon stays behind
and keeps holding its position, so you can cooperate with your own past bodies.
Four sectors, four robot classes, each with its own ability.

## Contents

- [Demo](#demo)
- [How to play](#how-to-play)
- [Robot classes](#robot-classes)
- [Sectors](#sectors)
- [Controls](#controls)
- [Run from source](#run-from-source)
- [Web export](#web-export)
- [CI / deployment](#ci--deployment)
- [Project layout](#project-layout)
- [Hackatime](#hackatime)
- [License](#license)

## Demo

Play it in the browser:

<https://peakbuild112000.github.io/phantom-loop/>

Recommended browser: a recent Chrome, Edge, Firefox or Safari with WebGL2
enabled. On Web, **hold the left mouse button and drag** to look around; this
keeps the buttons clickable.

Source code:

<https://github.com/peakbuild112000/phantom-loop>

## How to play

You are not the robot: you are the **pilot** of a fleet of shells in a derelict
facility. Stand on all the glowing plates at the same time to open the door.

* Plates are **automatic**: any shell standing on one lights it. No button needed.
* `E`, `Enter` or the `SKIP / TRANSFER BODY` button transfers you into a fresh
  shell at the entry point. **There is no timer** - nothing transfers you unless
  you decide to. The HUD shows a stopwatch.
* A parked shell replays its last route and then **freezes**, so it keeps
  holding its plate forever instead of walking away.
* You have only **3 copies** per sector. Using a fourth transfer is a **game
  over**; press `R` to restart the run. The HUD shows how many copies remain.
* Every new shell spawns facing the room. Once all plates are lit, the door
  stays open while you walk through it. Crossing it closes the door and loads
  the next sector automatically.

## Robot classes

Press `1`-`4` or click a class button at any time to change the shell you are
piloting. Parked shells keep the class they had when transferred.

| Key | Class | Ability |
| --- | --- | --- |
| `1` | **Anchor** | Heavy frame: the only class that can hold red heavy plates |
| `2` | **Magnet** | Pulls the gold core within 6 m onto its target pad |
| `3` | **Spark** | Lights yellow remote pads from up to 3.6 m away |
| `4` | **Phase** | Walks through thin purple phase walls |

## Sectors

| # | Name | Mechanic |
|---|------|----------|
| 1 | **Antechamber** | Automatic plates, parking basics |
| 2 | **Heavy Foundry** | Anchor-only plate behind a wall |
| 3 | **Magnet Bay** | Pull the gold core onto a dark pad |
| 4 | **Phase Vault** | Phase wall plus a Spark remote pad |

Everything is animated procedurally: the hands bob and sway with movement
(each class has its own tool instead of a bar between them), parked shells walk
in place, plates pulse, the door slides into the floor and transfers flash the
screen in the current class colour.

Full design notes: [docs/PHANTOM_LOOP.md](docs/PHANTOM_LOOP.md).

## Controls

| Input | Action |
| --- | --- |
| `W A S D` | Move the current shell |
| Mouse | Look (drag with left button on Web, captured on desktop) |
| `1` - `4` | Select Anchor / Magnet / Spark / Phase |
| `E` | Transfer to the next shell |
| `Enter` | Transfer to the next shell |
| Class buttons | Same as `1`-`4` (always clickable on Web) |
| `SKIP / TRANSFER BODY` button | Same as `Enter` |
| `Esc` | Release the mouse on desktop |
| `R` | Restart the whole run at any time |

## Run from source

Install Godot 4.6.1 or newer, then open this folder.

```powershell
$godot = "C:\Users\PC\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe"
$project = "C:\Users\PC\Documents\project-1\phantom-loop"

& $godot --headless --path $project --editor --quit
& $godot --path $project
```

Press **F6** or the Play button.

> The game source is already present in `scripts/`, `scenes/` and `shaders/`.
> [docs/COPY_ME.md](docs/COPY_ME.md) keeps an identical copy of every file if
> you want to retype them yourself for Hackatime.

## Web export

The `Web` preset is already configured in `export_presets.cfg`.

```powershell
New-Item -ItemType Directory -Force -Path "$project\build\web" | Out-Null
& $godot --headless --path $project --export-release "Web" "$project\build\web\index.html"
```

Serve `build/web/` with a static server. `file://` does not work with WebGL.

## CI / deployment

Every push to `main` runs `.github/workflows/export-web.yml`: it downloads
Godot 4.6.1 and the export templates, exports the Web build, and publishes it
to GitHub Pages at the demo URL above. A workflow run without the game source
skips the export with a warning instead of failing.

## Project layout

```
phantom-loop/
├── project.godot          # Godot config + WASD/E/R input map
├── export_presets.cfg     # Web preset
├── docs/
│   ├── COPY_ME.md         # exact copy of the game source
│   └── PHANTOM_LOOP.md    # design doc + 50 h roadmap
├── scripts/
│   ├── phantom_loop.gd    # controller, ghosts, plates, HUD, sector flow
│   ├── level_data.gd      # 4 sector definitions
│   └── robot_shell.gd     # procedural 3D robot + class colours
├── shaders/
│   └── ghost.gdshader     # spectral ghost material
├── scenes/
│   └── main.tscn          # main scene
├── tests/
│   └── smoke_test.gd      # headless checks for plates, ghosts, classes
└── .github/workflows/     # Web export + Pages deployment
```

## Hackatime

`.wakatime-project` names this project `phantom-loop` so tracked coding time is
easy to identify. The files in `docs/COPY_ME.md` are there if you prefer to
retype the source yourself and count those hours.

## License

MIT — see [LICENSE](LICENSE).
