# Code to copy

> These blocks are the source of truth. The files in `scripts/`, `shaders/` and
> `scenes/` are generated from them. Copy them yourself if you want the coding
> hours to count for Hackatime.

Order: 1 → 2 → 3 → 4 → 5. Then open the project in Godot 4.6.1 and press F6.

---

## 1. `scripts/level_data.gd`

```gdscript
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
```

---

## 2. `scripts/robot_shell.gd`

```gdscript
extends Node3D

## Procedural 3D robot shell, used for parked ghosts and the first-person tool.

const CLASS_NAMES = ["ANCHOR", "MAGNET", "SPARK", "PHASE"]
const CLASS_COLORS = [
	Color(1.0, 0.55, 0.20),
	Color(0.25, 0.80, 1.00),
	Color(1.0, 0.85, 0.30),
	Color(0.75, 0.40, 1.00),
]

var shell_class: int = 0

func setup(cls: int, ghost: bool) -> void:
	shell_class = cls
	var color: Color = CLASS_COLORS[cls]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.45
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.25
	var ghost_mat: ShaderMaterial
	if ghost:
		ghost_mat = ShaderMaterial.new()
		ghost_mat.shader = load("res://shaders/ghost.gdshader") as Shader
		ghost_mat.set_shader_parameter("tint", color)
	_add_box(Vector3(0.0, 0.15, 0.0), Vector3(0.72, 0.80, 0.46), mat, ghost_mat)
	_add_box(Vector3(0.0, 0.76, 0.0), Vector3(0.52, 0.42, 0.44), mat, ghost_mat)
	_add_box(Vector3(0.0, 0.20, 0.33), Vector3(0.50, 0.50, 0.22), mat, ghost_mat)
	_add_capsule(Vector3(-0.52, 0.12, 0.0), 0.13, 0.62, mat, ghost_mat)
	_add_capsule(Vector3(0.52, 0.12, 0.0), 0.13, 0.62, mat, ghost_mat)
	_add_capsule(Vector3(-0.20, -0.70, 0.0), 0.15, 0.72, mat, ghost_mat)
	_add_capsule(Vector3(0.20, -0.70, 0.0), 0.15, 0.72, mat, ghost_mat)
	var eye := _add_sphere(Vector3(0.0, 0.78, -0.24), 0.11, mat, ghost_mat)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color.WHITE
	eye_mat.emission_enabled = true
	eye_mat.emission = color
	eye_mat.emission_energy_multiplier = 3.0
	eye.material_override = eye_mat if not ghost else ghost_mat

static func make_viewmodel(cls: int) -> Node3D:
	var root := Node3D.new()
	var color: Color = CLASS_COLORS[cls]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	for x in [-0.32, 0.32]:
		var hand := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.22, 0.18, 0.50)
		hand.mesh = b
		hand.material_override = mat
		hand.position = Vector3(x, -0.34, -0.55)
		root.add_child(hand)
	var panel := MeshInstance3D.new()
	var p := BoxMesh.new()
	p.size = Vector3(0.50, 0.10, 0.06)
	panel.mesh = p
	panel.material_override = mat
	panel.position = Vector3(0.0, -0.43, -0.80)
	root.add_child(panel)
	return root

func _add_box(pos: Vector3, size: Vector3, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	m.material_override = ghost_mat if ghost_mat != null else mat
	add_child(m)
	return m

func _add_capsule(pos: Vector3, radius: float, height: float, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = height
	m.mesh = c
	m.position = pos
	m.material_override = ghost_mat if ghost_mat != null else mat
	add_child(m)
	return m

func _add_sphere(pos: Vector3, radius: float, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	m.mesh = s
	m.position = pos
	m.material_override = ghost_mat if ghost_mat != null else mat
	add_child(m)
	return m
```

---

## 3. `scripts/phantom_loop.gd`

