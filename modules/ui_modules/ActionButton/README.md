# ActionButton

带有统一主题变体和可选点击反馈的按钮模块。

## 结构

```text
ui_modules/ActionButton/
  ActionButton.tscn
  ActionButton.gd
  README.md
```

## 能力

- 统一 `PRIMARY`、`SECONDARY`、`DANGER` 三种视觉变体
- 默认通过 `UICore` 统一触发点击音效
- 适合作为所有操作按钮的基础按钮场景

## 关键接口

- `variant: ActionButton.Variant`
- `enable_click_sound: bool`
- `set_variant(value: Variant) -> void`

## 用法

```gdscript
@onready var send_button: ActionButton = %SendButton

func _ready() -> void:
	send_button.text = UICore.translate("SEND_BUTTON_SEND")
	send_button.variant = ActionButton.Variant.PRIMARY
	send_button.pressed.connect(_on_send_pressed)
```

## 约束

- 只负责按钮表现和交互反馈，不承载业务逻辑。
- 业务侧统一在外部脚本里设置文案、本地化和信号连接。
