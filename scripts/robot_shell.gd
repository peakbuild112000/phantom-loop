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
