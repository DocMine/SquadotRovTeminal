## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ForceVectorRenderer
extends Node3D

@export var force_scale: float = 0.012
@export var torque_scale: float = 0.02
@export var minimum_length_m: float = 0.05
@export var show_thruster: bool = true
@export var show_buoyancy: bool = true
@export var show_gravity: bool = true
@export var show_drag: bool = true
@export var show_net: bool = true
@export var show_torque: bool = true

@onready var mesh_instance: MeshInstance3D = %VectorMesh

var _mesh: ImmediateMesh = ImmediateMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
var _has_vertices: bool = false


func _ready() -> void:
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	mesh_instance.mesh = _mesh
	mesh_instance.material_override = _material


func set_snapshot(snapshot: RefCounted) -> void:
	_mesh.clear_surfaces()
	if snapshot == null:
		return
	_has_vertices = false
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
	var samples: Array[RefCounted] = snapshot.get("samples")
	for sample: RefCounted in samples:
		_draw_sample(sample)
	if _has_vertices:
		_mesh.surface_end()
	else:
		_mesh.clear_surfaces()


func _draw_sample(sample: RefCounted) -> void:
	var force_type: String = str(sample.get("force_type"))
	if not _is_force_visible(force_type):
		return
	var origin: Vector3 = sample.get("origin_m")
	var vector: Vector3 = sample.get("vector_n")
	var color: Color = sample.get("color")
	if vector.length() >= 0.01 and force_type != "torque":
		_draw_vector(origin, vector * force_scale, color)
	if show_torque:
		var torque: Vector3 = sample.get("torque_nm")
		if torque.length() >= 0.01:
			_draw_vector(origin, torque * torque_scale, Color(0.72, 0.3, 1.0, 1.0))


func _draw_vector(origin: Vector3, vector: Vector3, color: Color) -> void:
	var display_vector: Vector3 = vector
	if display_vector.length() < minimum_length_m:
		display_vector = display_vector.normalized() * minimum_length_m
	var end: Vector3 = origin + display_vector
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(origin)
	_has_vertices = true
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(end)
	var direction: Vector3 = display_vector.normalized()
	var side: Vector3 = direction.cross(Vector3.UP)
	if side.length() < 0.01:
		side = direction.cross(Vector3.RIGHT)
	side = side.normalized()
	var head_length: float = minf(0.18, maxf(0.06, display_vector.length() * 0.18))
	var wing_a: Vector3 = end - direction * head_length + side * head_length * 0.45
	var wing_b: Vector3 = end - direction * head_length - side * head_length * 0.45
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(end)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(wing_a)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(end)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(wing_b)


func _is_force_visible(force_type: String) -> bool:
	match force_type:
		"thruster":
			return show_thruster
		"buoyancy":
			return show_buoyancy
		"gravity":
			return show_gravity
		"drag":
			return show_drag
		"net":
			return show_net
		"torque":
			return show_torque
		_:
			return true
