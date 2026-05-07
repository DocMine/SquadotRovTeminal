# TauRealtimeChart

用于显示多条共享时间轴实时数据的内建曲线图模块，不再依赖外部 `tau-plot` 插件。

## 结构

```text
ui_modules/TauRealtimeChart/
  TauRealtimeChart.tscn
  TauRealtimeChart.gd
  TauPlotCanvas.gd
  README.md
```

## 能力

- 通过 `set_series(series)` 接收 `Dictionary[String, Array[Vector2]]`。
- 自动按序列名排序并生成图例。
- 对输入数据做点数上限控制，避免一次绘制过多点。
- 使用 Godot 原生绘图 API 渲染网格、折线和采样点。

## 最小示例

```gdscript
@onready var chart: TauRealtimeChart = %TauRealtimeChart

func _process(_delta: float) -> void:
	chart.set_series({
		"depth": depth_points,
		"speed": speed_points,
	})
```

## 约束

- 输入数组应按 `Vector2.x` 递增排列，否则折线顺序会和真实时间轴不一致。
- 模块负责通用图表展示，不承担业务统计、单位换算或采样缓存管理。
