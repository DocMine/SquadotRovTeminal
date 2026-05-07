## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name DataRecorder
extends Node

signal frame_recorded(frame: RefCounted)

@export var sample_frequency_hz: float = 20.0
@export var window_seconds: float = 20.0
@export var keep_full_record: bool = true

var is_recording: bool = true

var _accumulator_s: float = 0.0
var _window_frames: Array[RefCounted] = []
var _all_frames: Array[RefCounted] = []


func set_recording(value: bool) -> void:
	is_recording = value


func clear() -> void:
	_accumulator_s = 0.0
	_window_frames.clear()
	_all_frames.clear()


func tick(delta: float, frame: RefCounted) -> void:
	if not is_recording:
		return
	var interval_s: float = 1.0 / maxf(1.0, sample_frequency_hz)
	_accumulator_s += delta
	while _accumulator_s >= interval_s:
		_accumulator_s -= interval_s
		_record(frame.duplicate_frame())


func get_window_frames() -> Array[RefCounted]:
	return _window_frames.duplicate()


func get_window_frames_after(time_s: float) -> Array[RefCounted]:
	var frames: Array[RefCounted] = []
	var start_index: int = 0
	for index: int in range(_window_frames.size() - 1, -1, -1):
		var frame: DataFrame = _window_frames[index] as DataFrame
		if frame == null:
			continue
		if frame.time_s <= time_s:
			start_index = index + 1
			break
	for index: int in range(start_index, _window_frames.size()):
		frames.append(_window_frames[index])
	return frames


func get_all_frames() -> Array[RefCounted]:
	return _all_frames.duplicate()


func get_all_frame_count() -> int:
	return _all_frames.size()


func _record(frame: RefCounted) -> void:
	_window_frames.append(frame)
	if keep_full_record:
		_all_frames.append(frame)
	var cutoff_time_s: float = frame.time_s - window_seconds
	while _window_frames.size() > 0 and _window_frames[0].time_s < cutoff_time_s:
		_window_frames.remove_at(0)
	frame_recorded.emit(frame)
