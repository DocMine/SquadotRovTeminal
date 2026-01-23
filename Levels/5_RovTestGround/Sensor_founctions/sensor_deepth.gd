extends SensorBase
class_name DepthSensor
## 深度计（Pressure Sensor 简化版）

@export_group("绑定")

@export var body: RigidBody3D
@export var state: ROVState


func _sample() -> void:
	if body == null or state == null:
		return
	var depth := -body.global_position.y
	state.depth = _add_noise(depth)
