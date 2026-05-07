## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name SensorSuite
extends RefCounted

const SensorFrameScript = preload("res://Levels/5_rovsim/scripts/sensors/sensor_frame.gd")


static func build_frame(time_s: float, body: RigidBody3D, current_velocity_mps: Vector3, net_force_n: Vector3, mass_kg: float) -> RefCounted:
	var sensor_frame: RefCounted = SensorFrameScript.new()
	if body == null:
		return sensor_frame
	var deterministic_noise: Vector3 = Vector3(
		sin(time_s * 1.7) * 0.006,
		sin(time_s * 1.1 + 0.4) * 0.006,
		cos(time_s * 1.3) * 0.006
	)
	var rotation: Quaternion = body.global_transform.basis.get_rotation_quaternion()
	var euler: Vector3 = rotation.get_euler()
	sensor_frame.set("time_s", time_s)
	sensor_frame.set("imu_acceleration_mps2", net_force_n / maxf(1.0, mass_kg))
	sensor_frame.set("imu_angular_velocity_radps", body.angular_velocity)
	sensor_frame.set("imu_orientation_quat", rotation)
	sensor_frame.set("depth_m", maxf(0.0, -body.global_position.y) + deterministic_noise.y)
	sensor_frame.set("compass_heading_rad", euler.y + deterministic_noise.x)
	sensor_frame.set("dvl_velocity_mps", body.linear_velocity - current_velocity_mps + deterministic_noise)
	sensor_frame.set("position_observation_m", body.global_position + deterministic_noise)
	sensor_frame.set("sensor_health", 1.0)
	sensor_frame.set("noise_level", deterministic_noise.length())
	sensor_frame.set("delay_s", 0.0)
	return sensor_frame
