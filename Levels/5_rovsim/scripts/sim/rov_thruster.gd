## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ROVThruster
extends Node3D

const ThrusterStateScript = preload("res://Levels/5_rovsim/scripts/sim/thruster_state.gd")
const ThrusterTemplateScript = preload("res://Levels/5_rovsim/scripts/model/thruster_template.gd")

@export var thruster_id: int = 0
@export var display_name: String = "T"
@export var max_thrust_n: float = 35.0
@export var command: float = 0.0
@export var local_force_axis: Vector3 = Vector3(0.0, 0.0, -1.0)
@export var is_selected: bool = false

var current_thrust_n: float = 0.0
var template: RefCounted = ThrusterTemplateScript.new()
@onready var body_mesh: MeshInstance3D = %ThrusterBody
@onready var axis_mesh: MeshInstance3D = %ForceAxis


func _ready() -> void:
	update_visuals()


func set_command(value: float) -> void:
	command = clampf(value, -1.0, 1.0)
	if template != null:
		current_thrust_n = float(template.call("evaluate_thrust", command))
	else:
		current_thrust_n = command * max_thrust_n
	update_visuals()


func apply_template(thruster_template: RefCounted) -> void:
	template = thruster_template.call("duplicate_template")
	max_thrust_n = float(template.get("max_forward_thrust_n"))
	local_force_axis = template.get("force_axis_local")
	update_visuals()


func set_selected(value: bool) -> void:
	is_selected = value
	update_visuals()


func get_force_world() -> Vector3:
	var axis: Vector3 = local_force_axis.normalized()
	return global_transform.basis * axis * current_thrust_n


func get_state() -> RefCounted:
	var state: RefCounted = ThrusterStateScript.new()
	state.id = thruster_id
	state.display_name = display_name
	state.command = command
	state.thrust_n = current_thrust_n
	state.max_thrust_n = max_thrust_n
	state.position_m = global_position
	state.force_world_n = get_force_world()
	return state


func update_visuals() -> void:
	if axis_mesh == null:
		return
	var intensity: float = absf(command)
	if body_mesh != null and template != null:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		if is_selected:
			material.albedo_color = Color(1.0, 0.72, 0.22, 1.0)
		else:
			material.albedo_color = template.get("body_color")
		body_mesh.set_surface_override_material(0, material)
	if axis_mesh != null and template != null:
		var axis_material: StandardMaterial3D = StandardMaterial3D.new()
		axis_material.albedo_color = template.get("axis_color")
		axis_mesh.set_surface_override_material(0, axis_material)
	axis_mesh.scale = Vector3(1.0, 1.0, 0.45 + intensity * 0.8)
	if command >= 0.0:
		axis_mesh.position = Vector3(0.0, 0.0, -0.35 - intensity * 0.2)
	else:
		axis_mesh.position = Vector3(0.0, 0.0, 0.35 + intensity * 0.2)
