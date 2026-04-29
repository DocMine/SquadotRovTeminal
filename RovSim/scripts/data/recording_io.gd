extends RefCounted
class_name RecordingIO

## 录制文件 I/O（RecordingIO）
##
## 这是一个“纯工具类”（静态方法），负责把 DataFrame 数组保存/读取为 JSON 文件。
## - save_json(frames, path) -> bool
## - load_json(path) -> Array[DataFrame]
##
## 文件格式：
## {
##   "version": 1,
##   "frames": [ {DataFrame.to_dict()}, {DataFrame.to_dict()}, ... ]
## }
##
## 说明：
## - version 用于未来格式升级（例如新增字段、压缩、二进制等）
## - JSON 便于调试与分享，但不是最高效的存储格式；长时间录制可能会较大

const DataFrameScript := preload("res://RovSim/scripts/data/data_frame.gd")

static func save_json(frames: Array, path: String) -> bool:
	# 将帧数组写为 JSON 文本并保存到磁盘
	var arr = []
	arr.resize(frames.size())
	for i in frames.size():
		arr[i] = frames[i].to_dict()
	var doc = {
		"version": 1,
		"frames": arr,
	}
	var text = JSON.stringify(doc, "\t")
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	return true


static func load_json(path: String) -> Array:
	# 从 JSON 文件读取并恢复 DataFrame 数组
	if not FileAccess.file_exists(path):
		return []
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var frames = []
	for d in parsed.get("frames", []):
		frames.append(DataFrameScript.from_dict(d))
	return frames
