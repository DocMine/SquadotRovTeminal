extends Control

## 运行时构建/调参面板（Runtime Builder Panel）
##
## 这是一个“把很多功能集合在一起”的 UI 控制面板，面向交互式调参：
## - 预设：选择并加载 Preset（调用 PresetManager）
## - 推进器编辑：
##   - 全局指令（给所有推进器设置相同 command）
##   - 推进器列表（选择一个推进器）
##   - Inspector（编辑单个推进器的 command/max/position/rotation）
##   - 增删推进器（运行时创建/删除 Thruster 节点）
## - 录制/回放：
##   - Start/Stop Rec（调用 DataRecorder）
##   - Clear（清空录制缓存）
##   - Play/Stop（调用 PlaybackManager，使用全量录制帧）
##   - Save/Load JSON（使用 RecordingIO 保存/加载 user://recording.json）
## - 评估：
##   - Evaluate（调用 DesignEvaluator.evaluate 并把文本输出到 UI）
##
## 工作流程（入门最推荐看的部分）：
## 1) Main._ready() 调用 setup(...) 给本面板注入依赖模块
## 2) setup 只会“连一次信号”（用 _wired 防止重复连接）
## 3) 用户操作 UI -> 对应 _on_xxx 回调 -> 调用后端模块/修改推进器属性
## 4) 操作后通常调用 _refresh_thruster_list() 让列表显示最新值
##
## 实现要点：
## - Inspector 的 SpinBox 会触发 value_changed 信号。为了避免“加载 Inspector 时”
##   也触发写回，我们用 _updating_inspector 作为保护开关。

const ThrusterScript := preload("res://RovSim/scripts/sim/thruster.gd")
const RecordingIOScript := preload("res://RovSim/scripts/data/recording_io.gd")

var _preset_manager: Node
var _sim: Node
var _rec: Node
var _playback: Node
var _evaluator: Node

@onready var _preset_select: OptionButton = $Margin/Root/PresetRow/PresetSelect
@onready var _load_preset: Button = $Margin/Root/PresetRow/LoadPreset
@onready var _global_cmd: HSlider = $Margin/Root/GlobalCommandRow/GlobalCommand
@onready var _thruster_list: ItemList = $Margin/Root/ThrusterList
@onready var _add_thruster: Button = $Margin/Root/ThrusterButtons/AddThruster
@onready var _del_thruster: Button = $Margin/Root/ThrusterButtons/DeleteThruster

@onready var _cmd_spin: SpinBox = $Margin/Root/InspectorGrid/CmdSpin
@onready var _max_spin: SpinBox = $Margin/Root/InspectorGrid/MaxSpin
@onready var _pos_x: SpinBox = $Margin/Root/InspectorGrid/PosX
@onready var _pos_y: SpinBox = $Margin/Root/InspectorGrid/PosY
@onready var _pos_z: SpinBox = $Margin/Root/InspectorGrid/PosZ
@onready var _rot_x: SpinBox = $Margin/Root/InspectorGrid/RotX
@onready var _rot_y: SpinBox = $Margin/Root/InspectorGrid/RotY
@onready var _rot_z: SpinBox = $Margin/Root/InspectorGrid/RotZ

@onready var _rec_toggle: Button = $Margin/Root/OpsRow/RecToggle
@onready var _rec_clear: Button = $Margin/Root/OpsRow/RecClear
@onready var _play_toggle: Button = $Margin/Root/OpsRow/PlayToggle
@onready var _rec_save: Button = $Margin/Root/OpsRow/SaveJSON
@onready var _rec_load: Button = $Margin/Root/OpsRow/LoadJSON
@onready var _eval_button: Button = $Margin/Root/OpsRow/Evaluate
@onready var _eval_out: RichTextLabel = $Margin/Root/EvalOutput

var _selected_thruster
var _wired: bool = false
var _updating_inspector: bool = false


func setup(preset_manager: Node, simulation_manager: Node, data_recorder: Node, playback_manager: Node, evaluator: Node) -> void:
	# 注入依赖（这是本面板与其它模块解耦的关键：面板不自己去 get_node）
	_preset_manager = preset_manager
	_sim = simulation_manager
	_rec = data_recorder
	_playback = playback_manager
	_evaluator = evaluator

	if not _wired:
		_wired = true
		# 连接 UI 事件：按钮/滑条/列表/SpinBox
		_load_preset.pressed.connect(_on_load_preset)
		_global_cmd.value_changed.connect(_on_global_command_changed)
		_thruster_list.item_selected.connect(_on_thruster_selected)
		_add_thruster.pressed.connect(_on_add_thruster)
		_del_thruster.pressed.connect(_on_delete_thruster)

		_cmd_spin.value_changed.connect(_on_inspector_changed)
		_max_spin.value_changed.connect(_on_inspector_changed)
		_pos_x.value_changed.connect(_on_inspector_changed)
		_pos_y.value_changed.connect(_on_inspector_changed)
		_pos_z.value_changed.connect(_on_inspector_changed)
		_rot_x.value_changed.connect(_on_inspector_changed)
		_rot_y.value_changed.connect(_on_inspector_changed)
		_rot_z.value_changed.connect(_on_inspector_changed)

		_rec_toggle.pressed.connect(_on_toggle_recording)
		_rec_clear.pressed.connect(_on_clear_recording)
		_play_toggle.pressed.connect(_on_toggle_playback)
		_rec_save.pressed.connect(_on_save_json)
		_rec_load.pressed.connect(_on_load_json)
		_eval_button.pressed.connect(_on_evaluate)

	# 刷新预设下拉框
	_preset_select.clear()
	for p in _preset_manager.list_presets():
		_preset_select.add_item(p)
	# 刷新推进器列表
	_refresh_thruster_list()


