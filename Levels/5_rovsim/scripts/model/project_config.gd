## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ROVProjectConfig
extends RefCounted

var project_id: String = "rovsim_project"
var display_name: String = "ROVSim Project"
var machine_path: String = ""
var thruster_template_path: String = ""
var record_path: String = ""
var chart_layout_path: String = ""


func to_dictionary() -> Dictionary:
	return {
		"project_id": project_id,
		"display_name": display_name,
		"machine_path": machine_path,
		"thruster_template_path": thruster_template_path,
		"record_path": record_path,
		"chart_layout_path": chart_layout_path,
	}


func load_dictionary(data: Dictionary) -> void:
	project_id = str(data.get("project_id", project_id))
	display_name = str(data.get("display_name", display_name))
	machine_path = str(data.get("machine_path", machine_path))
	thruster_template_path = str(data.get("thruster_template_path", thruster_template_path))
	record_path = str(data.get("record_path", record_path))
	chart_layout_path = str(data.get("chart_layout_path", chart_layout_path))
