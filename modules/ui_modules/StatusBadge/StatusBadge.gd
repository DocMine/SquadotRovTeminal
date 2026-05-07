## 共享状态徽标组件，用于展示在线、离线、警告和错误等简短状态。
## 该脚本属于通用 UI 模块层，父级通过公开方法一次性设置文案与颜色。
@tool
class_name StatusBadge
extends PanelContainer

@onready var label_node: Label = %LabelNode


## 刷新徽标文本和整体颜色。
## 参数 `text_value` 是状态文案；参数 `color_value` 是对应的语义颜色。
## 示例：串口连接栏显示在线状态。
## `status_badge.set_status("在线", UICore.get_success_color())`
func set_status(text_value: String, color_value: Color) -> void:
	label_node.text = text_value
	self_modulate = color_value
