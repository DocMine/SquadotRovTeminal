# StatusBadge

用于展示短状态文本和状态色的小型徽标模块。

## 结构

```text
ui_modules/StatusBadge/
  StatusBadge.tscn
  StatusBadge.gd
  README.md
```

## 能力

- 用统一的胶囊样式显示当前状态
- 支持按状态切换文本和颜色
- 适合在线状态、运行状态、连接状态等场景

## 关键接口

- `set_status(text_value: String, color_value: Color) -> void`

## 用法

```gdscript
@onready var badge: StatusBadge = %StatusBadge

func _ready() -> void:
	badge.set_status(
		UICore.translate("SERIAL_OFFLINE"),
		UICore.get_muted_color()
	)
```

## 约束

- 颜色由外部传入，模块自身不做状态枚举判断。
