# Code to copy

> These blocks are intentionally kept in a document, **not** in `scripts/`,
> `scenes/` or `shaders/`. Copy them yourself into the paths shown below:
> it is your own coding time, and this is what Hackatime counts.

Order: 1 → 2 → 3. Then open the project in Godot 4.6.1 and press F6.

---

## 1. `scripts/phantom_loop.gd`

```gdscript
extends Node3D

## PHANTOM LOOP - central prototype (Godot 4.6)
## Copy to res://scripts/phantom_loop.gd
## Attach to the root Node3D of res://scenes/main.tscn

const LOOP_SECONDS := 30.0
const TICK := 1.0 / 60.0
const SPEED := 6.0
const MAX_GHOSTS := 3

var _time_left := LOOP_SECONDS
var _acc := 0.0
var _frames: Array[Dictionary] = []
var _recordings: Array[Array] = []
var _ghosts: Array[CharacterBody3D] = []
var _cursors: Array[int] = []
var _plates: Array[Area3D] = []
var _door: StaticBody3D
var _door_col: CollisionShape3D
var _player: CharacterBody3D
var _cam: Camera3D
var _label: Label
var _skip_button: Button
var _loops := 1
var _won := false
var _door_latched := false
var _pitch := 0.0
var _dragging := false

func _ready() -> void:
	_build_room()
	_build_player()
	_build_hud()
	_reset_room()
	# On Web we use click-drag look: no pointer lock, so the skip button stays clickable.
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
	var look := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if OS.has_feature("web"):
		look = _dragging
	if event is InputEventMouseMotion and look:
		_player.rotate_y(-event.relative.x * 0.0025)
		_pitch = clampf(_pitch - event.relative.y * 0.0025, -1.2, 1.2)
		_cam.rotation.x = _pitch
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if OS.has_feature("web"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventKey and event.keycode == KEY_ENTER and event.pressed and not _won:
		_finish_loop()

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
	_frames.append({
		"pos": _player.global_position,
		"action": Input.is_action_pressed("interact"),
	})

	# Docking on a plate transfers the pilot into a fresh shell right away.
	if Input.is_action_just_pressed("interact") and _on_plate(_player.global_position):
		_finish_loop()
		return

	for i in _ghosts.size():
		var frames: Array = _recordings[i]
		if frames.is_empty():
			continue
		if _cursors[i] >= frames.size():
			_cursors[i] = frames.size() - 1  # abandoned shell freezes on its plate
		var f: Dictionary = frames[_cursors[i]]
		_ghosts[i].global_position = f["pos"]
		_ghosts[i].set_meta("action", f["action"])
		_ghosts[i].visible = _ghosts[i].global_position.distance_to(_player.global_position) > 1.4
		_cursors[i] += 1

	var all := true
	for plate in _plates:
		# Deterministic position check instead of Area3D overlaps: no physics-frame
		# lag, works identically on desktop and Web.
		var active := _touches_plate(_player.global_position, plate)
		if not active:
			for i in _ghosts.size():
				var g := _ghosts[i]
				if not (g.has_meta("action") and g.get_meta("action")):
					continue
				if _touches_plate(g.global_position, plate):
					active = true
					break
		plate.set_meta("active", active)
		if not active:
			all = false
	if all:
		_door_latched = true
	_open_door(_door_latched)
	if _door_latched and _player.global_position.z < -8.2:
		_won = true
		_dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _finish_loop() -> void:
	if _won:
		return
	if _frames.size() > 2 and _recordings.size() < MAX_GHOSTS:
		_recordings.append(_frames.duplicate(true))
	_loops += 1
	_reset_room()

func _on_skip_pressed() -> void:
	_finish_loop()

func _touches_plate(pos: Vector3, plate: Area3D) -> bool:
	var p := plate.global_position
	if absf(pos.y - p.y) > 1.5:
		return false
	return Vector2(pos.x - p.x, pos.z - p.z).length() < 1.1

func _on_plate(pos: Vector3) -> bool:
	for plate in _plates:
		if _touches_plate(pos, plate):
			return true
	return false

func _reset_room() -> void:
	_time_left = LOOP_SECONDS
	_acc = 0.0
	_frames.clear()
	_door_latched = false
	_pitch = 0.0
	_cam.rotation.x = 0.0
	_player.rotation.y = 0.0  # always face the room, never the back wall
	_player.global_position = Vector3(0.0, 1.0, 7.0)
	_player.velocity = Vector3.ZERO
	_open_door(false)
	for g in _ghosts:
		g.queue_free()
	_ghosts.clear()
	_cursors.clear()
	for rec in _recordings:
		var g := _make_ghost()
		if not rec.is_empty():
			g.global_position = rec[0]["pos"]
		_ghosts.append(g)
		_cursors.append(0)

func _make_ghost() -> CharacterBody3D:
	var g := CharacterBody3D.new()
	# Layer 2, mask 0: plates detect ghosts, but ghosts never push the player.
	g.collision_layer = 2
	g.collision_mask = 0
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	var col := CollisionShape3D.new()
	col.shape = shape
	g.add_child(col)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	mesh.mesh = sphere
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ghost.gdshader") as Shader
	mesh.material_override = mat
	g.add_child(mesh)
	add_child(g)
	g.global_position = Vector3(0.0, 1.0, 7.0)
	return g

func _open_door(open: bool) -> void:
	_door.visible = not open
	_door_col.disabled = open

func _update_hud() -> void:
	var active := 0
	for p in _plates:
		if p.has_meta("active") and p.get_meta("active"):
			active += 1
	if _won:
		_label.text = "ESCAPED in %d shells - press R to replay" % _loops
	else:
		var msg := "PHANTOM PROTOCOL  |  %04.1fs  |  shell %d/%d  |  parked shells %d/%d  |  plates %d/%d\nYou are the pilot. Drive a shell onto a plate, press E to dock, then pilot the next one.\nEnter or the button = transfer now - Web: drag mouse to look." % [_time_left, mini(_loops, MAX_GHOSTS + 1), MAX_GHOSTS + 1, _ghosts.size(), MAX_GHOSTS, active, _plates.size()]
		if _recordings.size() >= MAX_GHOSTS:
			msg += "\nNO SHELLS LEFT - press R to restart"
		_label.text = msg

func _build_room() -> void:
	var dark := Color(0.07, 0.08, 0.13)
	var floor_col := Color(0.14, 0.16, 0.24)
	_box(Vector3(0, -0.3, 0), Vector3(22, 0.6, 22), floor_col)
	_box(Vector3(0, 4, -10.5), Vector3(22, 9, 1), dark)
	_box(Vector3(0, 4, 10.5), Vector3(22, 9, 1), dark)
	_box(Vector3(-10.5, 4, 0), Vector3(1, 9, 22), dark)
	_box(Vector3(10.5, 4, 0), Vector3(1, 9, 22), dark)

	_door = _box(Vector3(0, 1.5, -10.0), Vector3(4, 3, 0.5), Color(0.95, 0.55, 0.2))
	_door_col = _door.get_child(1) as CollisionShape3D

	_make_plate(Vector3(-4.0, 0.12, -2.0))
	_make_plate(Vector3(4.0, 0.12, -5.0))
	_make_plate(Vector3(0.0, 0.12, 2.5))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	add_child(light)
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.3, 0.45)
	ambient.environment = env
	add_child(ambient)

func _box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	body.global_position = pos
	return body

func _make_plate(pos: Vector3) -> Area3D:
	var area := Area3D.new()
	area.collision_mask = 3  # see player layer 1 and parked shells on layer 2
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.8
	cyl.bottom_radius = 0.8
	cyl.height = 0.16
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.9)
	mesh.material_override = mat
	area.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.9
	# Tall trigger: ghosts are spheres centred at torso height (~1 m).
	shape.height = 2.0
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.global_position = pos
	_plates.append(area)
	return area

func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.collision_layer = 1
	_player.collision_mask = 1
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	col.shape = capsule
	_player.add_child(col)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0.7, 0)
	_player.add_child(_cam)
	add_child(_player)
	_player.global_position = Vector3(0, 1, 7)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(24, 24)
	_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(_label)
	_skip_button = Button.new()
	_skip_button.text = "SKIP LOOP / TRANSFER BODY  [Enter]"
	_skip_button.position = Vector2(24, 116)
	_skip_button.size = Vector2(360, 40)
	_skip_button.pressed.connect(_on_skip_pressed)
	canvas.add_child(_skip_button)
	add_child(canvas)
```

