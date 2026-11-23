# PHANTOM LOOP 👻

**Demo:** <https://peakbuild112000.github.io/phantom-loop/>  
**Repository:** <https://github.com/peakbuild112000/phantom-loop>  
**Engine:** Godot 4.6.1 stable

A time-loop escape room built for **PHANTOM**, the Hack Club hackathon. You are
a pilot jumping between robot shells. Every shell you abandon stays behind and
keeps holding its position, so you can cooperate with your own past bodies.

## Contents

- [Demo](#demo)
- [How to play](#how-to-play)
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
enabled. Click the canvas once if mouse look does not respond.

Source code:

<https://github.com/peakbuild112000/phantom-loop>

## How to play

You are not the robot: you are the **pilot** of a series of shells in a derelict
facility. Each shell has 30 seconds of power. Stand on the three glowing plates
at the same time to open the door.

* Move a shell onto a plate and press `E` to **dock** it. The pilot transfers
  into a fresh shell at the entry point, and the old shell stays on the plate.
* `Enter` or the `SKIP LOOP / TRANSFER BODY` button transfers immediately
  without docking. Letting the timer expire transfers you too.
* A parked shell replays its last route and then **freezes**, so it keeps
  holding the plate forever instead of walking away.
* Once all plates are lit, the door stays open for the rest of the loop.
* The first puzzle needs two parked shells plus yourself. Future rooms will add
  different robot classes with their own abilities - see
  [docs/PHANTOM_LOOP.md](docs/PHANTOM_LOOP.md).

## Controls

| Input | Action |
| --- | --- |
| `W A S D` | Move the current shell |
| Mouse | Look (drag with left button on Web, captured on desktop) |
| `E` (on a plate) | Dock the shell and transfer to the next one |
| `Enter` | Skip the timer / transfer immediately |
| `SKIP LOOP / TRANSFER BODY` button | Same as `Enter` (always clickable on Web) |
| `Esc` | Release the mouse on desktop |
| Click | Capture the mouse again |
| `R` | Restart after escaping |

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
│   └── phantom_loop.gd    # loop recorder, ghost replay, puzzles, HUD
├── shaders/
│   └── ghost.gdshader     # spectral ghost material
├── scenes/
│   └── main.tscn          # main scene
└── .github/workflows/     # Web export + Pages deployment
```

## Hackatime

`.wakatime-project` names this project `phantom-loop` so tracked coding time is
easy to identify. The files in `docs/COPY_ME.md` are there if you prefer to
retype the source yourself and count those hours.

## License

MIT — see [LICENSE](LICENSE).
