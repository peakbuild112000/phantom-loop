extends Node3D

## PHANTOM LOOP - main controller (Godot 4.6.1).
## You are the pilot. Park shells to hold plates, then move to the next sector.

const TICK := 1.0 / 60.0
const SPEED := 6.0
const GRAVITY := 18.0
const JUMP_SPEED := 8.0
const FOOTSTEP_DISTANCE := 1.7
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
var _movers: Array[Dictionary] = []
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
var _jump_queued := false
var _was_on_floor := true
var _foot_acc := 0.0
var _foot_flip := false
var _audio: Dictionary = {}
var _hud: CanvasLayer
var _menu: CanvasLayer
var _menu_title: Label
var _in_menu := true

func _ready() -> void:
	_levels = LevelData.all()
	_build_player()
	_build_audio()
	_build_hud()
	_build_menu()
	_load_level(0)
	_set_menu(true)

func _apply_mouse_mode() -> void:
	# Called on boot AND after every level load / transfer: the mouse must never
	# silently stay unlocked when a new sector starts.
	if _in_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_dragging = false
		return
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

func _set_menu(show: bool) -> void:
	_in_menu = show
	_menu.visible = show
	_hud.visible = not show
	_jump_queued = false
	_dragging = false
	_apply_mouse_mode()

func _start_game() -> void:
	if not _in_menu:
		return
	_set_menu(false)
	_play("ui")

func _restart_level() -> void:
	# R repeats the sector you are in, not the whole run.
	var idx := _level_idx
	_load_level(idx)
	_set_menu(false)
	_play("ui")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_restart_level()
		return
	if _in_menu or _won or _game_over or _transition > 0.0:
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
	if _in_menu:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_start_game()
		return
	if event is InputEventKey and event.pressed and not event.echo:
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
			KEY_SPACE:
				_jump_queued = true
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
	# Gravity + one-shot jump, consumed on the exact fixed step we land on.
	if _player.is_on_floor():
		if _jump_queued:
			_player.velocity.y = JUMP_SPEED
			_play("jump")
		else:
			_player.velocity.y = 0.0
		_jump_queued = false
	else:
		_player.velocity.y -= GRAVITY * dt
	var before := _player.global_position
	_player.move_and_slide()
	var grounded := _player.is_on_floor()
	if grounded and not _was_on_floor:
		_play("land")
	_was_on_floor = grounded
	# Footsteps are distance-based, so they stay in sync on Web and desktop.
	var walked := Vector2(_player.global_position.x - before.x, _player.global_position.z - before.z).length()
	if grounded and walked > 0.001:
		_foot_acc += walked
		if _foot_acc >= FOOTSTEP_DISTANCE:
			_foot_acc -= FOOTSTEP_DISTANCE
			_play("step_a" if not _foot_flip else "step_b")
			_foot_flip = not _foot_flip
	elif not grounded:
		_foot_acc = 0.0
	for m in _movers:
		(m["body"] as Node3D).global_position = m["base"] + _mover_offset(m, _elapsed)
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
			active = _key != null and _near(_key.global_position, pos, radius)
		else:
			if _class_matches(need, _current_class) and _near(_player.global_position, pos, radius):
				active = true
			if not active:
				for i in _ghosts.size():
					if _class_matches(need, _ghost_classes[i]) and _near(_ghosts[i].global_position, pos, radius):
						active = true
						break
		if active and not bool(plate.get("was_active", false)):
			_play("plate")
		plate["was_active"] = active
		plate["active"] = active
		var mat: StandardMaterial3D = plate["mat"]
		mat.albedo_color = Color(0.35, 1.0, 0.85) if active else plate["off_color"]
		mat.emission_energy_multiplier = 2.0 if active else 0.25
		if not active:
			all = false
	if all and not _door_latched:
		_door_latched = true
		_play("door")
	_open_door(_door_latched)

func _class_matches(need: int, cls: int) -> bool:
	return need == NEED_ANY or need == cls

