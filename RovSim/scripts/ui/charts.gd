extends Control

## 曲线面板（Charts Panel）
##
## 作用：
## - 监听 DataRecorder.frame_recorded
## - 每次有新帧时，从 DataRecorder 拉取“窗口帧”（get_window_frames）
## - 把窗口帧分发给多个 ChartPlot（Depth/Attitude/Thrusters/Velocity）
##
## 为什么每次都拉窗口帧而不是只用最新一帧？
## - 图表需要“最近一段时间”的点序列来绘制曲线
## - DataRecorder 已经维护了滑动窗口，UI 只需读取即可
##
## 图表数据绑定方式：
## - 每个 plot 通过 configure() 接收一个 series 数组
## - series 的 getter 是一个 Callable：输入一帧 DataFrame，输出一个数值
## - 这样 Charts 不需要知道 ChartPlot 内部如何绘制，只负责“给数据怎么取”

var _rec: Node
@onready var _tabs: TabContainer = $Margin/Tabs
@onready var _depth_plot = $Margin/Tabs/DepthPlot
@onready var _att_plot = $Margin/Tabs/AttitudePlot
@onready var _thr_plot = $Margin/Tabs/ThrustersPlot
@onready var _vel_plot = $Margin/Tabs/VelocityPlot


func setup(data_recorder: Node) -> void:
	# 注入数据源，并监听“新帧到达”事件
	_rec = data_recorder
	_rec.frame_recorded.connect(_on_frame)
	# 初始化 Tab 标题（避免依赖编辑器里手动设置）
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_depth_plot), "Depth")
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_att_plot), "Attitude")
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_thr_plot), "Thrusters")
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_vel_plot), "Velocity")

	# 深度：单条曲线
	_depth_plot.configure([
		{"name": "depth_m", "color": Color(0.3, 0.8, 1.0), "enabled": true, "getter": func(f) -> float: return f.state.depth_m},
	])
	# 姿态：Roll/Pitch/Yaw 三条曲线
	_att_plot.configure([
		{"name": "roll_deg", "color": Color(1.0, 0.4, 0.4), "enabled": true, "getter": func(f) -> float: return _roll_deg(f.state.rotation_quat)},
		{"name": "pitch_deg", "color": Color(0.4, 1.0, 0.4), "enabled": true, "getter": func(f) -> float: return _pitch_deg(f.state.rotation_quat)},
		{"name": "yaw_deg", "color": Color(0.4, 0.6, 1.0), "enabled": true, "getter": func(f) -> float: return _yaw_deg(f.state.rotation_quat)},
	])
	# 速度：标量速度（线速度模长）
	_vel_plot.configure([
		{"name": "speed_mps", "color": Color(1.0, 0.9, 0.4), "enabled": true, "getter": func(f) -> float: return f.state.linear_velocity_mps.length()},
	])


func _on_frame(_f) -> void:
	# 每来一帧，就刷新一次所有曲线（使用滑动窗口数据）
	var frames = _rec.get_window_frames()
	_depth_plot.update_frames(frames)
	_att_plot.update_frames(frames)
	_update_thruster_plot(frames)
	_vel_plot.update_frames(frames)


func _update_thruster_plot(frames: Array) -> void:
	# 推进器曲线的条数取决于当前 ROV 配置（推进器数量可能可变）
	if frames.size() == 0:
		return
	var first = frames[0]
	var count = first.thrusters.size()
	# ChartPlot 内部会保存 series 列表；数量变化时需要重新 configure
	var cur = _thr_plot._series.size()
	if cur != count:
		var series = []
		for i in count:
			var c = Color.from_hsv(float(i) / max(count, 1), 0.8, 1.0)
			series.append({
				"name": first.thrusters[i].name,
				"color": c,
				"enabled": true,
				"getter": func(f, idx = i) -> float:
					if idx < 0 or idx >= f.thrusters.size():
						return 0.0
					return f.thrusters[idx].thrust_n,
			})
		_thr_plot.configure(series)
	# configure 之后/或数量没变时，都更新窗口帧数据
	_thr_plot.update_frames(frames)


func _roll_deg(q: Quaternion) -> float:
	# 这里用 Basis(q).get_euler() 做四元数到欧拉角的转换（单位：弧度）
	# 注意：欧拉角存在万向节锁风险，但在仪表盘/曲线展示场景通常足够。
	return rad_to_deg(Basis(q).get_euler().z)


func _pitch_deg(q: Quaternion) -> float:
	return rad_to_deg(Basis(q).get_euler().x)


func _yaw_deg(q: Quaternion) -> float:
	return rad_to_deg(Basis(q).get_euler().y)
