## 本脚本负责对应场景或模块的局部逻辑与节点协作。
extends RefCounted
class_name PIDController

var P: float
var I: float
var D: float

var prev_error: float = 0.0
var integral: float = 0.0

# 积分限幅（非常重要）
var integral_limit: float = 0.0   # 0 表示不限制

# 输出限幅（强烈建议用）
var output_limit: float = 0.0     # 0 表示不限制

func _init(pp: float, ii: float, dd: float):
	P = pp
	I = ii
	D = dd

func set_pid(pp: float, ii: float, dd: float):
	P = pp
	I = ii
	D = dd

func clear_error():
	prev_error = 0.0
	integral = 0.0

func calculate(target: float, current: float, delta: float) -> float:
	if delta <= 0.0:
		return 0.0

	# 1. 误差
	var error = target - current

	# 2. 积分项（带 anti-windup）
	integral += error * delta
	if integral_limit > 0.0:
		integral = clamp(integral, -integral_limit, integral_limit)

	# 3. 微分项（基于 error）
	var derivative = (error - prev_error) / delta
	prev_error = error

	# 4. PID 合成
	var output = P * error + I * integral + D * derivative

	# 5. 输出限幅（保护执行器 + 防止积分风up）
	if output_limit > 0.0:
		output = clamp(output, -output_limit, output_limit)

	return output