```gdscript
extends Node3D

## PHANTOM LOOP - main controller (Godot 4.6.1).
## You are the pilot. Park shells to hold plates, then move to the next sector.

const LOOP_SECONDS := 30.0
const TICK := 1.0 / 60.0
const SPEED := 6.0
const MAX_GHOSTS := 3
const NEED_ANY := -1
const NEED_KEY := -2
const RobotShell = preload("res://scripts/robot_shell.gd")
const LevelData = preload("res://scripts/level_data.gd")

var _levels: Array[Dictionary] = []
var _level_idx := 0
var _time_left := LOOP_SECONDS
var _acc := 0.0
var _frames: Array[Dictionary] = []
var _recordings: Array[Array] = []
var _ghosts: Array[Node3D] = []
var _ghost_classes: Array[int] = []
var _cursors: Array[int] = []
var _plates: Array[Dictionary] = []
var _level_nodes: Array[Node] = []
var _door: StaticBody3D
var _door_col: CollisionShape3D
var _player: CharacterBody3D
var _cam: Camera3D
var _viewmodel: Node3D
var _key: Node3D
var _key_start := Vector3.ZERO
var _label: Label
var _skip_button: Button
var _class_buttons: Array[Button] = []
var _current_class := 0
var _loops := 1
var _won := false
var _door_latched := false
var _pitch := 0.0
var _dragging := false

func _ready() -> void:
	_levels = LevelData.all()
	_build_player()
	_build_hud()
	_load_level(0)
	if OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if _won:
		return
	_acc += delta
	var steps := 0
	while _acc >= TICK and steps < 5:
		_step(TICK)
		_acc -= TICK
		steps += 1
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _select_class(0)
			KEY_2: _select_class(1)
			KEY_3: _select_class(2)
			KEY_4: _select_class(3)
			KEY_ENTER:
				if _won:
					_advance_level()
				else:
					_finish_loop()
			KEY_E:
				if not _won:
					_finish_loop()
			KEY_ESCAPE:
				_dragging = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var look := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if OS.has_feature("web"):
		look = _dragging
	if event is InputEventMouseMotion and look and not _won:
		_player.rotate_y(-event.relative.x * 0.0025)
		_pitch = clampf(_pitch - event.relative.y * 0.0025, -1.2, 1.2)
		_cam.rotation.x = _pitch
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if OS.has_feature("web"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _step(dt: float) -> void:
	_time_left -= dt
	if _time_left <= 0.0:
		_finish_loop()
		return
	var input := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var local := Vector3(input.x, 0.0, -input.y)
	var dir := (_player.global_transform.basis * local).normalized()
	_player.velocity.x = dir.x * SPEED
	_player.velocity.z = dir.z * SPEED
	_player.move_and_slide()
	_frames.append({"pos": _player.global_position, "cls": _current_class})

	for i in _ghosts.size():
		var frames: Array = _recordings[i]
		if frames.is_empty():
			continue
		if _cursors[i] >= frames.size():
			_cursors[i] = frames.size() - 1
		var f: Dictionary = frames[_cursors[i]]
		_ghosts[i].global_position = f["pos"]
		_cursors[i] += 1
		_ghosts[i].visible = _ghosts[i].global_position.distance_to(_player.global_position) > 1.4

	_move_key(dt)
	_check_plates()
	if _door_latched and _player.global_position.z < -8.2:
		_win()

func _check_plates() -> void:
	var all := true
	for plate in _plates:
		var need: int = plate["need"]
		var radius: float = plate["r"]
		var pos: Vector3 = plate["pos"]
		var active := false
		if need == NEED_KEY:
			active = _key != null and _flat_dist(_key.global_position, pos) < radius
		else:
			if _class_matches(need, _current_class) and _flat_dist(_player.global_position, pos) < radius:
				active = true
			if not active:
				for i in _ghosts.size():
					if _class_matches(need, _ghost_classes[i]) and _flat_dist(_ghosts[i].global_position, pos) < radius:
						active = true
						break
		plate["active"] = active
		var mat: StandardMaterial3D = plate["mat"]
		mat.albedo_color = Color(0.35, 1.0, 0.85) if active else plate["off_color"]
		mat.emission_energy_multiplier = 2.0 if active else 0.25
		if not active:
			all = false
	if all and not _door_latched:
		_door_latched = true
	_open_door(_door_latched)

func _class_matches(need: int, cls: int) -> bool:
	return need == NEED_ANY or need == cls

func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _move_key(dt: float) -> void:
	if _key == null:
		return
	var target: Node3D = null
	var best := 6.0
	if _current_class == 1:
		var d := _flat_dist(_player.global_position, _key.global_position)
		if d < best:
			best = d
			target = _player
	for i in _ghosts.size():
		if _ghost_classes[i] != 1:
			continue
		var d := _flat_dist(_ghosts[i].global_position, _key.global_position)
		if d < best:
			best = d
			target = _ghosts[i]
	if target != null and best > 0.05:
		var from := _key.global_position
		var to := target.global_position
		var dir := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
		var step := minf(2.5 * dt, best)
		_key.global_position = Vector3(from.x + dir.x * step, _key_start.y, from.z + dir.z * step)

func _finish_loop() -> void:
	if _won:
		return
	if _frames.size() > 2 and _recordings.size() < MAX_GHOSTS:
		_recordings.append(_frames.duplicate(true))
	_loops += 1
	_reset_room()

func _reset_room() -> void:
	var level: Dictionary = _levels[_level_idx]
	_time_left = LOOP_SECONDS
	_acc = 0.0
	_frames.clear()
	_door_latched = false
	_pitch = 0.0
	_dragging = false
	_cam.rotation.x = 0.0
	_player.rotation.y = float(level.get("yaw", 0.0))
	_player.global_position = level["spawn"]
	_player.velocity = Vector3.ZERO
	_player.collision_mask = 1 if _current_class == 3 else 5
	_open_door(false)
	if _key != null:
		_key.global_position = _key_start
	for g in _ghosts:
		g.queue_free()
	_ghosts.clear()
	_ghost_classes.clear()
	_cursors.clear()
	for rec in _recordings:
		var cls: int = rec[rec.size() - 1]["cls"] if not rec.is_empty() else 0
		_ghosts.append(_make_ghost(cls))
		_ghost_classes.append(cls)
		_cursors.append(0)
	for plate in _plates:
		plate["active"] = false
		var mat: StandardMaterial3D = plate["mat"]
		mat.albedo_color = plate["off_color"]
		mat.emission_energy_multiplier = 0.25

func _make_ghost(cls: int) -> Node3D:
	var g := CharacterBody3D.new()
	g.collision_layer = 2
	g.collision_mask = 0
	var model := RobotShell.new()
	model.setup(cls, true)
	g.add_child(model)
	add_child(g)
	g.global_position = _levels[_level_idx]["spawn"]
	return g

func _select_class(cls: int) -> void:
	_current_class = cls
	if _viewmodel != null:
		_viewmodel.queue_free()
	_viewmodel = RobotShell.make_viewmodel(cls)
	_cam.add_child(_viewmodel)
	_player.collision_mask = 1 if cls == 3 else 5
	for i in _class_buttons.size():
		_class_buttons[i].modulate = Color(1, 1, 1, 1) if i == cls else Color(0.45, 0.45, 0.45, 1)
	_update_hud()

func _win() -> void:
	_won = true
	_dragging = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_hud()

func _advance_level() -> void:
	if _level_idx + 1 < _levels.size():
		_load_level(_level_idx + 1)
	else:
		get_tree().reload_current_scene()

func _load_level(idx: int) -> void:
	_level_idx = idx
	for n in _level_nodes:
		n.queue_free()
	_level_nodes.clear()
	_plates.clear()
	_recordings.clear()
	_loops = 1
	_won = false
	_key = null
	var level: Dictionary = _levels[idx]
	_build_room()
	for w in level.get("walls", []):
		_box(w["pos"], w["size"], Color(0.18, 0.20, 0.32), 3 if w.get("phase", false) else 1)
	_build_door()
	for p in level["plates"]:
		_make_plate(p)
	if level.get("key") != null:
		_key = _make_key(level["key"])
		_key_start = level["key"]
	_select_class(_current_class)
	_reset_room()

func _open_door(open: bool) -> void:
	_door.visible = not open
	_door_col.disabled = open

func _update_hud() -> void:
	if _levels.is_empty():
		return
	var level: Dictionary = _levels[_level_idx]
	var active := 0
	for p in _plates:
		if p["active"]:
			active += 1
	var msg := "%s  |  %04.1fs  |  shell %d/%d  |  parked %d/%d  |  plates %d/%d\n" % [level["name"], _time_left, mini(_loops, MAX_GHOSTS + 1), MAX_GHOSTS + 1, _ghosts.size(), MAX_GHOSTS, active, _plates.size()]
	msg += "CLASS: %s  |  %s\n" % [RobotShell.CLASS_NAMES[_current_class], level["hint"]]
	if _won:
		msg = "SECTOR CLEAR - %s in %d shells\nPress Enter for the next sector - R restarts." % [level["name"], _loops]
	elif _recordings.size() >= MAX_GHOSTS:
		msg += "NO SHELLS LEFT - press R to restart\n"
	_label.text = msg

func _build_room() -> void:
	var dark := Color(0.07, 0.08, 0.13)
	var floor_col := Color(0.14, 0.16, 0.24)
	_box(Vector3(0.0, -0.3, 0.0), Vector3(22.0, 0.6, 22.0), floor_col)
	_box(Vector3(0.0, 4.0, -10.5), Vector3(22.0, 9.0, 1.0), dark)
	_box(Vector3(0.0, 4.0, 10.5), Vector3(22.0, 9.0, 1.0), dark)
	_box(Vector3(-10.5, 4.0, 0.0), Vector3(1.0, 9.0, 22.0), dark)
	_box(Vector3(10.5, 4.0, 0.0), Vector3(1.0, 9.0, 22.0), dark)
	for x in range(-10, 11, 2):
		_deco_box(Vector3(float(x), 0.01, 0.0), Vector3(0.04, 0.02, 21.0), Color(0.05, 0.18, 0.24))
	for z in range(-10, 11, 2):
		_deco_box(Vector3(0.0, 0.01, float(z)), Vector3(21.0, 0.02, 0.04), Color(0.05, 0.18, 0.24))

func _build_door() -> void:
	_door = _box(Vector3(0.0, 1.5, -10.0), Vector3(4.0, 3.0, 0.5), Color(0.95, 0.55, 0.20))
	_door_col = _door.get_child(1) as CollisionShape3D
	_deco_box(Vector3(-2.2, 1.6, -10.0), Vector3(0.3, 3.4, 0.8), Color(0.3, 0.35, 0.5))
	_deco_box(Vector3(2.2, 1.6, -10.0), Vector3(0.3, 3.4, 0.8), Color(0.3, 0.35, 0.5))
	_deco_box(Vector3(0.0, 3.3, -10.0), Vector3(4.7, 0.3, 0.8), Color(0.3, 0.35, 0.5))
	_deco_box(Vector3(0.0, 1.5, -9.72), Vector3(3.2, 0.06, 0.05), Color(1.0, 0.8, 0.3))

func _box(pos: Vector3, size: Vector3, color: Color, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 1
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.25
	mat.roughness = 0.65
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	body.global_position = pos
	_level_nodes.append(body)
	return body

func _deco_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	m.material_override = mat
	add_child(m)
	m.global_position = pos
	_level_nodes.append(m)

func _make_plate(p: Dictionary) -> Area3D:
	var need: int = p["need"]
	var off: Color = Color(0.2, 0.8, 0.9)
	if need == NEED_KEY:
		off = Color(1.0, 0.8, 0.25)
	elif need >= 0:
		off = RobotShell.CLASS_COLORS[need]
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.85
	cyl.bottom_radius = 0.95
	cyl.height = 0.16
	base.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = off
	mat.metallic = 0.5
	mat.emission_enabled = true
	mat.emission = off
	mat.emission_energy_multiplier = 0.25
	base.material_override = mat
	area.add_child(base)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.78
	torus.outer_radius = 1.0
	ring.mesh = torus
	ring.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	ring.position.y = 0.1
	ring.material_override = mat
	area.add_child(ring)
	add_child(area)
	area.global_position = p["pos"]
	_level_nodes.append(area)
	_plates.append({
		"pos": p["pos"],
		"need": need,
		"r": p.get("r", 1.15),
		"mat": mat,
		"off_color": off,
		"active": false,
	})
	return area

func _make_key(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	var cube := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.6, 0.6, 0.6)
	cube.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2)
	mat.metallic = 0.9
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1)
	mat.emission_energy_multiplier = 0.4
	cube.material_override = mat
	root.add_child(cube)
	var core := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.18
	core.mesh = s
	core.material_override = mat
	root.add_child(core)
	add_child(root)
	root.global_position = pos
	_level_nodes.append(root)
	return root

func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.collision_layer = 1
	_player.collision_mask = 5
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	col.shape = capsule
	_player.add_child(col)
	_cam = Camera3D.new()
	_cam.position = Vector3(0.0, 0.7, 0.0)
	_player.add_child(_cam)
	add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 7.0)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	add_child(light)
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.3, 0.45)
	ambient.environment = env
	add_child(ambient)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(24.0, 18.0)
	_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(_label)
	_skip_button = Button.new()
	_skip_button.text = "SKIP / TRANSFER BODY  [Enter]"
	_skip_button.position = Vector2(24.0, 118.0)
	_skip_button.size = Vector2(330.0, 36.0)
	_skip_button.pressed.connect(_finish_loop)
	canvas.add_child(_skip_button)
	var names := ["1 ANCHOR", "2 MAGNET", "3 SPARK", "4 PHASE"]
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.position = Vector2(24.0 + float(i) * 118.0, 160.0)
		b.size = Vector2(112.0, 34.0)
		b.pressed.connect(_select_class.bind(i))
		canvas.add_child(b)
		_class_buttons.append(b)
	add_child(canvas)
```

