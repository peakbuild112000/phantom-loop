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
var _torso: MeshInstance3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _eye: MeshInstance3D

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
	_torso = _add_box(Vector3(0.0, 0.15, 0.0), Vector3(0.72, 0.80, 0.46), mat, ghost_mat)
	_add_box(Vector3(0.0, 0.20, 0.33), Vector3(0.50, 0.50, 0.22), mat, ghost_mat)
	_head = _pivot(Vector3(0.0, 0.62, 0.0))
	_add_box_child(_head, Vector3(0.0, 0.14, 0.0), Vector3(0.52, 0.42, 0.44), mat, ghost_mat)
	_eye = _add_sphere_child(_head, Vector3(0.0, 0.16, -0.24), 0.11, mat, ghost_mat)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color.WHITE
	eye_mat.emission_enabled = true
	eye_mat.emission = color
	eye_mat.emission_energy_multiplier = 3.0
	_eye.material_override = eye_mat if not ghost else ghost_mat
	_arm_l = _pivot(Vector3(-0.52, 0.45, 0.0))
	_add_capsule_child(_arm_l, Vector3(0.0, -0.33, 0.0), 0.13, 0.62, mat, ghost_mat)
	_arm_r = _pivot(Vector3(0.52, 0.45, 0.0))
	_add_capsule_child(_arm_r, Vector3(0.0, -0.33, 0.0), 0.13, 0.62, mat, ghost_mat)
	_leg_l = _pivot(Vector3(-0.20, -0.34, 0.0))
	_add_capsule_child(_leg_l, Vector3(0.0, -0.36, 0.0), 0.15, 0.72, mat, ghost_mat)
	_leg_r = _pivot(Vector3(0.20, -0.34, 0.0))
	_add_capsule_child(_leg_r, Vector3(0.0, -0.36, 0.0), 0.15, 0.72, mat, ghost_mat)

func animate(t: float, speed: float) -> void:
	var amount := clampf(speed / 6.0, 0.0, 1.0)
	var swing := sin(t * 10.0) * 0.65 * amount
	_arm_l.rotation.x = swing
	_arm_r.rotation.x = -swing
	_leg_l.rotation.x = -swing
	_leg_r.rotation.x = swing
	_torso.position.y = 0.15 + absf(sin(t * 10.0)) * 0.05 * amount
	_head.rotation.z = sin(t * 2.0) * 0.05
	_head.rotation.y = sin(t * 1.3) * 0.08
	var pulse := 1.0 + 0.12 * sin(t * 5.0)
	_eye.scale = Vector3(pulse, pulse, pulse)

static func make_viewmodel(cls: int) -> Node3D:
	var root := Node3D.new()
	var color: Color = CLASS_COLORS[cls]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	_make_hand(root, "HandL", -1.0, mat)
	_make_hand(root, "HandR", 1.0, mat)
	var tool := MeshInstance3D.new()
	match cls:
		0:
			var b := BoxMesh.new()
			b.size = Vector3(0.30, 0.24, 0.20)
			tool.mesh = b
			tool.position = Vector3(0.0, 0.02, -0.26)
		1:
			var t := TorusMesh.new()
			t.inner_radius = 0.09
			t.outer_radius = 0.17
			tool.mesh = t
			tool.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			tool.position = Vector3(0.0, 0.0, -0.24)
		2:
			var c := CylinderMesh.new()
			c.top_radius = 0.07
			c.bottom_radius = 0.07
			c.height = 0.34
			tool.mesh = c
			tool.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			tool.position = Vector3(0.0, 0.0, -0.28)
		3:
			var blade := BoxMesh.new()
			blade.size = Vector3(0.05, 0.06, 0.46)
			tool.mesh = blade
			tool.position = Vector3(0.0, 0.0, -0.32)
	tool.material_override = mat
	tool.name = "Tool"
	(root.get_node("HandR") as Node3D).add_child(tool)
	return root

static func _make_hand(root: Node3D, hand_name: String, side: float, mat: Material) -> void:
	var hand := Node3D.new()
	hand.name = hand_name
	hand.position = Vector3(0.32 * side, -0.30, -0.52)
	hand.rotation.y = -0.12 * side
	root.add_child(hand)
	var forearm := MeshInstance3D.new()
	var sleeve := BoxMesh.new()
	sleeve.size = Vector3(0.20, 0.19, 0.52)
	forearm.mesh = sleeve
	forearm.material_override = mat
	forearm.position = Vector3(0.0, -0.02, 0.24)
	forearm.rotation.x = -0.10
	hand.add_child(forearm)
	var fist := MeshInstance3D.new()
	var knuckle := BoxMesh.new()
	knuckle.size = Vector3(0.24, 0.20, 0.22)
	fist.mesh = knuckle
	fist.material_override = mat
	fist.position = Vector3(0.0, 0.0, -0.10)
	hand.add_child(fist)

