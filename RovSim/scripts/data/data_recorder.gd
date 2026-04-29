extends Node

## 数据录制器（时间序列采样 + 滑动窗口）
##
## 作用：
## - 以固定采样率（sample_rate_hz）从 SimulationManager 取“当前状态”
## - 把采样结果封装成 DataFrame
## - 维护两份缓存：
##   1) _window_frames：最近 window_seconds 秒的滑动窗口（用于实时 UI：仪表盘/曲线）
##   2) _all_frames：全量录制（可选，用于回放/导出）
##
## 对外事件：
## - frame_recorded：每写入一帧就发一次，UI 通常只需要监听这个信号然后拉取窗口数据
## - recording_changed：开始/停止录制时发一次，用于 UI 状态切换
##
## 实现要点：
## - 用 _accum_s 做时间累加，保证在低帧率或 delta 波动时仍能“补采样”
## - _trim_window 只按时间戳剔除过期帧，保持窗口长度近似恒定

signal frame_recorded(frame)
signal recording_changed(is_recording: bool)

const DataFrameScript := preload("res://RovSim/scripts/data/data_frame.gd")

## 采样频率（Hz）。例如 10Hz 表示每 0.1s 采一次样。
@export var sample_rate_hz: float = 10.0
## 窗口时长（秒）。只保留最近 window_seconds 秒的帧用于实时展示。
@export var window_seconds: float = 20.0
## 是否保留全量录制数据（用于回放/导出）。关闭后只维护窗口数据。
@export var keep_full_recording: bool = true

## 当前是否处于录制状态。start_recording/stop_recording 会切换它。
var is_recording: bool = false
## 采样时间累加器，用来决定何时该采样以及是否需要“补采样”。
var _accum_s: float = 0.0
## 滑动窗口帧（最近 window_seconds 秒）。
var _window_frames: Array = []
## 全量帧（从开始录制到现在），受 keep_full_recording 控制。
var _all_frames: Array = []

## 仿真管理器引用（负责提供 get_current_state / get_thruster_states 等接口）。
var _sim: Node


func _ready() -> void:
	# 默认按相对路径寻找 SimulationManager。Main 脚本会把各节点摆在同一层级。
	_sim = get_node_or_null("../SimulationManager")


func start_recording() -> void:
	# 开始录制：打开开关并广播状态
	is_recording = true
	recording_changed.emit(true)


func stop_recording() -> void:
	# 停止录制：关闭开关并广播状态
	is_recording = false
	recording_changed.emit(false)


func clear() -> void:
	# 清空缓存（不会自动停止录制）
	_window_frames.clear()
	_all_frames.clear()


func get_window_frames() -> Array:
	# 返回滑动窗口帧（注意：这里直接返回数组引用，调用方不要随意修改内容）
	return _window_frames


func get_all_frames() -> Array:
	# 返回全量帧（同上，调用方不要随意修改内容）
	return _all_frames


func set_all_frames(frames: Array) -> void:
	# 用外部传入的帧替换当前缓存（常用于从磁盘读取录制并进入回放模式）
	_all_frames = frames
	_window_frames = frames.duplicate()
	if _window_frames.size() > 0:
		_trim_window(_window_frames[_window_frames.size() - 1].time_s)


func _physics_process(delta: float) -> void:
	# 录制逻辑放在 _physics_process：与物理步进同步，时间尺度更稳定
	if _sim == null:
		return
	if not is_recording:
		return
	var step = 1.0 / max(sample_rate_hz, 0.001)
	_accum_s += delta
	# 当累加时间超过一个采样周期时，进行采样；如果超过多个周期则循环补采样
	while _accum_s >= step:
		_accum_s -= step
		_record_one()


func _record_one() -> void:
	# 构造一帧 DataFrame：包含时刻、ROV 状态、推进器状态等
	var f = DataFrameScript.new()
	f.state = _sim.get_current_state()
	f.time_s = f.state.time_s
	f.thrusters = _sim.get_thruster_states()
	_window_frames.append(f)
	if keep_full_recording:
		_all_frames.append(f)
	# 写入后立刻裁剪窗口，保证窗口数据只覆盖最近 window_seconds 秒
	_trim_window(f.time_s)
	# 用信号通知 UI/回放系统：新的一帧已经就绪
	frame_recorded.emit(f)


func _trim_window(now_s: float) -> void:
	# 移除窗口中时间戳早于 min_t 的帧（越旧越先删）
	var min_t = now_s - window_seconds
	while _window_frames.size() > 0 and _window_frames[0].time_s < min_t:
		_window_frames.remove_at(0)
