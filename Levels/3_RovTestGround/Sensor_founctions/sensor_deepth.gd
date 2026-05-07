## 本脚本负责对应场景或模块的局部逻辑与节点协作。
extends SensorBase
class_name DepthSensor
## 深度计（Pressure Sensor 简化版）

@export_group("绑定")

@export var body: RigidBody3D
@export var state: LegacyROVState


func _sample() -> void:
	if body == null or state == null:
		return
	var depth: float = -body.global_position.y
	state.depth = _add_noise(depth)
