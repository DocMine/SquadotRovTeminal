extends Node3D
class_name Thruster

## 推进器（Thruster）
##
## 这是一个挂在 ROV 下的 Node3D，用来把“控制指令 command”转换为“施加在 ROV 上的力”。
##
## 字段说明：
## - command：[-1, 1] 的归一化指令，通常由控制器/手动输入赋值
## - max_thrust_n：最大推力（牛顿），实际推力 = clamp(command)*max_thrust_n
## - axis_local：推进器推力方向（本地坐标）。默认 (0,0,-1) 表示朝 -Z 推
##
## 计算流程：
## - get_thrust_n()：得到标量推力（单位：N）
## - get_force_global()：把 axis_local 变换到世界坐标并乘以推力，得到世界坐标力向量
##
## 注意：
## - 这里不直接对 ROV 施力；ROVController 会遍历推进器并在其位置施加该力。

@export var id: int = 0
@export var max_thrust_n: float = 30.0
@export var axis_local: Vector3 = Vector3(0, 0, -1)
@export var command: float = 0.0


func get_thrust_n() -> float:
	# 把 command 夹在 [-1, 1]，再按最大推力缩放
	return clamp(command, -1.0, 1.0) * max_thrust_n


func get_force_global() -> Vector3:
	# 将本地推力轴变换到世界坐标，并输出世界坐标力向量
	var dir = (global_transform.basis * axis_local).normalized()
	return dir * get_thrust_n()
