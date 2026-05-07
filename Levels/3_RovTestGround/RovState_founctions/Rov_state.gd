## 本脚本负责对应场景或模块的局部逻辑与节点协作。
extends Node
class_name LegacyROVState
## ROV 状态总线（单一事实源）

# ===============================
# 真实物理状态（Ground Truth）
# ===============================

@export_group("绑定")

## 物理刚体（仅用于真实值）
@export var body: RigidBody3D

var true_position: Vector3
var true_linear_velocity: Vector3
var true_angular_velocity: Vector3
var true_orientation: Quaternion


# ===============================
# 传感器输出（控制 / UI 用）
# ===============================
## IMU
var imu_orientation: Quaternion
var imu_angular_velocity: Vector3
## 深度
var depth: float
## 温度
var water_temperature: float

# ===============================
# 系统状态
# ===============================
var control_mode: String = "MANUAL"
var thruster_commands: Dictionary = {}


# ===============================
# 同步真实状态
# ===============================
func _physics_process(_delta: float) -> void:
	if body == null:
		return
	true_position = body.global_position
	true_linear_velocity = body.linear_velocity
	true_angular_velocity = body.angular_velocity
	true_orientation = body.global_transform.basis.get_rotation_quaternion()

# ===============================
# 对外快照
# ===============================
func to_dict() -> Dictionary:
	return {
		"depth": depth,
		"temperature": water_temperature,
		"imu_orientation": imu_orientation,
		"imu_angular_velocity": imu_angular_velocity,
		"mode": control_mode
	}
