## Displays one realtime chart with a localized title and multiple named series.
## Mount on `modules/ui_modules/TauRealtimeChart/TauRealtimeChart.tscn`; keep `title`
## as editor-visible Chinese text and use `title_key` for runtime localization.
class_name TauRealtimeChart
extends Control

const TauPlotScript = preload("res://addons/tau-plot/plot/plot.gd")

@export var title: String = "深度 / 时间"
@export var title_key: String = "CHART_DEPTH"
@export var y_unit: String = ""
@export var max_points: int = 1000

@onready var plot: PanelContainer = %TauPlotNode

var _dataset: Variant = null
var _series_order: PackedStringArray = PackedStringArray()
var _last_x_value: float = -INF


## Initializes the plot title and base legend configuration.
func _ready() -> void:
	UICore.ensure_localization_ready()
	_apply_title()
	plot.set("legend_enabled", true)


## Replaces the chart content with the provided named series dictionary.
## Example:
## `chart.set_series({"depth": [Vector2(0.0, 1.2), Vector2(0.1, 1.3)]})`
func set_series(series: Dictionary) -> void:
	if series.is_empty():
		_reset_plot()
		return
	var next_order: PackedStringArray = _resolve_series_order(series)
	if next_order.is_empty():
		_reset_plot()
		return
	if _dataset == null or next_order != _series_order:
		_initialize_plot(series, next_order)
		return
	_append_new_samples(series)


## Refreshes the localized title when the application locale changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_title()


## Applies the exported localization key while preserving Chinese editor defaults.
func _apply_title() -> void:
	var visible_title: String = title
	if not title_key.is_empty():
		visible_title = UICore.translate(title_key)
	plot.set("title", visible_title)


## Rebuilds the dataset and plot configuration for a new series layout.
func _initialize_plot(series: Dictionary, next_order: PackedStringArray) -> void:
	_series_order = next_order
	_last_x_value = -INF
	var initial_x: PackedFloat64Array = PackedFloat64Array()
	var initial_y_by_series: Array[PackedFloat64Array] = []
	for series_name: String in _series_order:
		initial_y_by_series.append(PackedFloat64Array())
	var sample_points: Array = _downsample(series[_series_order[0]])
	for point_variant: Variant in sample_points:
		var point: Vector2 = point_variant
		if point.x <= _last_x_value:
			continue
		initial_x.append(point.x)
		for series_index: int in range(_series_order.size()):
			var value: float = _resolve_value_at_x(series, _series_order[series_index], point.x)
			initial_y_by_series[series_index].append(value)
		_last_x_value = point.x
	_dataset = TauPlotScript.Dataset.make_shared_x_continuous(_series_order, initial_x, initial_y_by_series, max_points)
	var x_axis: TauAxisConfig = TauAxisConfig.new()
	x_axis.title = "s"
	x_axis.include_zero_in_domain = false
	var y_axis: TauAxisConfig = TauAxisConfig.new()
	y_axis.title = y_unit
	y_axis.include_zero_in_domain = false
	var scatter_config: TauScatterConfig = TauScatterConfig.new()
	scatter_config.style.marker_size_px = 5.0
	scatter_config.style.outline_width_px = 0.0
	var pane: TauPaneConfig = TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]
	var config: TauXYConfig = TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	var bindings: Array[TauXYSeriesBinding] = []
	for series_index: int in range(_dataset.get_series_count()):
		var binding: TauXYSeriesBinding = TauXYSeriesBinding.new()
		binding.series_id = _dataset.get_series_id_by_index(series_index)
		binding.pane_index = 0
		binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
		binding.y_axis_id = TauPlotScript.AxisId.LEFT
		bindings.append(binding)
	_apply_title()
	plot.call("plot_xy", _dataset, config, bindings)


## Appends only samples newer than the currently rendered X position.
func _append_new_samples(series: Dictionary) -> void:
	var reference_points: Array = series[_series_order[0]]
	var appended: bool = false
	for point_variant: Variant in reference_points:
		var point: Vector2 = point_variant
		if point.x <= _last_x_value:
			continue
		var values: PackedFloat64Array = PackedFloat64Array()
		for series_name: String in _series_order:
			values.append(_resolve_value_at_x(series, series_name, point.x))
		_dataset.append_shared_sample(point.x, values)
		_last_x_value = point.x
		appended = true
	if appended:
		plot.call("refresh_now")


## Clears the current plot state and waits for the next non-empty dataset.
func _reset_plot() -> void:
	plot.call("reset")
	_dataset = null
	_series_order = PackedStringArray()
	_last_x_value = -INF


## Reduces oversized sample arrays to the configured maximum count.
func _downsample(points: Array) -> Array:
	if points.size() <= max_points:
		return points
	var sampled: Array = []
	var step: int = ceili(float(points.size()) / float(max_points))
	for index: int in range(0, points.size(), step):
		sampled.append(points[index])
	return sampled


## Resolves the non-empty series order used by the shared X-axis dataset.
func _resolve_series_order(series: Dictionary) -> PackedStringArray:
	var order: PackedStringArray = PackedStringArray()
	for key: Variant in series.keys():
		var points: Array = series[key]
		if not points.is_empty():
			order.append(str(key))
	order.sort()
	return order


## Returns the Y value at the requested X position, falling back to the last known sample.
func _resolve_value_at_x(series: Dictionary, series_name: String, x_value: float) -> float:
	if not series.has(series_name):
		return 0.0
	var points: Array = series[series_name]
	var fallback: float = 0.0
	for point_variant: Variant in points:
		var point: Vector2 = point_variant
		fallback = point.y
		if is_equal_approx(point.x, x_value):
			return point.y
	return fallback
