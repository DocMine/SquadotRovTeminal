extends SensorBase
class_name IMUSensor
## IMU：姿态 + 角速度

@export_group("绑定")

## 数据来源
@export var body: RigidBody3D

## 状态写入目标
@export var state: ROVState


func _sample() -> void:
	if body == null or state == null:
		return

	# --- 姿态 ---
	var q := body.global_transform.basis.get_rotation_quaternion()

	# --- 角速度 ---
	var w := body.angular_velocity

	# 写入状态（带噪声）
	state.imu_orientation = q
	state.imu_angular_velocity = Vector3(
		_add_noise(w.x),
		_add_noise(w.y),
		_add_noise(w.z)
	)
