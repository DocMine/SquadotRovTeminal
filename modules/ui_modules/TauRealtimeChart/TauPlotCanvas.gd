## 共享实时折线图画布，负责绘制多条时间序列的简化折线预览。
## 该脚本属于 `TauRealtimeChart` 的内部实现层，不建议页面脚本直接操作其私有绘制细节。
@tool
extends Control

const BACKGROUND_COLOR: Color = Color(0.09, 0.11, 0.14, 1.0)
const PLOT_COLOR: Color = Color(0.13, 0.15, 0.19, 1.0)
const GRID_COLOR: Color = Color(0.28, 0.31, 0.36, 0.65)
const BORDER_COLOR: Color = Color(0.6, 0.66, 0.75, 0.85)
const FALLBACK_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)

var _series: Dictionary = {}
var _series_order: PackedStringArray = PackedStringArray()
var _series_colors: Dictionary = {}


## 初始化时请求首次重绘，保证编辑器和运行时都能看到默认边框。
func _ready() -> void:
	queue_redraw()


## 在尺寸变化后重新绘制图表。
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		queue_redraw()


## 更新当前要绘制的序列数据。
## 参数 `series` 是按序列名分组的点集字典。
## 参数 `series_order` 决定图例与绘制顺序。
## 参数 `series_colors` 指定每条序列对应的颜色。
func _set_chart_data(series: Dictionary, series_order: PackedStringArray, series_colors: Dictionary) -> void:
	_series = series.duplicate(true)
	_series_order = series_order
	_series_colors = series_colors.duplicate()
	queue_redraw()


## 绘制背景、网格和所有折线序列。
func _draw() -> void:
	var frame_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(frame_rect, BACKGROUND_COLOR)

	var plot_rect: Rect2 = _resolve_plot_rect(frame_rect)
	draw_rect(plot_rect, PLOT_COLOR)
	_draw_grid(plot_rect)

	if _series_order.is_empty():
		return

	var domain: Dictionary = _resolve_domain()
	for series_name: String in _series_order:
		var points: Array = _series.get(series_name, [])
		var polyline: PackedVector2Array = _build_polyline(points, plot_rect, domain)
		var color: Color = _series_colors.get(series_name, FALLBACK_COLOR)
		if polyline.size() >= 2:
			draw_polyline(polyline, color, 2.0, true)
		for point: Vector2 in polyline:
			draw_circle(point, 2.5, color)


## 计算实际绘图区矩形，给边框和数据点留出内边距。
func _resolve_plot_rect(frame_rect: Rect2) -> Rect2:
	var horizontal_padding: float = 16.0
	var vertical_padding: float = 16.0
	var width: float = maxf(1.0, frame_rect.size.x - horizontal_padding * 2.0)
	var height: float = maxf(1.0, frame_rect.size.y - vertical_padding * 2.0)
	return Rect2(Vector2(horizontal_padding, vertical_padding), Vector2(width, height))


## 绘制网格线和外边框。
func _draw_grid(plot_rect: Rect2) -> void:
	draw_rect(plot_rect, BORDER_COLOR, false, 1.0)
	for index: int in range(1, 4):
		var x: float = plot_rect.position.x + plot_rect.size.x * float(index) / 4.0
		var y: float = plot_rect.position.y + plot_rect.size.y * float(index) / 4.0
		draw_line(Vector2(x, plot_rect.position.y), Vector2(x, plot_rect.end.y), GRID_COLOR, 1.0)
		draw_line(Vector2(plot_rect.position.x, y), Vector2(plot_rect.end.x, y), GRID_COLOR, 1.0)


## 统计全部序列的坐标范围，用于后续归一化映射。
func _resolve_domain() -> Dictionary:
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF

	for series_name: String in _series_order:
		var points: Array = _series.get(series_name, [])
		for point_variant: Variant in points:
			var point: Vector2 = point_variant
			min_x = minf(min_x, point.x)
			max_x = maxf(max_x, point.x)
			min_y = minf(min_y, point.y)
			max_y = maxf(max_y, point.y)

	if min_x == INF:
		min_x = 0.0
		max_x = 1.0
		min_y = 0.0
		max_y = 1.0
	if is_equal_approx(min_x, max_x):
		min_x -= 0.5
		max_x += 0.5
	if is_equal_approx(min_y, max_y):
		min_y -= 0.5
		max_y += 0.5

	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y,
	}


## 把单条序列的点集映射为屏幕折线。
func _build_polyline(points: Array, plot_rect: Rect2, domain: Dictionary) -> PackedVector2Array:
	var polyline: PackedVector2Array = PackedVector2Array()
	for point_variant: Variant in points:
		var point: Vector2 = point_variant
		polyline.append(_map_point(point, plot_rect, domain))
	return polyline


## 把一个数据点映射到当前绘图区坐标。
func _map_point(point: Vector2, plot_rect: Rect2, domain: Dictionary) -> Vector2:
	var min_x: float = domain["min_x"]
	var max_x: float = domain["max_x"]
	var min_y: float = domain["min_y"]
	var max_y: float = domain["max_y"]

	var x_ratio: float = inverse_lerp(min_x, max_x, point.x)
	var y_ratio: float = inverse_lerp(min_y, max_y, point.y)

	var x: float = plot_rect.position.x + plot_rect.size.x * x_ratio
	var y: float = plot_rect.end.y - plot_rect.size.y * y_ratio
	return Vector2(x, y)