func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _near(a: Vector3, b: Vector3, radius: float) -> bool:
	# Height matters for the new elevated pads: standing under one must not count.
	return absf(a.y - b.y) < 1.4 and _flat_dist(a, b) < radius

func _mover_offset(m: Dictionary, t: float) -> Vector3:
	var off := Vector3.ZERO
	var v := sin(t * float(m["speed"]) + float(m["phase"])) * float(m["amp"])
	match String(m["axis"]):
		"x": off.x = v
		"y": off.y = v
		"z": off.z = v
	return off

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
		_play("lose")
		_flash.color = Color(0.75, 0.06, 0.12, 0.3)
		_flash_alpha = 0.3
		_update_hud()
		return
	if _frames.size() > 2:
		_recordings.append(_frames.duplicate(true))
	_play("transfer")
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
	_jump_queued = false
	_was_on_floor = true
	_foot_acc = 0.0
	for m in _movers:
		(m["body"] as Node3D).global_position = m["base"] + _mover_offset(m, 0.0)
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
		plate["was_active"] = false
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
	_play("ui")
	_update_hud()

func _win() -> void:
	_won = true
	_play("win")
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
		# All sectors cleared: offer the menu again instead of a silent reload.
		_menu_title.text = "RUN COMPLETE"
		_set_menu(true)

func _load_level(idx: int) -> void:
	_level_idx = idx
	for n in _level_nodes:
		n.queue_free()
	_level_nodes.clear()
	_plates.clear()
	_movers.clear()
	_recordings.clear()
	_loops = 1
	_won = false
	_game_over = false
	_transition = 0.0
	_key = null
	var level: Dictionary = _levels[idx]
	_build_room()
	for w in level.get("walls", []):
		var wall_color := Color(0.18, 0.20, 0.32)
		if w.has("color"):
			wall_color = Color.html(String(w["color"]))
		if w.get("phase", false):
			wall_color = Color(0.55, 0.30, 0.90)
		_box(w["pos"], w["size"], wall_color, 3 if w.get("phase", false) else 1)
	for m in level.get("movers", []):
		var body := _box(m["pos"], m["size"], Color(0.90, 0.22, 0.26), 1)
		_movers.append({
			"body": body,
			"base": m["pos"],
			"axis": m.get("axis", "y"),
			"amp": m.get("amp", 1.0),
			"speed": m.get("speed", 1.0),
			"phase": m.get("phase", 0.0),
		})
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
		msg = "GAME OVER - OUT OF COPIES\nPress R to repeat this sector"
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
	_hud = canvas
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

func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.layer = 10
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.02, 0.03, 0.08, 0.94),
		Color(0.10, 0.04, 0.20, 0.86),
		Color(0.02, 0.02, 0.05, 0.96),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	bg.texture = tex
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(bg)
	var edge := ColorRect.new()
	edge.set_anchors_preset(Control.PRESET_CENTER)
	edge.position = Vector2(-362.0, -232.0)
	edge.size = Vector2(724.0, 464.0)
	edge.color = Color(0.25, 1.0, 0.90, 0.35)
	_menu.add_child(edge)
	var frame := ColorRect.new()
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.position = Vector2(-360.0, -230.0)
	frame.size = Vector2(720.0, 460.0)
	frame.color = Color(0.03, 0.05, 0.11, 0.72)
	_menu.add_child(frame)
	_menu_title = Label.new()
	_menu_title.text = "PHANTOM LOOP"
	_menu_title.set_anchors_preset(Control.PRESET_CENTER)
	_menu_title.position = Vector2(-320.0, -196.0)
	_menu_title.size = Vector2(640.0, 90.0)
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 58)
	_menu_title.add_theme_color_override("font_color", Color(0.45, 1.0, 0.92))
	_menu.add_child(_menu_title)
	var sub := Label.new()
	sub.text = "TIME-LOOP ESCAPE  //  PILOT THE SHELLS"
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.position = Vector2(-320.0, -112.0)
	sub.size = Vector2(640.0, 40.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 19)
	sub.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_menu.add_child(sub)
	var info := Label.new()
	info.text = "WASD move   SPACE jump   Mouse look (drag on Web)\n1-4 choose class   E / Enter transfer   R repeat sector\nPark shells on plates, then cross the door."
	info.set_anchors_preset(Control.PRESET_CENTER)
	info.position = Vector2(-320.0, -48.0)
	info.size = Vector2(640.0, 110.0)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0))
	_menu.add_child(info)
	var start := Button.new()
	start.text = "START SHIFT  [Enter]"
	start.set_anchors_preset(Control.PRESET_CENTER)
	start.position = Vector2(-160.0, 92.0)
	start.size = Vector2(320.0, 54.0)
	start.pressed.connect(_start_game)
	_menu.add_child(start)
	var footer := Label.new()
	footer.text = "3 COPIES PER SECTOR  //  NO TIMER  //  0 COPIES = GAME OVER"
	footer.set_anchors_preset(Control.PRESET_CENTER)
	footer.position = Vector2(-340.0, 182.0)
	footer.size = Vector2(680.0, 34.0)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(1.0, 0.72, 0.40))
	_menu.add_child(footer)
	add_child(_menu)

