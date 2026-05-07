## 共享“标签 + 只读值”行组件，用于状态栏、仪表板和摘要面板。
## 该脚本属于通用 UI 模块层，外部只应通过公开方法设置标签和值文本。
@tool
class_name LabelValueRow
extends HBoxContainer

@onready var label_node: Label = %LabelNode
@onready var value_node: Label = %ValueNode


## 设置左侧标签文本。
## 参数 `value` 是要显示的标签内容。
## 示例：刷新仪表盘项目名称。
## `depth_row.set_label_text("深度")`
func set_label_text(value: String) -> void:
	label_node.text = value


## 设置右侧值文本。
## 参数 `value` 是要显示的只读值。
## 示例：刷新当前状态读数。
## `depth_row.set_value_text("1.25 m")`
func set_value_text(value: String) -> void:
	value_node.text = value
