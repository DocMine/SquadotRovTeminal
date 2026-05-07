# LabelInputRow

标签加单行输入框的基础行模块。

## 结构

```text
ui_modules/LabelInputRow/
  LabelInputRow.tscn
  LabelInputRow.gd
  README.md
```

## 能力

- 固定一行内的标签和 `LineEdit`
- 对外转发 `text_changed`
- 适合文件名、路径、字段名等短文本输入

## 关键接口

- `signal text_changed(value: String)`
- `set_label_text(value: String) -> void`
- `set_text_value(value: String) -> void`
- `get_text_value() -> String`
- `set_placeholder(value: String) -> void`

## 用法

```gdscript
@onready var name_row: LabelInputRow = %NameRow

func _ready() -> void:
	name_row.set_label_text(UICore.translate("PROTOCOL_LABEL_NAME"))
	name_row.set_placeholder(UICore.translate("PROTOCOL_PACKET_NAME_PLACEHOLDER"))
	name_row.text_changed.connect(_on_name_changed)
```

## 约束

- 只承载短文本输入；多行内容统一使用 `TextEdit`。