### Lore and how it works

You are not the robot. You are the **pilot** jumping between robot shells in a
derelict facility. A shell you abandon does not disappear: it stays behind,
replays its last route and keeps holding whatever it was holding. That is the
only way to be in several places at once.

- Every 60 Hz tick, the current shell's position and the state of `E` are recorded.
- Stand on a plate and press `E` to **dock** the shell. The pilot transfers into a
  fresh shell at the entry point; the old one becomes a parked ghost on the plate.
- The `SKIP LOOP / TRANSFER BODY` button (or `Enter`) transfers immediately
  without docking. The timer expiry also forces a transfer.
- A ghost replays its recording and then **freezes at its final position**, so it
  keeps holding the plate forever instead of walking away.
- You light a plate just by standing on it. You need 2 parked shells + yourself
  for the 3 plates. Once all plates are lit, the door stays open for the loop.
  Plates are checked by direct XZ distance, so a ghost holding a plate always
  counts - no physics-frame lag or missed trigger volume.
- **Shell limit:** at most 3 ghosts can be parked (`MAX_GHOSTS`). Further
  transfers still reset the timer but do not create a new ghost, and the HUD
  shows `NO SHELLS LEFT - press R to restart`.
- Every new shell spawns facing the room, never the back wall.
- On Web, hold the **left mouse button and drag** to look around (no pointer
  lock, so the skip button stays clickable). On desktop the mouse is captured;
  `Esc` releases it.
