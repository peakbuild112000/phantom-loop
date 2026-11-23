# Code à copier (ne pas le laisser généré par l'IA)

> Ces blocs sont volontairement **dans un document**, pas dans les dossiers `scripts/`,
> `scenes/` et `shaders/`. Copie-les toi-même dans les fichiers indiqués : c'est ton
> travail de code, et c'est ce que Hackatime/Hackatime-compatible compte comme du temps.

Ordre recommandé : 1 → 2 → 3. Ensuite ouvre le projet dans Godot 4.6.1 et appuie sur F6.

---

## 1. `scripts/phantom_loop.gd`

```gdscript
extends Node3D

## PHANTOM LOOP — prototype central (Godot 4.6)
## À copier dans res://scripts/phantom_loop.gd
## À attacher au nœud racine de res://scenes/main.tscn

const LOOP_SECONDS := 30.0
const TICK := 1.0 / 60.0
const SPEED := 6.0
const MAX_GHOSTS := 4

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
var _label: Label
var _loops := 1
var _won := false

func _ready() -> void:
	_build_room()
	_build_player()
	_build_hud()
	_reset_room()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if _won:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	_acc += delta
	var steps := 0
	while _acc >= TICK and steps < 5:
		_step(TICK)
		_acc -= TICK
		steps += 1
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_player.rotate_y(-event.relative.x * 0.0025)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _step(dt: float) -> void:
	_time_left -= dt
	if _time_left <= 0.0:
		_finish_loop()
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var local := Vector3(input.x, 0.0, -input.y)
	var dir := (_player.global_transform.basis * local).normalized()
	_player.velocity.x = dir.x * SPEED
	_player.velocity.z = dir.z * SPEED
	_player.move_and_slide()
	_frames.append({
		"pos": _player.global_position,
		"action": Input.is_action_pressed("interact"),
	})

	for i in _ghosts.size():
		var frames: Array = _recordings[i]
		if frames.is_empty():
			continue
		if _cursors[i] >= frames.size():
			_cursors[i] = 0
		var f: Dictionary = frames[_cursors[i]]
		_ghosts[i].global_position = f["pos"]
		_ghosts[i].set_meta("action", f["action"])
		_cursors[i] += 1

	var all := true
	for plate in _plates:
		var active := false
		for body in plate.get_overlapping_bodies():
			if body == _player:
				active = true
			elif body is CharacterBody3D and body.has_meta("action") and body.get_meta("action"):
				active = true
		plate.set_meta("active", active)
		if not active:
			all = false
	_open_door(all)
	if all and _player.global_position.z < -8.2:
		_won = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _finish_loop() -> void:
	if _frames.size() > 2:
		if _recordings.size() < MAX_GHOSTS:
			_recordings.append(_frames.duplicate(true))
		else:
			_recordings[_loops % MAX_GHOSTS] = _frames.duplicate(true)
	_loops += 1
	_reset_room()

func _reset_room() -> void:
	_time_left = LOOP_SECONDS
	_acc = 0.0
	_frames.clear()
	_player.global_position = Vector3(0.0, 1.0, 7.0)
	_player.velocity = Vector3.ZERO
	_open_door(false)
	for g in _ghosts:
		g.queue_free()
	_ghosts.clear()
	_cursors.clear()
	for rec in _recordings:
		_ghosts.append(_make_ghost())
		_cursors.append(0)

func _make_ghost() -> CharacterBody3D:
	var g := CharacterBody3D.new()
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
	g.global_position = Vector3(0.0, 1.0, 7.0)
	add_child(g)
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
		_label.text = "ESCAPED in %d loops — press R to replay" % _loops
	else:
		_label.text = "PHANTOM LOOP  |  %04.1fs  |  loop %d  |  ghosts %d/%d  |  plates %d/%d\nWASD move · mouse look · E hold plate · Esc release" % [_time_left, _loops, _ghosts.size(), MAX_GHOSTS, active, _plates.size()]

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
	body.global_position = pos
	add_child(body)
	return body

func _make_plate(pos: Vector3) -> Area3D:
	var area := Area3D.new()
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
	shape.height = 0.5
	col.shape = shape
	area.add_child(col)
	area.global_position = pos
	add_child(area)
	_plates.append(area)
	return area

func _build_player() -> void:
	_player = CharacterBody3D.new()
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	col.shape = capsule
	_player.add_child(col)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.7, 0)
	_player.add_child(cam)
	_player.global_position = Vector3(0, 1, 7)
	add_child(_player)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(24, 24)
	_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(_label)
	add_child(canvas)
```

### Comment ça marche
- À chaque tick fixe (60 Hz), on stocke la position du joueur et l'état de `E`.
- Quand le timer expire, la liste est sauvegardée et rejouée par un fantôme.
- Un fantôme n'active une plaque **que si `E` était pressé** au moment de l'enregistrement.
- Le joueur active une plaque rien qu'en se tenant dessus. Il faut donc 2 fantômes + toi pour les 3 plaques.

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

## Vérification

```powershell
$godot = "C:\Users\PC\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe"
$project = "C:\Users\PC\Documents\project-1\phantom-loop"
& $godot --headless --path $project --editor --quit
& $godot --path $project
```

Si Godot râle sur un `uid`, supprime la ligne `uid="..."` eventuelle du `.tscn` : Godot la régénère.

## Améliorations à coder toi-même (idées)

- Remplacer le `SphereMesh` du fantôme par un vrai corps + traînée d'afterimages.
- Ajouter un `AudioStreamPlayer` dont la hauteur change à chaque boucle.
- Faire varier la disposition des plaques avec un `RandomNumberGenerator` seedé.
- Ajouter un deuxième type d'énigme : faisceau bloqué par un corps.
- Brancher le mode coop avec `tools/signaling_server.js` du projet Climb Together.
