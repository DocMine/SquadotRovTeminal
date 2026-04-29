extends Node

## 设计评估器（DesignEvaluator）
##
## 作用：
## - 对当前 ROV 的配置给出一些“快速体检”式的提示文字
## - 结果是一个字符串数组（每行一条），通常用于 UI 直接展示
##
## 当前评估项（启发式规则，不是严格物理证明）：
## - 重心偏移是否过大（center_of_mass）
## - 当前姿态倾斜是否过大（roll/pitch）
## - 角速度是否过大（可能意味着不稳定）
## - 推进器数量是否为偶数（便于对称布局）
## - 推进器布局是否大致左右对称（x 轴镜像）
##
## 注意：
## - 这里的规则阈值通过 @export 暴露，便于在编辑器或运行时调参
## - 对称性检查只做“粗略匹配”，容差 tol 写在 _is_roughly_symmetric_x 内部

@export var com_warn_m: float = 0.15
@export var tilt_warn_deg: float = 60.0
@export var ang_vel_warn_radps: float = 6.0

var _sim: Node


func setup(simulation_manager: Node) -> void:
	# 注入仿真管理器（提供当前 rov 引用）
	_sim = simulation_manager


func evaluate() -> Array[String]:
	# 生成评估结果（每行一条字符串），供 UI 展示
	var out: Array[String] = []
	if _sim == null or _sim.rov == null:
		out.append("⚠ 未找到 ROV")
		return out
	var rov = _sim.rov
	# 1) 重心偏移：只有在 CUSTOM 模式下才有意义
	if rov.center_of_mass_mode == RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM and rov.center_of_mass.length() > com_warn_m:
		out.append("⚠ 重心偏移过大")
	else:
		out.append("✔ 重心偏移合理")

	# 2) 姿态倾斜：用欧拉角展示 roll/pitch 的绝对值是否超过阈值
	var e = rov.global_transform.basis.get_euler()
	var roll_deg = rad_to_deg(e.z)
	var pitch_deg = rad_to_deg(e.x)
	if absf(roll_deg) > tilt_warn_deg or absf(pitch_deg) > tilt_warn_deg:
		out.append("⚠ 姿态倾斜过大")
	else:
		out.append("✔ 姿态倾斜可接受")

	# 3) 角速度：角速度过大通常意味着控制/阻尼参数不合适
	if rov.angular_velocity.length() > ang_vel_warn_radps:
		out.append("⚠ 角速度过大（可能不稳定）")
	else:
		out.append("✔ 角速度可接受")

	# 4) 推进器数量：偶数更容易做对称布置（不是硬性要求）
	var thr = rov.get_thrusters()
	if thr.size() % 2 != 0:
		out.append("⚠ 推进器数量非偶数")
	else:
		out.append("✔ 推进器数量为偶数")

	# 5) 大致对称性：检查每个推进器是否能在 x 轴镜像位置找到配对
	if not _is_roughly_symmetric_x(thr):
		out.append("⚠ 推进器布局可能不对称")
	else:
		out.append("✔ 推进器布局大致对称")

	return out


func _is_roughly_symmetric_x(thrusters: Array) -> bool:
	# 粗略对称检查：
	# - 对每个推进器 a，寻找一个未使用的推进器 b，使得 a 与 b 的位置满足：
	#   x 坐标互为相反数（ap.x + bp.x ≈ 0），y/z 坐标相近（ap.y ≈ bp.y, ap.z ≈ bp.z）
	# - 使用 tol 作为容差（单位：米）
	var tol = 0.08
	var used = {}
	for i in thrusters.size():
		if used.has(i):
			continue
		var a = thrusters[i]
		var found = false
		for j in thrusters.size():
			if i == j or used.has(j):
				continue
			var b = thrusters[j]
			var ap = a.position
			var bp = b.position
			if absf(ap.x + bp.x) <= tol and absf(ap.y - bp.y) <= tol and absf(ap.z - bp.z) <= tol:
				used[i] = true
				used[j] = true
				found = true
				break
		if not found:
			return false
	return true