- Parked shells live on collision layer 2 with mask 0: plates still detect them,
  but they can never push the player out of the room.

---

## 2. `shaders/ghost.gdshader`

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

## 3. `scenes/main.tscn`

```gdscene
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/phantom_loop.gd" id="1_phantom"]

[node name="Main" type="Node3D"]
script = ExtResource("1_phantom")
```

---

## Verification

```powershell
$godot = "C:\Users\PC\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe"
$project = "C:\Users\PC\Documents\project-1\phantom-loop"
& $godot --headless --path $project --editor --quit
& $godot --path $project
```

## Planned robot classes (future levels)

The lore is meant to grow into a class system. Each shell type should have one
distinct ability, so later rooms ask you to combine them:

| Shell | Ability | Puzzle use |
|-------|---------|------------|
| **Anchor** (current one) | Heavy, can lock a plate with `E` | Holds switches in place |
| **Magnet** | Pulls nearby metal props toward itself | Bridges gaps, drags keys |
| **Spark** | Short burst that stuns drones / lights terminals | Disables hazards, activates remote panels |
| **Mimer** | Copies the last movement of the previously parked shell | Repeats a timed route without you |
| **Phase** | Walks through one thin wall per level | Reaches isolated switch rooms |

Implementation hint: add a `class_name` enum to the shell scene and store it in
each recording alongside `pos` and `action`. The replay code then reads the
class and calls the matching ability instead of only moving the ghost.

## Other ideas to build next

- Replace the ghost sphere with a real robot mesh plus afterimage trail.
- Add an `AudioStreamPlayer` whose pitch shifts on every transfer.
- Randomize plate positions with a seeded `RandomNumberGenerator`.
- Add a second puzzle type: a beam blocked by a body.
- Hook up co-op using the signaling server from the Climb Together project.
