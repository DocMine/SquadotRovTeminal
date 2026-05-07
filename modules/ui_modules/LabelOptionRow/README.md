# LabelOptionRow

标签加下拉框的基础行模块。

## 结构

```text
ui_modules/LabelOptionRow/
  LabelOptionRow.tscn
  LabelOptionRow.gd
  README.md
```

## 能力

- 统一标签与 `OptionButton` 布局
- 对外转发选项切换事件
- 适合模式、类型、字节序等枚举项配置

## 关键接口

- `signal option_selected(index: int)`
- `set_label_text(value: String) -> void`
- `set_options(values: PackedStringArray) -> void`
- `select_index(index: int) -> void`
- `get_selected_index() -> int`
- `get_selected_text() -> String`
- `get_option_button() -> OptionButton`

## 用法

```gdscript
@onready var mode_row: LabelOptionRow = %ModeRow

func _ready() -> void:
	mode_row.set_label_text(UICore.translate("PROTOCOL_LABEL_KIND"))
	mode_row.set_options(PackedStringArray([
		UICore.translate("PROTOCOL_VALUE_KIND_CONSTANT"),
		UICore.translate("PROTOCOL_VALUE_KIND_DATA"),
		UICore.translate("PROTOCOL_VALUE_KIND_CHECKSUM"),
	]))
	mode_row.option_selected.connect(_on_mode_selected)
```

## 约束

- 如果业务需要保留原始值，外层应使用 `OptionButton.set_item_metadata()` 保存原始枚举值。