---

## 4. `shaders/ghost.gdshader`

```gdscript
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec3 tint = vec3(0.35, 0.85, 1.0);

void fragment() {
	ALBEDO = tint;
	ALPHA = 0.35 + 0.15 * sin(TIME * 4.0);
}
```

---

## 5. `scenes/main.tscn`

```gdscene
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/phantom_loop.gd" id="1_phantom"]

[node name="Main" type="Node3D"]
script = ExtResource("1_phantom")
```

---

### Lore and how it works

You are not the robot. You are the **pilot** of a fleet of shells in a derelict
facility. When you transfer, the old shell replays its last route and then
freezes, so it keeps holding whatever it was standing on.

- Plates are **automatic**: any shell standing on one lights it. There is no
  `E` requirement for detection.
- `E`, `Enter` and the skip button all transfer you into a fresh shell. Timer
  expiry transfers you too.
- Press `1`-`4` or click a class button at any time to change the class of the
  shell you currently control. It stays that class after parking.
- **Anchor** can hold heavy red plates. **Magnet** pulls the gold core. **Spark**
  lights remote pads from a distance. **Phase** walks through thin purple walls.
- Each new shell spawns facing the room. The door latches open while all plates
  are lit. At most 3 shells can be parked.

### Class reference

| Key | Class | Passive ability | Plate colour |
|-----|-------|-----------------|--------------|
| `1` | Anchor | Can hold heavy plates | Red-orange |
| `2` | Magnet | Pulls the gold core within 6 m | Cyan |
| `3` | Spark | Lights remote pads within 3.6 m | Yellow |
| `4` | Phase | Ignores phase walls | Purple |

### Sector reference

| # | Name | New mechanic |
|---|------|--------------|
| 1 | Antechamber | Automatic plates, parking |
| 2 | Heavy Foundry | Anchor-only plate |
| 3 | Magnet Bay | Pull the core onto a plate |
| 4 | Phase Vault | Phase wall + Spark remote pad |

## Verification

```powershell
$godot = "C:\Users\PC\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe"
$project = "C:\Users\PC\Documents\project-1\phantom-loop"
& $godot --headless --path $project --script $project\tests\smoke_test.gd
& $godot --path $project
```

## Ideas to build next

- Animated robot walk cycle instead of static meshes.
- More classes: Drone (flies), Echo (duplicates the previous shell).
- Level-specific ambient audio and a glitch effect on transfer.
- Co-op using the signaling server from the Climb Together project.
