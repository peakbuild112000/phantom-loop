extends Node

## Sector definitions for PHANTOM LOOP.
## need: ANY = any class, KEY = gold core, 0..3 = RobotShell class id.

const ANY := -1
const KEY := -2

static func all() -> Array[Dictionary]:
	return [
		{
			"name": "01 / ANTECHAMBER",
			"hint": "Park a shell on each plate. Any class works.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-4.0, 0.12, -2.0), "need": ANY},
				{"pos": Vector3(4.0, 0.12, -5.0), "need": ANY},
				{"pos": Vector3(0.0, 0.12, 2.5), "need": ANY},
			],
			"walls": [],
			"movers": [],
			"key": null,
		},
		{
			"name": "02 / HEAVY FOUNDRY",
			"hint": "The red plate is heavy: only ANCHOR [1] can hold it.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-4.5, 0.12, -2.0), "need": ANY},
				{"pos": Vector3(1.0, 0.12, 3.0), "need": ANY},
				{"pos": Vector3(5.0, 0.12, -5.5), "need": 0, "r": 1.35},
			],
			"walls": [
				{"pos": Vector3(0.0, 1.5, -1.0), "size": Vector3(6.0, 3.0, 0.5), "phase": false},
			],
			"movers": [],
			"key": null,
		},
		{
			"name": "03 / MAGNET BAY",
			"hint": "MAGNET [2] pulls the gold core onto the dark pad.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-5.0, 0.12, -2.0), "need": ANY},
				{"pos": Vector3(5.0, 0.12, -2.0), "need": ANY},
				{"pos": Vector3(0.0, 0.12, -6.5), "need": KEY, "r": 1.4},
			],
			"walls": [],
			"movers": [],
			"key": Vector3(0.0, 0.55, 3.0),
		},
		{
			"name": "04 / PHASE VAULT",
			"hint": "PHASE [4] crosses the thin wall; SPARK [3] lights the remote pad.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-5.0, 0.12, 1.0), "need": ANY},
				{"pos": Vector3(5.5, 0.12, 2.0), "need": 2, "r": 3.6},
				{"pos": Vector3(0.0, 0.12, -7.5), "need": ANY},
			],
			"walls": [
				{"pos": Vector3(0.0, 2.0, -4.0), "size": Vector3(7.0, 4.0, 0.4), "phase": true},
			],
			"movers": [],
			"key": null,
		},
		{
			"name": "05 / STEP LADDER",
			"hint": "SPACE jumps. Climb the blue steps to reach the high cyan pad.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-6.0, 0.12, -1.0), "need": ANY},
				{"pos": Vector3(6.0, 0.12, -1.0), "need": ANY},
				{"pos": Vector3(0.0, 2.62, -6.5), "need": ANY},
			],
			"walls": [
				{"pos": Vector3(-3.5, 0.5, -3.5), "size": Vector3(2.5, 1.0, 2.5), "color": "#1B4A66"},
				{"pos": Vector3(-1.7, 1.25, -4.8), "size": Vector3(2.4, 2.5, 2.4), "color": "#256080"},
				{"pos": Vector3(0.5, 1.25, -7.0), "size": Vector3(4.0, 2.5, 3.0), "color": "#2E7896"},
			],
			"movers": [],
			"key": null,
		},
		{
			"name": "06 / GRATED CELL",
			"hint": "SPARK [3] lights the caged pad through the grate; PHASE [4] crosses the purple wall.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-6.0, 0.12, 1.0), "need": ANY},
				{"pos": Vector3(7.2, 0.12, 1.0), "need": 2, "r": 4.0},
				{"pos": Vector3(0.0, 0.12, -7.0), "need": ANY},
			],
			"walls": [
				{"pos": Vector3(5.2, 1.5, 1.0), "size": Vector3(0.4, 3.0, 4.5)},
				{"pos": Vector3(9.2, 1.5, 1.0), "size": Vector3(0.4, 3.0, 4.5)},
				{"pos": Vector3(7.2, 1.5, 3.3), "size": Vector3(4.4, 3.0, 0.4)},
				{"pos": Vector3(7.2, 1.5, -1.3), "size": Vector3(4.4, 3.0, 0.4), "color": "#3A5B78"},
				{"pos": Vector3(0.0, 2.0, -4.0), "size": Vector3(20.0, 4.0, 0.4), "phase": true},
			],
			"movers": [],
			"key": null,
		},
		{
			"name": "07 / MAGNET RIDGE",
			"hint": "SPACE jumps to the high pad; MAGNET [2] leads the core through the slit to the gold pad.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-6.0, 0.12, 3.0), "need": ANY},
				{"pos": Vector3(4.0, 2.62, -3.0), "need": ANY},
				{"pos": Vector3(0.0, 0.12, -7.5), "need": KEY, "r": 1.4},
			],
			"walls": [
				{"pos": Vector3(-5.5, 1.5, -1.0), "size": Vector3(9.0, 3.0, 0.5)},
				{"pos": Vector3(5.5, 1.5, -1.0), "size": Vector3(9.0, 3.0, 0.5)},
				{"pos": Vector3(6.0, 0.5, -2.0), "size": Vector3(2.0, 1.0, 2.0), "color": "#1B4A66"},
				{"pos": Vector3(4.0, 1.25, -3.0), "size": Vector3(3.0, 2.5, 3.0), "color": "#2E7896"},
			],
			"movers": [],
			"key": Vector3(0.0, 0.55, 5.0),
		},
		{
			"name": "08 / SWEEPING GATE",
			"hint": "Jump the low bar with SPACE, then slip under the rising red gate to reach the back pad.",
			"spawn": Vector3(0.0, 1.0, 7.0),
			"yaw": 0.0,
			"plates": [
				{"pos": Vector3(-6.0, 0.12, 2.0), "need": ANY},
				{"pos": Vector3(6.0, 0.12, 2.0), "need": ANY},
				{"pos": Vector3(0.0, 0.12, -7.5), "need": ANY},
			],
			"walls": [
				{"pos": Vector3(0.0, 0.4, -3.0), "size": Vector3(20.0, 0.8, 0.5), "color": "#6B4A20"},
			],
			"movers": [
				{"pos": Vector3(0.0, 1.5, -5.0), "size": Vector3(20.0, 2.6, 0.5), "axis": "y", "amp": 1.9, "speed": 1.4, "phase": 0.0},
			],
			"key": null,
		},
	]
