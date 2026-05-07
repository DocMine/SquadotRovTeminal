## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name MachineSerializer
extends RefCounted

const JsonFileServiceScript = preload("res://Levels/5_rovsim/scripts/io/json_file_service.gd")
const MachineConfigScript = preload("res://Levels/5_rovsim/scripts/model/machine_config.gd")


static func save(path: String, machine: MachineConfig) -> bool:
	var document: Dictionary = JsonFileServiceScript.build_document("rovsim.machine", machine.to_dictionary())
	return JsonFileServiceScript.write_json(path, document)


static func load(path: String) -> MachineConfig:
	var document: Dictionary = JsonFileServiceScript.read_json(path)
	var payload: Dictionary = document.get("payload", document)
	var machine: MachineConfig = MachineConfigScript.new()
	machine.load_dictionary(payload)
	return machine