func _build_audio() -> void:
	_audio["step_a"] = _make_player(_synth(110.0, 0.09, 0.85, 30.0, -0.3), -9.0)
	_audio["step_b"] = _make_player(_synth(85.0, 0.10, 0.82, 28.0, -0.4), -9.0)
	_audio["jump"] = _make_player(_synth(260.0, 0.16, 0.12, 9.0, 1.1), -7.0)
	_audio["land"] = _make_player(_synth(130.0, 0.14, 0.50, 18.0, -0.5), -8.0)
	_audio["plate"] = _make_player(_synth(720.0, 0.18, 0.05, 8.0, 0.2), -6.0)
	_audio["door"] = _make_player(_synth(150.0, 0.45, 0.25, 3.5, -0.6), -6.0)
	_audio["transfer"] = _make_player(_synth(320.0, 0.30, 0.20, 6.0, 1.8), -7.0)
	_audio["win"] = _make_player(_synth(440.0, 0.55, 0.04, 2.5, 1.6), -5.0)
	_audio["lose"] = _make_player(_synth(220.0, 0.60, 0.25, 2.5, -0.8), -5.0)
	_audio["ui"] = _make_player(_synth(900.0, 0.06, 0.03, 30.0, 0.0), -12.0)

func _make_player(stream: AudioStream, db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = db
	add_child(player)
	return player

func _play(name: String) -> void:
	var player: AudioStreamPlayer = _audio.get(name)
	if player != null:
		player.play()

func _shutdown_audio() -> void:
	# Used by the headless smoke test before quit() so the audio server has no
	# live playbacks when the process tears down.
	for key in _audio.keys():
		var player: AudioStreamPlayer = _audio[key]
		player.stop()
		player.stream = null
	_audio.clear()

func _synth(freq: float, dur: float, noise: float, decay: float, sweep: float) -> AudioStreamWAV:
	# Tiny procedural PCM samples: no external audio assets in the export.
	var rate := 22050
	var count := int(float(rate) * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var rng_state := 987654321
	for i in range(count):
		var t := float(i) / float(rate)
		var env: float = exp(-decay * t) * clampf(1.0 - t / dur, 0.0, 1.0)
		var f := freq * (1.0 + sweep * t)
		phase += 6.2831853 * f / float(rate)
		rng_state = (rng_state * 1103515245 + 12345) & 0x7fffffff
		var rnd := float(rng_state) / 1073741824.0 - 1.0
		var wave := sin(phase) * (1.0 - noise) + rnd * noise
		var v := int(clampf(wave * env * 0.7, -1.0, 1.0) * 32000.0)
		data[i * 2] = v & 0xff
		data[i * 2 + 1] = (v >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
