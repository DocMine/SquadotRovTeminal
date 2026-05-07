## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ThrusterSerializer
extends RefCounted

const JsonFileServiceScript = preload("res://Levels/5_rovsim/scripts/io/json_file_service.gd")
const ThrusterTemplateScript = preload("res://Levels/5_rovsim/scripts/model/thruster_template.gd")


static func save(path: String, thruster_template: ThrusterTemplate) -> bool:
	var document: Dictionary = JsonFileServiceScript.build_document("rovsim.thruster", thruster_template.to_dictionary())
	return JsonFileServiceScript.write_json(path, document)


static func load(path: String) -> ThrusterTemplate:
	var document: Dictionary = JsonFileServiceScript.read_json(path)
	var payload: Dictionary = document.get("payload", document)
	var thruster_template: ThrusterTemplate = ThrusterTemplateScript.new()
	thruster_template.load_dictionary(payload)
	return thruster_template
