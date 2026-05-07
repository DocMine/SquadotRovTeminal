## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ChartLayoutConfig
extends RefCounted

var layout_id: String = "default_chart_layout"
var display_name: String = "Default Chart Layout"
var window_seconds: float = 20.0
var pages: Array[Dictionary] = [
	{"title_key": "CHART_PAGE_MOTION", "charts": ["depth", "speed", "attitude"]},
	{"title_key": "CHART_PAGE_FORCES", "charts": ["force", "torque"]},
	{"title_key": "CHART_PAGE_THRUSTERS", "charts": ["thrust", "command"]},
]


func to_dictionary() -> Dictionary:
	return {
		"layout_id": layout_id,
		"display_name": display_name,
		"window_seconds": window_seconds,
		"pages": pages,
	}


func load_dictionary(data: Dictionary) -> void:
	layout_id = str(data.get("layout_id", layout_id))
	display_name = str(data.get("display_name", display_name))
	window_seconds = float(data.get("window_seconds", window_seconds))
	pages = data.get("pages", pages)
