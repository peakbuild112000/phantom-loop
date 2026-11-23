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
			c.radius = 0.07
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
