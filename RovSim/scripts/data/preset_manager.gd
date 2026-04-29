extends Node

## 预设管理器（PresetManager）
##
## 作用：
## - 从 resources/presets/*.json 读取预设配置
## - 生成/替换场景中的 ROV 实例
## - 把预设中的 ROV 参数（质量、浮力、阻尼、重心/浮心偏移等）应用到 ROV
## - 按预设创建推进器节点（Thruster），并挂到 ROV/Thrusters 节点下
## - 把当前 ROV 设置到 SimulationManager，使仿真使用新的配置
##
## 预设 JSON 结构（概念上）：
## {
##   "rov": { "mass": ..., "buoyancy_n": ..., "drag_linear_local": [x,y,z], ... },
##   "thrusters": [
##     { "id": 0, "name": "...", "position_m": [x,y,z], "rotation_deg":[rx,ry,rz], "max_thrust_n": 30.0 },
##     ...
##   ]
## }
##
## 实现要点：
## - 每次 load_preset 都会清空 _rov_root 下的旧 ROV，然后实例化 rov.tscn
## - 推进器也是“清空后重建”，保证与预设一致

const PRESET_DIR := "res://RovSim/resources/presets"
const ROV_SCENE := "res://RovSim/scenes/rov/rov.tscn"
const ThrusterScript := preload("res://RovSim/scripts/sim/thruster.gd")

var _rov_root: Node3D
var _sim: Node
var _rov_scene: PackedScene
var _current_rov


func setup(rov_root: Node3D, simulation_manager: Node) -> void:
	# 注入 ROV 挂载根节点与仿真管理器，并预加载 ROV 场景
	_rov_root = rov_root
	_sim = simulation_manager
	_rov_scene = load(ROV_SCENE)


func get_current_rov():
	# 返回当前正在仿真/显示的 ROV 实例（可能为 null）
	return _current_rov


func list_presets() -> Array[String]:
	# 当前是硬编码列表；如果后续想自动发现，可以扫描 PRESET_DIR 目录。
	return ["stable", "unstable", "high_thrust"]


func load_preset(preset_name: String) -> void:
	# 读取 json 并应用到新生成的 ROV 上
	var path = "%s/%s.json" % [PRESET_DIR, preset_name]
	var d = _read_json(path)
	if d.is_empty():
		return
	var rov = _spawn_rov()
	_apply_rov_params(rov, d.get("rov", {}))
	_apply_thrusters(rov, d.get("thrusters", []))
	_current_rov = rov
	# 通知仿真管理器切换 ROV，使后续 get_current_state 等都来自新实例
	_sim.set_rov(rov)


func _spawn_rov():
	# 清空挂载点并实例化新的 ROV
	for c in _rov_root.get_children():
		c.queue_free()
	var inst = _rov_scene.instantiate()
	_rov_root.add_child(inst)
	return inst


func _apply_rov_params(rov, d: Dictionary) -> void:
	# 把 json 字段映射到 ROV 节点的属性（字段缺失则保持默认）
	if d.has("mass"):
		rov.mass = float(d["mass"])
	if d.has("buoyancy_n"):
		rov.buoyancy_n = float(d["buoyancy_n"])
	if d.has("drag_linear_local"):
		var a = d["drag_linear_local"]
		rov.drag_linear_local = Vector3(float(a[0]), float(a[1]), float(a[2]))
	if d.has("cob_offset_local_m"):
		var c = d["cob_offset_local_m"]
		rov.cob_offset_local_m = Vector3(float(c[0]), float(c[1]), float(c[2]))
	if d.has("com_offset_local_m"):
		var com = d["com_offset_local_m"]
		rov.set_center_of_mass_offset_local(Vector3(float(com[0]), float(com[1]), float(com[2])))


func _apply_thrusters(rov, arr: Array) -> void:
	# 在 ROV 的 Thrusters 子节点下“清空后重建”推进器
	var root = rov.get_node_or_null("Thrusters")
	if root == null:
		return
	for c in root.get_children():
		c.queue_free()
	for item in arr:
		var t = ThrusterScript.new()
		t.id = int(item.get("id", 0))
		t.name = str(item.get("name", "Thruster"))
		var p = item.get("position_m", [0.0, 0.0, 0.0])
		t.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		var r = item.get("rotation_deg", [0.0, 0.0, 0.0])
		t.rotation_degrees = Vector3(float(r[0]), float(r[1]), float(r[2]))
		t.max_thrust_n = float(item.get("max_thrust_n", 30.0))
		root.add_child(t)


func _read_json(path: String) -> Dictionary:
	# 读取并解析 json；失败时返回空字典
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text = f.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
