## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ChartLayoutSerializer
extends RefCounted

const JsonFileServiceScript = preload("res://Levels/5_rovsim/scripts/io/json_file_service.gd")
const ChartLayoutConfigScript = preload("res://Levels/5_rovsim/scripts/model/chart_layout_config.gd")


static func save(path: String, layout: ChartLayoutConfig) -> bool:
	var document: Dictionary = JsonFileServiceScript.build_document("rovsim.chart_layout", layout.to_dictionary())
	return JsonFileServiceScript.write_json(path, document)


static func load(path: String) -> ChartLayoutConfig:
	var document: Dictionary = JsonFileServiceScript.read_json(path)
	var payload: Dictionary = document.get("payload", document)
	var layout: ChartLayoutConfig = ChartLayoutConfigScript.new()
	layout.load_dictionary(payload)
	return layout
