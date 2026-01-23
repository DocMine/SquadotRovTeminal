extends Node
class_name SensorBase
## 传感器基类（只负责：采样 + 噪声 + 输出）
@export_group("基础参数")

## 采样频率（Hz）
@export var sample_rate: float = 5.0

## 是否启用
@export var enabled: bool = true

## 高斯噪声标准差
@export var noise_sigma: float = 0.02


var _time_acc := 0.0


func _physics_process(delta: float) -> void:
	if not enabled:
		return

	_time_acc += delta
	if _time_acc >= 1.0 / sample_rate:
		_time_acc = 0.0
		_sample()


## 子类实现
func _sample() -> void:
	pass


## 噪声工具
func _add_noise(value: float) -> float:
	if noise_sigma <= 0.0:
		return value
	return value + randfn(0.0, noise_sigma)
