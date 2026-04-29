extends VBoxContainer
class_name ChartPlot

## 单个图表组件（ChartPlot）
##
## 这是 Charts 面板里每一个 Tab 页上的“单张图”。它做两件事：
## 1) 管理图例 UI（Legend：一组 CheckBox，用于开关每条曲线）
## 2) 把窗口帧数据转换成 tau-plot 可用的数据集（TauPlot.Dataset），并触发绘制
##
## 为什么要把“取数逻辑”交给外部？
## - Charts.gd 负责定义 series：name/color/getter/enabled
## - ChartPlot 只关心“把 getter 取出来的数按时间组织成图表”
## 这样可以让 ChartPlot 复用：任何时间序列都能用同一套 UI + 绘图逻辑。
##
## 数据流（最重要的流程）：
## - configure(series):
##   - 保存 series 定义
##   - 重建图例复选框
##   - 创建 dataset/config（只跟 series 数量/颜色/名称有关）
##   - 根据 enabled 重建 bindings 并 plot_xy()
## - update_frames(frames):
##   - 抽样窗口帧（最多 max_points 个点）
##   - 每个抽样帧：X=time_s，Y=每条 series 的 getter(frame)
##   - 写入 dataset（begin_batch/end_batch 让插件做增量更新更高效）
##
## 注意：
## - 目前 tau-plot 的 XY 里只有 BAR/SCATTER，两者都不是“折线”。这里用 SCATTER
##   并把 marker_size 调小，让视觉上接近连续曲线。

@export var max_points: int = 1000

## series 定义数组，每项是一个 Dictionary：
## - name: String   曲线名称（用于 legend）
## - color: Color   曲线颜色
## - enabled: bool  是否显示
## - getter: Callable(frame) -> float  从 DataFrame 中取数
## - _tau_series_id: int （内部字段）对应 tau-plot Dataset 的 series_id
var _series: Array = []
@onready var _legend: HBoxContainer = $Legend
@onready var _plot: TauPlot = $Plot

## tau-plot 数据集：存储 X/Y 样本并驱动渲染（这里用 SHARED_X + NUMERIC，即所有曲线共享同一份时间轴）
var _dataset: TauPlot.Dataset = null
## tau-plot XY 配置：轴、pane、overlay 等配置（这里是 1 个 pane + 1 个 scatter overlay）
var _xy_config: TauXYConfig = null


func configure(series: Array) -> void:
	_series = series
	_rebuild_legend()
	_rebuild_dataset_and_config()
	_replot_from_series_enabled()


func update_frames(frames: Array) -> void:
	# update_frames 只负责“更新数据”，不负责改配置；配置变化由 configure/legend 触发
	if _dataset == null:
		return

	# 批处理：避免每写一个样本就触发一次重绘/刷新
	_dataset.begin_batch()
	# 这里采用“重建窗口”策略：每次都用窗口帧清空并重写 dataset
	# 好处：实现简单且始终与 DataRecorder 的窗口严格一致
	# 代价：每帧会写入若干样本；通过抽样（max_points）控制成本
	_dataset.clear_samples()

	var n := frames.size()
	if n > 0:
		# 抽样步长：窗口帧越多，步长越大；最终点数不超过 max_points
		var step := int(ceil(float(n) / float(max(max_points, 1))))
		step = max(step, 1)
		for i in range(0, n, step):
			var f = frames[i]
			var ys := PackedFloat64Array()
			ys.resize(_series.size())
			for s_i in range(_series.size()):
				ys[s_i] = float(_series[s_i]["getter"].call(f))
			# X=time_s；Y=每条曲线的值（顺序必须与 dataset.add_series 的顺序一致）
			_dataset.append_shared_sample(float(f.time_s), ys)

	_dataset.end_batch()


func _rebuild_legend() -> void:
	# Legend 是自定义的（不用 tau-plot 自带 legend），因此需要手动创建 CheckBox
	for c in _legend.get_children():
		c.queue_free()
	for i in _series.size():
		var idx = i
		var s = _series[idx]
		var cb = CheckBox.new()
		cb.text = str(s.get("name", "series"))
		cb.button_pressed = bool(s.get("enabled", true))
		cb.toggled.connect(func(v: bool, j = idx) -> void:
			# 切换曲线显示：更新 enabled 后重建绑定并重新 plot
			_series[j]["enabled"] = v
			_replot_from_series_enabled()
		)
		_legend.add_child(cb)


func _rebuild_dataset_and_config() -> void:
	if _plot == null:
		return

	if _series.is_empty():
		_dataset = null
		_xy_config = null
		_plot.reset()
		return

	# Dataset：共享时间轴（SHARED_X），X 是数值（秒），容量用 max_points 控制
	_dataset = TauPlot.Dataset.new(TauPlot.Dataset.Mode.SHARED_X, TauPlot.Dataset.XElementType.NUMERIC, max(max_points, 1))

	var series_colors: Array[Color] = []
	series_colors.resize(_series.size())

	# 先把所有 series 加进 dataset，确保它们的 series_id 稳定
	# enabled 只影响“绑定显示”，不影响 dataset 内是否存在该 series
	for i in range(_series.size()):
		var s = _series[i]
		var name := str(s.get("name", "series"))
		var series_id := _dataset.add_series(name, max(max_points, 1))
		_series[i]["_tau_series_id"] = series_id
		series_colors[i] = s.get("color", Color.WHITE)

	# X/Y 坐标轴：连续轴（时间-数值）
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	# Scatter overlay：把点画得很小，使视觉效果接近“线”
	var scatter_cfg := TauScatterConfig.new()
	scatter_cfg.style.marker_size_px = 2.0
	scatter_cfg.style.outline_width_px = 0.0
	scatter_cfg.style.hovered_marker_size_px = 4.0
	scatter_cfg.style.hovered_outline_width_px = 0.0

	# Pane：只用左侧 Y 轴；overlay 只挂 scatter
	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]

	# XYConfig：只有一个 pane；series_colors 用外部传入的颜色覆盖插件默认调色板
	_xy_config = TauXYConfig.new()
	_xy_config.x_axis = x_axis
	_xy_config.panes = [pane]
	_xy_config.style.series_colors = series_colors


func _replot_from_series_enabled() -> void:
	if _plot == null:
		return
	if _dataset == null or _xy_config == null:
		_plot.reset()
		return

	# bindings 描述“哪些 series 画出来、画到哪个 pane、用哪种 overlay、挂到哪个 Y 轴”
	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(_series.size()):
		if not bool(_series[i].get("enabled", true)):
			continue
		var b := TauXYSeriesBinding.new()
		b.series_id = int(_series[i]["_tau_series_id"])
		b.pane_index = 0
		b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
		b.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(b)

	# 这里关闭 tau-plot 自带 legend/hover：项目使用自定义 Legend（复选框），也不需要悬浮提示
	_plot.title = ""
	_plot.legend_enabled = false
	_plot.hover_enabled = false

	if bindings.is_empty():
		_plot.reset()
		return

	# 注意：plot_xy 会做一次参数校验（validate），失败会 push_error
	_plot.plot_xy(_dataset, _xy_config, bindings)
