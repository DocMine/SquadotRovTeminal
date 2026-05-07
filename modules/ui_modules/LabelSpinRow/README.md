# LabelSpinRow

标签加数值输入框的基础行模块。

## 结构

```text
ui_modules/LabelSpinRow/
  LabelSpinRow.tscn
  LabelSpinRow.gd
  README.md
```

## 能力

- 封装 `SpinBox` 的常用行布局
- 对外转发 `value_changed`
- 适合超时、步进、长度、计数等数值参数

## 关键接口

- `signal value_changed(value: float)`
- `set_label_text(value: String) -> void`
- `set_value_number(value: float) -> void`
- `get_value_number() -> float`
- `configure(minimum: float, maximum: float, step: float, rounded: bool = true) -> void`

## 用法

```gdscript
@onready var timeout_row: LabelSpinRow = %TimeoutRow

func _ready() -> void:
	timeout_row.set_label_text(UICore.translate("AUTOMATION_LABEL_TIMEOUT_DELAY"))
	timeout_row.configure(0.0, 10000.0, 1.0, true)
	timeout_row.set_value_number(1000.0)
```

## 约束

- 模块只负责单个数值输入，不组合校验逻辑；跨字段约束由外层处理。
