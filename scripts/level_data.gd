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
			"key": null,
		},
	]
