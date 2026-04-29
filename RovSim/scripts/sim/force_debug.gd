extends Node3D

## 力可视化调试（ForceDebug）
##
## 作用：
## - 在 3D 场景中用线段把关键外力画出来，便于调试仿真是否符合预期
## - 当前绘制：
##   - 推进器力（红色）
##   - 浮力（绿色，作用点在浮心）
##   - 线性阻尼力（蓝色，作用点在质心）
##
## 使用方式：
## - 把该节点放在场景合适位置（通常在 UI 或 Debug 组里）
## - enabled=false 时不绘制并清空 mesh
##
## 实现要点：
## - ImmediateMesh + PRIMITIVE_LINES：每帧重建线段
## - scale_m_per_n：把牛顿换算成“画线长度”（米/牛），避免线太短/太长

@export var enabled: bool = true
@export var scale_m_per_n: float = 0.01

var _sim: Node
var _mesh: ImmediateMesh
var _mi: MeshInstance3D
var _mat: StandardMaterial3D


func _ready() -> void:
	# 从相对路径找到 SimulationManager（场景结构变化时这里可能需要同步修改）
	_sim = get_node_or_null("../../SimulationManager")
	# 初始化用于绘制的 ImmediateMesh 与材质
	_mesh = ImmediateMesh.new()
	_mi = MeshInstance3D.new()
	_mi.mesh = _mesh
	add_child(_mi)
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true


func _process(_delta: float) -> void:
	# 这里放在 _process：调试绘制不必与物理帧严格同步
	if not enabled:
		if _mesh.get_surface_count() > 0:
			_mesh.clear_surfaces()
		return
	if _sim == null or _sim.rov == null:
		return
	_draw_forces(_sim.rov)


func _draw_forces(rov) -> void:
	# 每帧重建：先清空，再 begin/end 一次 surface
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _mat)

	# 推进器力：从推进器位置指向力方向
	for t in rov.get_thrusters():
		var p = t.global_transform.origin
		var f = t.get_force_global()
		_line(p, p + f * scale_m_per_n, Color(1.0, 0.2, 0.2))

	# 浮力：从浮心位置向上
	var cob_pos = rov.global_transform.origin + rov.global_transform.basis * rov.cob_offset_local_m
	_line(cob_pos, cob_pos + Vector3.UP * rov.buoyancy_n * scale_m_per_n, Color(0.2, 1.0, 0.2))

	# 阻尼：把速度变换到本地坐标系，按阻尼系数计算阻力，再变换回世界坐标绘制
	var v_local = rov.global_transform.basis.inverse() * rov.linear_velocity
	var drag_local = Vector3(
		-v_local.x * rov.drag_linear_local.x,
		-v_local.y * rov.drag_linear_local.y,
		-v_local.z * rov.drag_linear_local.z
	)
	var drag_global = rov.global_transform.basis * drag_local
	var p0 = rov.global_transform.origin
	_line(p0, p0 + drag_global * scale_m_per_n, Color(0.2, 0.4, 1.0))

	_mesh.surface_end()


func _line(a: Vector3, b: Vector3, c: Color) -> void:
	# 画一条带颜色的线段（两点）
	_mesh.surface_set_color(c)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(c)
	_mesh.surface_add_vertex(b)