func _pivot(pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	add_child(p)
	return p

func _add_box(pos: Vector3, size: Vector3, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	return _add_box_child(self, pos, size, mat, ghost_mat)

func _add_box_child(parent: Node, pos: Vector3, size: Vector3, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	m.material_override = ghost_mat if ghost_mat != null else mat
	parent.add_child(m)
	return m

func _add_capsule(pos: Vector3, radius: float, height: float, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	return _add_capsule_child(self, pos, radius, height, mat, ghost_mat)

func _add_capsule_child(parent: Node, pos: Vector3, radius: float, height: float, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = height
	m.mesh = c
	m.position = pos
	m.material_override = ghost_mat if ghost_mat != null else mat
	parent.add_child(m)
	return m

func _add_sphere(pos: Vector3, radius: float, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	return _add_sphere_child(self, pos, radius, mat, ghost_mat)

func _add_sphere_child(parent: Node, pos: Vector3, radius: float, mat: Material, ghost_mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	m.mesh = s
	m.position = pos
	m.material_override = ghost_mat if ghost_mat != null else mat
	parent.add_child(m)
	return m
```

---

## 3. `scripts/phantom_loop.gd`

```gdscript
extends Node3D

## PHANTOM LOOP - main controller (Godot 4.6.1).
## You are the pilot. Park shells to hold plates, then move to the next sector.

const TICK := 1.0 / 60.0
const SPEED := 6.0
const MAX_GHOSTS := 3
const NEED_ANY := -1
const NEED_KEY := -2
const RobotShell = preload("res://scripts/robot_shell.gd")
const LevelData = preload("res://scripts/level_data.gd")

var _levels: Array[Dictionary] = []
var _level_idx := 0
var _elapsed := 0.0
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
var _game_over := false
var _transition := 0.0
var _door_latched := false
var _pitch := 0.0
var _dragging := false
var _anim_t := 0.0
var _ghost_speeds: Array[float] = []
var _door_y := 1.5
var _door_target_y := 1.5
var _flash: ColorRect
var _flash_alpha := 0.0
var _mouse_released_by_user := false

func _ready() -> void:
	_levels = LevelData.all()
	_build_player()
	_build_hud()
	_load_level(0)
	_apply_mouse_mode()

func _apply_mouse_mode() -> void:
	# Called on boot AND after every level load / transfer: the mouse must never
	# silently stay unlocked when a new sector starts.
	if OS.has_feature("web"):
		# Web has no pointer lock - drag look keeps HUD buttons clickable.
		# Keep dragging if the button is still held during the transition.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_dragging = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	elif _mouse_released_by_user:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_dragging = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_dragging = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if _won or _game_over or _transition > 0.0:
		return
	_acc += delta
	var steps := 0
	while _acc >= TICK and steps < 5:
		_step(TICK)
		_acc -= TICK
		steps += 1
	_update_hud()

func _process(delta: float) -> void:
	_anim_t += delta
	# Walking through the door closes it, then loads the next sector on its own.
	if _won and _transition > 0.0:
		_transition -= delta
		if _transition <= 0.0:
			_advance_level()
	if _game_over:
		_flash_alpha = 0.3
	# Door slides down into the floor instead of popping out of existence.
	_door_y = lerpf(_door_y, _door_target_y, clampf(delta * 9.0, 0.0, 1.0))
	if _door != null:
		_door.position.y = _door_y
	# First-person hands: walking bob plus a slow idle sway.
	if _viewmodel != null:
		var amount := clampf(_player.velocity.length() / SPEED, 0.0, 1.0)
		_viewmodel.position.x = sin(_anim_t * 5.0) * 0.006 * amount
		_viewmodel.position.y = sin(_anim_t * 10.0) * 0.012 * amount + sin(_anim_t * 2.0) * 0.003
		_viewmodel.rotation.z = sin(_anim_t * 5.0) * 0.02 * amount
		_viewmodel.rotation.x = -0.02 + absf(sin(_anim_t * 10.0)) * 0.025 * amount
		var hl := _viewmodel.get_node_or_null("HandL")
		var hr := _viewmodel.get_node_or_null("HandR")
		if hl != null:
			(hl as Node3D).rotation.x = sin(_anim_t * 10.0) * 0.12 * amount
		if hr != null:
			(hr as Node3D).rotation.x = -sin(_anim_t * 10.0) * 0.12 * amount
	# Parked shells walk in place with their recorded motion.
	for i in _ghosts.size():
		var model := _ghosts[i].get_child(0)
		if model.has_method("animate"):
			model.animate(_anim_t + float(i) * 0.7, _ghost_speeds[i] if i < _ghost_speeds.size() else 0.0)
	# Lit plates breathe; the key core spins and hovers.
	for plate in _plates:
		if plate["active"]:
			var mat: StandardMaterial3D = plate["mat"]
			mat.emission_energy_multiplier = 1.6 + 0.6 * sin(_anim_t * 6.0)
			var ring: MeshInstance3D = plate["ring"]
			var s := 1.0 + 0.04 * sin(_anim_t * 6.0)
			ring.scale = Vector3(s, s, s)
	if _key != null:
		_key.rotation.y += delta * 1.6
	# Transfer flash fades out and gives a small FOV punch.
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.2)
		_flash.color.a = _flash_alpha
		_cam.fov = 75.0 + 5.0 * _flash_alpha
	elif _cam.fov != 75.0:
		_cam.fov = 75.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _select_class(0)
			KEY_2: _select_class(1)
			KEY_3: _select_class(2)
			KEY_4: _select_class(3)
			KEY_ENTER:
				if not _won and not _game_over:
					_finish_loop()
			KEY_E:
				if not _won and not _game_over:
					_finish_loop()
			KEY_ESCAPE:
				_mouse_released_by_user = true
				_apply_mouse_mode()
	var look := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if OS.has_feature("web"):
		look = _dragging
	if event is InputEventMouseMotion and look and not _won and not _game_over:
		_player.rotate_y(-event.relative.x * 0.0025)
		_pitch = clampf(_pitch - event.relative.y * 0.0025, -1.2, 1.2)
		_cam.rotation.x = _pitch
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_mouse_released_by_user = false
		if OS.has_feature("web"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _step(dt: float) -> void:
	_elapsed += dt
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
		var previous: Vector3 = _ghosts[i].global_position
		_ghosts[i].global_position = f["pos"]
		if i < _ghost_speeds.size():
			_ghost_speeds[i] = previous.distance_to(_ghosts[i].global_position) / dt
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
		_key.global_position = Vector3(from.x + dir.x * step, _key_start.y + sin(_anim_t * 3.0) * 0.05, from.z + dir.z * step)

func _finish_loop() -> void:
	if _won or _game_over:
		return
	# No shells left: this transfer is a loss, not another free reset.
	if _recordings.size() >= MAX_GHOSTS:
		_game_over = true
		_flash.color = Color(0.75, 0.06, 0.12, 0.3)
		_flash_alpha = 0.3
		_update_hud()
		return
	if _frames.size() > 2:
		_recordings.append(_frames.duplicate(true))
	var c: Color = RobotShell.CLASS_COLORS[_current_class]
	_flash.color = Color(c.r, c.g, c.b, 0.32)
	_flash_alpha = 0.32
	_loops += 1
	_reset_room()

func _reset_room() -> void:
	var level: Dictionary = _levels[_level_idx]
	_elapsed = 0.0
	_acc = 0.0
	_frames.clear()
	_door_latched = false
	_pitch = 0.0
	_apply_mouse_mode()
	_cam.rotation.x = 0.0
	_player.rotation.y = float(level.get("yaw", 0.0))
	_player.global_position = level["spawn"]
	_player.velocity = Vector3.ZERO
	_player.collision_mask = 1 if _current_class == 3 else 5
	_door_y = 1.5
	_door_target_y = 1.5
	_door.position.y = _door_y
	_open_door(false)
	if _key != null:
		_key.global_position = _key_start
	for g in _ghosts:
		g.queue_free()
	_ghosts.clear()
	_ghost_classes.clear()
	_ghost_speeds.clear()
	_cursors.clear()
	for rec in _recordings:
		var cls: int = rec[rec.size() - 1]["cls"] if not rec.is_empty() else 0
		_ghosts.append(_make_ghost(cls))
		_ghost_classes.append(cls)
		_ghost_speeds.append(0.0)
		_cursors.append(0)
	for plate in _plates:
		plate["active"] = false
		var mat: StandardMaterial3D = plate["mat"]
		mat.albedo_color = plate["off_color"]
		mat.emission_energy_multiplier = 0.25
		(plate["ring"] as MeshInstance3D).scale = Vector3.ONE

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
	_door_col.disabled = false
	_door_target_y = 1.5
	_flash.color = Color(0.6, 1.0, 0.8, 0.55)
	_flash_alpha = 0.55
	_transition = 0.45
	# Deliberately keep the current mouse mode here: releasing on the door
	# crossing was what made the view unlock on every sector change.
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
	_game_over = false
	_transition = 0.0
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
	_door.visible = true
	_door_col.disabled = open
	_door_target_y = -1.7 if open else 1.5

func _update_hud() -> void:
	if _levels.is_empty():
		return
	var level: Dictionary = _levels[_level_idx]
	var active := 0
	for p in _plates:
		if p["active"]:
			active += 1
	var left := MAX_GHOSTS - _recordings.size()
	var msg := "%s  |  T+%04.1fs  |  shell %d  |  copies left %d/%d  |  plates %d/%d\n" % [level["name"], _elapsed, mini(_loops, MAX_GHOSTS + 1), left, MAX_GHOSTS, active, _plates.size()]
	msg += "CLASS: %s  |  %s\n" % [RobotShell.CLASS_NAMES[_current_class], level["hint"]]
	if _game_over:
		msg = "GAME OVER - OUT OF COPIES\nPress R to restart the run"
	elif _won:
		msg = "SECTOR CLEAR - %s in %d shells\nOpening next sector..." % [level["name"], _loops]
	elif left == 0:
		msg += "LAST COPY - solve this sector or the next transfer loses\n"
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
		"ring": ring,
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
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_flash)
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
	float slow = sin(TIME * 4.0);
	float flicker = sin(TIME * 11.0 + FRAGCOORD.y * 0.05);
	ALPHA = 0.30 + 0.12 * slow + 0.06 * flicker;
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
- `E`, `Enter` and the skip button transfer you into a fresh shell. **There is
  no timer any more**: nothing transfers you unless you choose to. The HUD shows
  a stopwatch instead of a countdown.
- **Copies are limited to 3.** Using a fourth transfer ends the run with a
  `GAME OVER` screen. Press `R` to retry the sector from scratch.
- Press `1`-`4` or click a class button at any time to change the class of the
  shell you currently control. It stays that class after parking.
- **Anchor** can hold heavy red plates. **Magnet** pulls the gold core. **Spark**
  lights remote pads from a distance. **Phase** walks through thin purple walls.
- Each new shell spawns facing the room. The door latches open while all plates
  are lit. Walking through it closes the door and loads the next sector
  automatically - no extra key press.

### Class reference

| Key | Class | Passive ability | Plate colour |
|-----|-------|-----------------|--------------|
| `1` | Anchor | Can hold heavy plates | Red-orange |
| `2` | Magnet | Pulls the gold core within 6 m | Cyan |
| `3` | Spark | Lights remote pads within 3.6 m | Yellow |
| `4` | Phase | Ignores phase walls | Purple |

### Animation

Everything is procedural, with no animation resources:

- **Hands** are two separate arms with forearms and fists - no bar between
  them. Each class gets its own tool on the right hand (fist, coil, emitter,
  blade). They bob and sway with movement and sway back when you stop.
- **Parked shells** swing their arms and legs at a speed derived from their
  recorded motion, bob their torso, tilt their head and pulse their eye.
- **Plates** breathe with a brighter emissive pulse and a slight ring scale
  when lit. The gold core spins and hovers.
- **Doors** slide down into the floor instead of disappearing instantly.
- **Transfers** flash the screen in the current class colour and punch the FOV
  briefly. The ghost shader adds a flicker on top of the slow fade.

### Sector reference

| # | Name | New mechanic |
|---|------|--------------|
| 1 | Antechamber | Automatic plates, parking |
| 2 | Heavy Foundry | Anchor-only plate |
| 3 | Magnet Bay | Pull the core onto a plate |
| 4 | Phase Vault | Phase wall + Spark remote pad |

### Mouse handling

`_apply_mouse_mode()` is called on boot, on every room reset and after every
level load. On desktop it keeps the pointer captured, so crossing a door never
releases it. Only `Esc` unlocks the mouse, and the next left click captures it
again. On Web there is no pointer lock: `_apply_mouse_mode()` restores the drag
state from the actual left-button state, so looking keeps working across a
sector transition instead of needing a fresh click.

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
