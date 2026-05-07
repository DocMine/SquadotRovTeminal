# LabelValueRow

标签加只读数值显示的基础行模块。

## 结构

```text
ui_modules/LabelValueRow/
  LabelValueRow.tscn
  LabelValueRow.gd
  README.md
```

## 能力

- 用于展示统计值、状态值、当前结果等只读信息
- 标签和值分离，便于单独更新本地化或数据

## 关键接口

- `set_label_text(value: String) -> void`
- `set_value_text(value: String) -> void`

## 用法

```gdscript
@onready var rx_row: LabelValueRow = %RxRow

func _ready() -> void:
	rx_row.set_label_text(UICore.translate("COMMON_STAT_RX"))
	rx_row.set_value_text("0")
```

## 约束

- 仅用于展示，不要把交互控件嵌进这个模块。
