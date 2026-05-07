## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name JsonFileService
extends RefCounted

const DEFAULT_UNITS: Dictionary = {
	"length": "m",
	"force": "N",
	"torque": "N*m",
	"angle": "rad",
	"time": "s",
}


static func build_document(schema: String, payload: Dictionary) -> Dictionary:
	return {
		"schema": schema,
		"version": 1,
		"created_at": Time.get_datetime_string_from_system(true),
		"units": DEFAULT_UNITS,
		"payload": payload,
	}


static func write_json(path: String, data: Dictionary) -> bool:
	var normalized_path: String = _normalize_path(path)
	var directory_path: String = normalized_path.get_base_dir()
	if not directory_path.is_empty():
		DirAccess.make_dir_recursive_absolute(directory_path)
	var file: FileAccess = FileAccess.open(normalized_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open JSON for write: %s" % normalized_path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func read_json(path: String) -> Dictionary:
	var normalized_path: String = _normalize_path(path)
	if not FileAccess.file_exists(normalized_path):
		push_error("JSON file does not exist: %s" % normalized_path)
		return {}
	var file: FileAccess = FileAccess.open(normalized_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON for read: %s" % normalized_path)
		return {}
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON document: %s" % normalized_path)
		return {}
	return parsed


static func user_absolute_path(user_path: String) -> String:
	return ProjectSettings.globalize_path(user_path)


static func _normalize_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path
