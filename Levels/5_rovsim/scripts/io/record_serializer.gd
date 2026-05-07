## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name RecordSerializer
extends RefCounted

const JsonFileServiceScript = preload("res://Levels/5_rovsim/scripts/io/json_file_service.gd")


static func save(path: String, frames: Array[RefCounted], sample_frequency_hz: float, machine_summary: Dictionary) -> bool:
	var frame_rows: Array[Dictionary] = []
	for frame: RefCounted in frames:
		var data_frame: DataFrame = frame as DataFrame
		if data_frame != null:
			frame_rows.append(data_frame.to_dictionary())
	var payload: Dictionary = {
		"sample_frequency_hz": sample_frequency_hz,
		"machine_summary": machine_summary,
		"frame_count": frame_rows.size(),
		"frames": frame_rows,
		"events": [],
	}
	var document: Dictionary = JsonFileServiceScript.build_document("rovsim.record", payload)
	return JsonFileServiceScript.write_json(path, document)


static func load(path: String) -> Dictionary:
	var document: Dictionary = JsonFileServiceScript.read_json(path)
	return document.get("payload", document)
