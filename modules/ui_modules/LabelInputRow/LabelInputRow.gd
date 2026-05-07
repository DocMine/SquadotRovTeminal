## Renders a reusable `Label + LineEdit` row for form-style panels.
## Mount on `modules/ui_modules/LabelInputRow/LabelInputRow.tscn` and configure
## `label_key` when the visible label should participate in runtime localization.
@tool
class_name LabelInputRow
extends HBoxContainer

signal text_changed(value: String)

@export var label_key: String = "MODULE_LABEL_INPUT_DEFAULT"

@onready var label_node: Label = %LabelNode
@onready var input_node: LineEdit = %InputNode


## Initializes localization and forwards text changes to the parent page.
func _ready() -> void:
	_apply_localization()
	input_node.text_changed.connect(func(value: String) -> void:
		text_changed.emit(value)
	)


## Refreshes the localized label when the application language changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_localization()


## Applies the exported localization key while preserving Chinese editor defaults.
func _apply_localization() -> void:
	UICore.ensure_localization_ready()
	if not label_key.is_empty():
		label_node.text = UICore.translate(label_key)


## Overrides the visible label text directly.
## Example:
## `row.set_label_text("机器文件")`
func set_label_text(value: String) -> void:
	label_node.text = value


## Updates the editable text value.
## Example:
## `row.set_text_value("demo.json")`
func set_text_value(value: String) -> void:
	input_node.text = value


## Returns the current editable text value.
## Example:
## `var file_name: String = row.get_text_value()`
func get_text_value() -> String:
	return input_node.text


## Updates the placeholder shown inside the input field.
## Example:
## `row.set_placeholder("请输入文件名")`
func set_placeholder(value: String) -> void:
	input_node.placeholder_text = value