func _on_load_preset() -> void:
	# 加载选中的预设，并刷新列表/选中状态
	var preset_name = _preset_select.get_item_text(_preset_select.selected)
	_preset_manager.load_preset(preset_name)
	_selected_thruster = null
	_refresh_thruster_list()


func _on_global_command_changed(v: float) -> void:
	# 把一个统一的 command 值写入所有推进器（便于快速测试最大推力/方向等）
	var rov = _preset_manager.get_current_rov()
	if rov == null:
		return
	for t in rov.get_thrusters():
		t.command = v
	_refresh_thruster_list()


func _on_add_thruster() -> void:
	# 在 ROV/Thrusters 下新增一个推进器节点（默认参数）
	var rov = _preset_manager.get_current_rov()
	if rov == null:
		return
	var root = rov.get_node_or_null("Thrusters")
	if root == null:
		return
	var t = ThrusterScript.new()
	# 用当前时间戳做一个相对唯一的 id（简单实用，但不是强一致）
	t.id = int(Time.get_ticks_msec() % 1000000)
	t.name = "Thruster"
	root.add_child(t)
	_refresh_thruster_list()


func _on_delete_thruster() -> void:
	# 删除当前选中的推进器
	if _selected_thruster == null:
		return
	_selected_thruster.queue_free()
	_selected_thruster = null
	_refresh_thruster_list()


func _on_thruster_selected(index: int) -> void:
	# 列表选择变化：把选中推进器加载到 Inspector
	var rov = _preset_manager.get_current_rov()
	if rov == null:
		return
	var thr = rov.get_thrusters()
	if index < 0 or index >= thr.size():
		return
	_selected_thruster = thr[index]
	_load_inspector(_selected_thruster)


func _load_inspector(t) -> void:
	# 把推进器属性“展示”到 SpinBox（注意用 _updating_inspector 防止触发写回）
	_updating_inspector = true
	_cmd_spin.value = t.command
	_max_spin.value = t.max_thrust_n
	_pos_x.value = t.position.x
	_pos_y.value = t.position.y
	_pos_z.value = t.position.z
	_rot_x.value = t.rotation_degrees.x
	_rot_y.value = t.rotation_degrees.y
	_rot_z.value = t.rotation_degrees.z
	_updating_inspector = false


func _on_inspector_changed(_v: float) -> void:
	# 用户在 Inspector 改了数值：把 UI 值写回到推进器节点
	if _updating_inspector:
		return
	if _selected_thruster == null:
		return
	_selected_thruster.command = _cmd_spin.value
	_selected_thruster.max_thrust_n = _max_spin.value
	_selected_thruster.position = Vector3(_pos_x.value, _pos_y.value, _pos_z.value)
	_selected_thruster.rotation_degrees = Vector3(_rot_x.value, _rot_y.value, _rot_z.value)
	_refresh_thruster_list()


func _on_toggle_recording() -> void:
	# 录制开关：切换 DataRecorder 状态，并更新按钮文本
	if _rec.is_recording:
		_rec.stop_recording()
		_rec_toggle.text = "Start Rec"
	else:
		_rec.start_recording()
		_rec_toggle.text = "Stop Rec"


func _on_clear_recording() -> void:
	# 清空录制缓存（窗口 + 全量）
	_rec.clear()


func _on_toggle_playback() -> void:
	# 回放开关：回放使用“全量帧”，并更新按钮文本
	if _playback.is_playing:
		_playback.stop()
		_play_toggle.text = "Play"
	else:
		_playback.set_frames(_rec.get_all_frames())
		_playback.start()
		_play_toggle.text = "Stop"


func _on_save_json() -> void:
	# 保存录制到 user://recording.json
	var path := "user://recording.json"
	var ok := RecordingIOScript.save_json(_rec.get_all_frames(), path)
	_eval_out.clear()
	_eval_out.add_text(("✔ Saved: %s" if ok else "⚠ Save failed") % path + "\n")


func _on_load_json() -> void:
	# 从 user://recording.json 读取录制并写回 DataRecorder
	var path := "user://recording.json"
	var frames := RecordingIOScript.load_json(path)
	_rec.set_all_frames(frames)
	_eval_out.clear()
	_eval_out.add_text("✔ Loaded: %s  frames=%d\n" % [path, frames.size()])


func _on_evaluate() -> void:
	# 调用 DesignEvaluator 并把结果逐行输出
	_eval_out.clear()
	for line in _evaluator.evaluate():
		_eval_out.add_text(line + "\n")


func _refresh_thruster_list() -> void:
	# 刷新推进器列表显示：名称 + 指令 + 当前推力
	_thruster_list.clear()
	var rov = _preset_manager.get_current_rov()
	if rov == null:
		return
	for t in rov.get_thrusters():
		_thruster_list.add_item("%s  cmd=%.2f  F=%.1fN" % [t.name, t.command, t.get_thrust_n()])
