extends Node3D
class_name ThrusterSim
# 工程级推进器模型（PWM → 推力）

# ===== 基本参数 =====
## 正向最大推力
@export var max_forward_thrust:float = 30.0
## 反向最大推力
@export var max_reverse_thrust:float = 20.0
## 推力响应速度
@export var response:float = 100
## 推力方向（局部）            
@export var direction := Vector3.UP  

# ===== PWM / 指令建模 =====
## PWM 死区
@export var deadzone:float = 0.05

## 非线性指数（桨特性）         
@export var thrust_exponent:float = 2.0

# ===== 状态 =====
var command:float = 0.0                         # -1 ~ 1（控制输入）
var target_thrust:float = 0.0                   # 目标推力
var thrust:float = 0.0                          # 当前推力

# ===== 主更新 =====
func update_thruster(delta: float) -> void:
	target_thrust = pwm_to_thrust(command)
	# 计算响应时间，不超过1.0
	var resSpeed:float = clampf(response * delta, 0.0, 1.0)
	if global_position.y > 0:
		# 如果推进器出水，则推力为0
		thrust = 0
	else:
		thrust = lerp(thrust, target_thrust, resSpeed)

# ===== PWM → 推力 =====
func pwm_to_thrust(cmd: float) -> float:
	var x:float = clamp(cmd, -1.0, 1.0)
	# 死区
	if abs(x) < deadzone:
		return 0.0
	# 归一化到死区外
	var Thesign:float = signf(x)
	var norm:float = (abs(x) - deadzone) / (1.0 - deadzone)
	norm = clamp(norm, 0.0, 1.0)
	# 非线性桨模型
	norm = pow(norm, thrust_exponent)
	# 正反推力不对称
	if Thesign > 0.0:
		return norm * max_forward_thrust
	else:
		return -norm * max_reverse_thrust

# ===== 对外接口 =====
func get_force() -> Vector3:
	return global_transform.basis * direction * thrust

func get_thrust() -> float:
	return thrust

func set_commd(comm:float):
	command = comm
