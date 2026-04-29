extends Node

## 回放管理器（PlaybackManager）
##
## 作用：
## - 读取一段录制的 DataFrame 序列
## - 在播放时按“当前播放时间”找到最接近的录制帧
## - 把录制帧的位姿/速度写回到 ROV（RigidBody3D），从而实现回放
##
## 核心思路：
## - 播放时间 _play_time_s 从 0 开始随 delta 累加
## - 录制帧有自己的时间轴（frames[i].time_s），从第一帧开始的时间是 _t0_s
## - 目标时间 target_t = _t0_s + _play_time_s
## - 用 _get_nearest_frame(target_t) 找到最接近的帧并应用到 ROV
##
## 注意事项：
## - start() 时会把 ROV.freeze 暂时置为 true，防止物理仿真与回放写入“打架”
## - stop() 会恢复 freeze 到开始前的状态
## - _get_nearest_frame 当前是线性扫描 O(n)。窗口较小时足够；如果要回放很长录制，
##   可以改成二分查找（按 time_s 排序）来提升性能

signal playback_changed(is_playing: bool)

var is_playing: bool = false
var _sim: Node
var _frames: Array = []
var _t0_s: float = 0.0
var _play_time_s: float = 0.0
var _rov
var _saved_freeze: bool = false


func setup(simulation_manager: Node) -> void:
	# 注入仿真管理器，用于找到当前 ROV 节点
	_sim = simulation_manager


func set_frames(frames: Array) -> void:
	# 设置要回放的帧序列（通常来自 RecordingIO.load_json 或 DataRecorder.get_all_frames）
	_frames = frames
	if _frames.size() > 0:
		_t0_s = _frames[0].time_s


func start() -> void:
	# 开始回放：拿到 ROV，并把物理冻结以便我们直接写位姿/速度
	if _sim == null:
		return
	_rov = _sim.rov
	if _rov == null:
		return
	_saved_freeze = _rov.freeze
	_rov.freeze = true
	_play_time_s = 0.0
	is_playing = true
	playback_changed.emit(true)


func stop() -> void:
	# 停止回放：恢复 freeze，并广播状态
	if _rov != null:
		_rov.freeze = _saved_freeze
	is_playing = false
	playback_changed.emit(false)


func _physics_process(delta: float) -> void:
	# 回放使用 _physics_process：与物理帧同步，写入 RigidBody 状态更一致
	if not is_playing:
		return
	if _rov == null or _frames.size() == 0:
		return
	_play_time_s += delta
	var target_t = _t0_s + _play_time_s
	# 播放超过最后一帧时间则自动停止
	if target_t > _frames[_frames.size() - 1].time_s:
		stop()
		return
	var f = _get_nearest_frame(target_t)
	if f == null:
		stop()
		return
	# 将录制帧状态应用到 ROV：位姿 + 线速度 + 角速度
	_rov.global_transform = Transform3D(Basis(f.state.rotation_quat), f.state.position_m)
	_rov.linear_velocity = f.state.linear_velocity_mps
	_rov.angular_velocity = f.state.angular_velocity_radps


func _get_nearest_frame(t: float):
	# 找到 time_s 最接近 t 的帧（线性扫描）
	var best = null
	var best_dt = INF
	for f in _frames:
		var dt = absf(f.time_s - t)
		if dt < best_dt:
			best_dt = dt
			best = f
	return best
