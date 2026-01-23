extends Node
class_name RovAssembler
# 这个脚本用于构建场景与仿真场景之间的转换

@export var sim_rov_scene: PackedScene

func build_simulation(build_root: Node3D) -> Node3D:
	var sim_rov := sim_rov_scene.instantiate()
	var body := sim_rov.get_node("Body") as RigidBody3D

	for child in build_root.get_children():
		if child.has_method("get_part_config"):
			_spawn_part(child.get_part_config(), body)
	return sim_rov

func _spawn_part(cfg: Dictionary, body: RigidBody3D):
	match cfg.type:
		"thruster":
			var t := ThrusterSim.new()
			t.data = cfg.data
			t.global_transform = cfg.transform
			body.add_child(t)


func _on_button_pressed() -> void:
	var sim = build_simulation($"../buildroot")
	get_tree().current_scene.add_child(sim)
	pass # Replace with function body.
