## 共享动作按钮组件，统一封装按钮变体样式与点击音效接入。
## 该脚本适用于工具栏按钮、确认按钮和危险操作按钮等高频 UI 入口。
@tool
class_name ActionButton
extends Button

enum Variant {
	PRIMARY,
	SECONDARY,
	DANGER,
}

@export var variant: Variant = Variant.SECONDARY
@export var enable_click_sound: bool = true


## 初始化按钮样式，并在运行时按配置接入统一点击音效。
func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_variant()
		return
	if enable_click_sound:
		pressed.connect(_on_pressed)
	_apply_variant()


## 处理按钮点击后的统一音效播放。
func _on_pressed() -> void:
	UICore.play_button_click()


## 切换按钮视觉变体。
## 参数 `value` 表示目标样式枚举。
## 示例：父级面板把主发送按钮切到强调态。
## `send_button.set_variant(ActionButton.Variant.PRIMARY)`
func set_variant(value: Variant) -> void:
	variant = value
	_apply_variant()


## 根据当前 `variant` 刷新按钮自身颜色。
func _apply_variant() -> void:
	match variant:
		Variant.PRIMARY:
			self_modulate = UICore.get_accent_color()
		Variant.DANGER:
			self_modulate = UICore.get_danger_color()
		_:
			self_modulate = Color.WHITE
