## Renders a reusable `Label + OptionButton` row for editor-visible forms.
## Mount on `modules/ui_modules/LabelOptionRow/LabelOptionRow.tscn` and use
## `label_key` to localize the fixed label at runtime.
@tool
class_name LabelOptionRow
extends HBoxContainer

signal option_selected(index: int)

@export var label_key: String = "MODULE_LABEL_OPTION_DEFAULT"

@onready var label_node: Label = %LabelNode
@onready var option_node: OptionButton = %OptionNode


## Initializes the localized label and forwards selection changes.
func _ready() -> void:
	_apply_localization()
	option_node.item_selected.connect(func(index: int) -> void:
		option_selected.emit(index)
	)


## Refreshes the localized label when the active locale changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_localization()


## Applies the exported localization key while keeping Chinese scene defaults readable.
func _apply_localization() -> void:
	UICore.ensure_localization_ready()
	if not label_key.is_empty():
		label_node.text = UICore.translate(label_key)


## Overrides the visible label text directly.
## Example:
## `row.set_label_text("预设")`
func set_label_text(value: String) -> void:
	label_node.text = value


## Rebuilds the option list with the provided visible labels.
## Example:
## `row.set_options(PackedStringArray(["稳定布局", "高推力布局"]))`
func set_options(values: PackedStringArray) -> void:
	option_node.clear()
	for value in values:
		option_node.add_item(value)


## Selects an option index when it exists.
## Example:
## `row.select_index(0)`
func select_index(index: int) -> void:
	if index >= 0 and index < option_node.item_count:
		option_node.select(index)


## Returns the selected option index.
## Example:
## `var preset_index: int = row.get_selected_index()`
func get_selected_index() -> int:
	return option_node.selected


## Returns the selected option text, or an empty string when nothing is selected.
## Example:
## `var preset_name: String = row.get_selected_text()`
func get_selected_text() -> String:
	return option_node.get_item_text(option_node.selected) if option_node.selected >= 0 else ""


## Exposes the wrapped `OptionButton` for advanced configuration.
## Example:
## `row.get_option_button().disabled = true`
func get_option_button() -> OptionButton:
	return option_node
