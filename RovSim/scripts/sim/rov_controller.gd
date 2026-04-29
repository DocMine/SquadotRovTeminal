extends RigidBody3D
class_name ROVController

## ROV 物理控制器（ROVController）
##
## 这是 ROV 在场景中的实体（RigidBody3D），负责在每个物理帧施加外力：
## - 浮力（buoyancy_n），作用点可偏离质心（通过 cob_offset_local_m 模拟浮心）
## - 线性阻尼（drag_linear_local），在本地坐标系中按速度分量施加阻力
## - 推进器力（Thruster.get_force_global），在推进器位置施加力矩/力
##
## 重要约定：
## - 本脚本不直接做“控制算法”（比如 PID）。推进器的 command 值由外部系统设置。
## - 推进器节点应作为子节点挂在名为 "Thrusters" 的节点下，方便统一管理与遍历。

const ThrusterScript := preload("res://RovSim/scripts/sim/thruster.gd")

## 浮力大小（牛顿）。为 0 时不施加浮力。
@export var buoyancy_n: float = 80.0
## 浮心相对质心的本地偏移（米）。用于产生扶正力矩等效果。
@export var cob_offset_local_m: Vector3 = Vector3.ZERO
## 线性阻尼系数（本地坐标）。数值越大阻尼越强。
@export var drag_linear_local: Vector3 = Vector3(6.0, 6.0, 8.0)


func get_thrusters() -> Array:
	# 获取所有推进器节点（脚本类型为 ThrusterScript）
	var out: Array = []
	var thrusters_root = get_node_or_null("Thrusters")
	if thrusters_root == null:
		return out
	for c in thrusters_root.get_children():
		if c.get_script() == ThrusterScript:
			out.append(c)
	return out


func set_center_of_mass_offset_local(offset_m: Vector3) -> void:
	# 设置自定义质心偏移（本地坐标，单位：米）
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = offset_m


func _physics_process(_delta: float) -> void:
	# 物理帧主入口：按顺序施加各类力
	_apply_buoyancy()
	_apply_drag()
	_apply_thrusters()


func _apply_buoyancy() -> void:
	# 浮力：在浮心位置施加一个向上的力
	if buoyancy_n == 0.0:
		return
	var pos_global = global_transform.origin + global_transform.basis * cob_offset_local_m
	apply_force(Vector3.UP * buoyancy_n, pos_global - global_transform.origin)


func _apply_drag() -> void:
	# 阻尼：先把速度转换到本地坐标，按每个轴分别施加与速度相反的力
	if drag_linear_local == Vector3.ZERO:
		return
	var v_local = global_transform.basis.inverse() * linear_velocity
	var drag_local = Vector3(
		-v_local.x * drag_linear_local.x,
		-v_local.y * drag_linear_local.y,
		-v_local.z * drag_linear_local.z
	)
	var drag_global = global_transform.basis * drag_local
	apply_central_force(drag_global)


func _apply_thrusters() -> void:
	# 推进器：在推进器位置施加力（会同时产生力和力矩）
	for t in get_thrusters():
		var f = t.get_force_global()
		if f == Vector3.ZERO:
			continue
		apply_force(f, t.global_transform.origin - global_transform.origin)
