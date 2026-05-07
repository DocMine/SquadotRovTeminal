## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ROVPresetLibrary
extends RefCounted

const MachineSerializerScript = preload("res://Levels/5_rovsim/scripts/io/machine_serializer.gd")


static func get_preset_ids() -> PackedStringArray:
	return PackedStringArray(["stable", "unstable", "high_power"])


static func get_preset_title_key(preset_id: String) -> String:
	match preset_id:
		"unstable":
			return "PRESET_UNSTABLE"
		"high_power":
			return "PRESET_HIGH_POWER"
		_:
			return "PRESET_STABLE"


static func get_preset(preset_id: String) -> Dictionary:
	var file_path: String = _preset_path(preset_id)
	if ResourceLoader.exists(file_path) or FileAccess.file_exists(file_path):
		var machine: MachineConfig = MachineSerializerScript.load(file_path)
		return machine.to_runtime_dictionary(0.0)
	match preset_id:
		"unstable":
			return _unstable_preset()
		"high_power":
			return _high_power_preset()
		_:
			return _stable_preset()


static func _preset_path(preset_id: String) -> String:
	match preset_id:
		"unstable":
			return "res://Levels/5_rovsim/presets/machines/unstable_offset_cob.rovmachine.json"
		"high_power":
			return "res://Levels/5_rovsim/presets/machines/high_power_4_thruster.rovmachine.json"
		_:
			return "res://Levels/5_rovsim/presets/machines/stable_4_thruster.rovmachine.json"


static func _stable_preset() -> Dictionary:
	return {
		"mass_kg": 50.0,
		"displaced_volume_m3": 0.051,
		"center_of_mass_m": Vector3(0.0, -0.04, 0.0),
		"center_of_buoyancy_m": Vector3(0.0, 0.18, 0.0),
		"drag_coefficients": Vector3(42.0, 58.0, 46.0),
		"angular_drag": Vector3(3.2, 3.8, 3.2),
		"thrusters": [
			_thruster("T1", Vector3(-0.48, 0.0, 0.34), Vector3.ZERO, 34.0),
			_thruster("T2", Vector3(0.48, 0.0, 0.34), Vector3.ZERO, 34.0),
			_thruster("T3", Vector3(-0.48, 0.0, -0.34), Vector3.ZERO, 34.0),
			_thruster("T4", Vector3(0.48, 0.0, -0.34), Vector3.ZERO, 34.0),
			_vertical_thruster("T5", Vector3(-0.28, 0.0, 0.0), 30.0),
			_vertical_thruster("T6", Vector3(0.28, 0.0, 0.0), 30.0),
		],
	}


static func _unstable_preset() -> Dictionary:
	return {
		"mass_kg": 50.0,
		"displaced_volume_m3": 0.049,
		"center_of_mass_m": Vector3(0.18, 0.02, 0.0),
		"center_of_buoyancy_m": Vector3(-0.12, 0.08, 0.12),
		"drag_coefficients": Vector3(38.0, 48.0, 40.0),
		"angular_drag": Vector3(1.8, 2.2, 1.6),
		"thrusters": [
			_thruster("T1", Vector3(-0.62, 0.03, 0.36), Vector3(0.0, deg_to_rad(-7.0), 0.0), 36.0),
			_thruster("T2", Vector3(0.38, -0.02, 0.29), Vector3(0.0, deg_to_rad(15.0), 0.0), 36.0),
			_thruster("T3", Vector3(-0.52, 0.01, -0.30), Vector3(0.0, deg_to_rad(5.0), 0.0), 24.0),
			_thruster("T4", Vector3(0.54, 0.0, -0.42), Vector3(0.0, deg_to_rad(-18.0), 0.0), 42.0),
		],
	}


static func _high_power_preset() -> Dictionary:
	return {
		"mass_kg": 52.0,
		"displaced_volume_m3": 0.053,
		"center_of_mass_m": Vector3(0.0, -0.05, 0.0),
		"center_of_buoyancy_m": Vector3(0.0, 0.18, 0.0),
		"drag_coefficients": Vector3(54.0, 70.0, 58.0),
		"angular_drag": Vector3(4.0, 4.2, 4.0),
		"thrusters": [
			_thruster("T1", Vector3(-0.55, 0.0, 0.38), Vector3.ZERO, 70.0),
			_thruster("T2", Vector3(0.55, 0.0, 0.38), Vector3.ZERO, 70.0),
			_thruster("T3", Vector3(-0.55, 0.0, -0.38), Vector3.ZERO, 70.0),
			_thruster("T4", Vector3(0.55, 0.0, -0.38), Vector3.ZERO, 70.0),
			_vertical_thruster("T5", Vector3(-0.32, 0.0, 0.0), 58.0),
			_vertical_thruster("T6", Vector3(0.32, 0.0, 0.0), 58.0),
		],
	}


static func _thruster(label: String, position_m: Vector3, rotation_rad: Vector3, max_thrust_n: float) -> Dictionary:
	return {
		"name": "Thruster_%s" % label,
		"label": label,
		"position_m": position_m,
		"rotation_rad": rotation_rad,
		"max_thrust_n": max_thrust_n,
		"local_force_axis": Vector3(0.0, 0.0, -1.0),
		"command": 0.0,
	}


static func _vertical_thruster(label: String, position_m: Vector3, max_thrust_n: float) -> Dictionary:
	return _thruster(label, position_m, Vector3(deg_to_rad(90.0), 0.0, 0.0), max_thrust_n)
