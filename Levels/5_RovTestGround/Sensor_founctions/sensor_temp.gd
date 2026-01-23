extends SensorBase
class_name TempSensor
## 水温传感器（简单模型）

@export_group("模型参数")

## 表层温度
@export var surface_temp: float = 20.0

## 温度梯度（°C / m）
@export var gradient: float = -0.03


@export_group("绑定")

@export var state: ROVState


func _sample() -> void:
	if state == null:
		return

	var temp := surface_temp + gradient * state.depth
	state.water_temperature = _add_noise(temp)
