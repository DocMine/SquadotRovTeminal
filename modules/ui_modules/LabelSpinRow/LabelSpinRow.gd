## Renders a reusable `Label + SpinBox` row for numeric parameter editing.
## Mount on `modules/ui_modules/LabelSpinRow/LabelSpinRow.tscn` and provide
## `label_key` when the fixed label participates in runtime localization.
@tool
class_name LabelSpinRow
extends HBoxContainer

signal value_changed(value: float)

@export var label_key: String = "MODULE_LABEL_SPIN_DEFAULT"

@onready var label_node: Label = %LabelNode
@onready var spin_node: SpinBox = %SpinNode


## Initializes the localized label and forwards numeric changes.
func _ready() -> void:
	_apply_localization()
	spin_node.value_changed.connect(func(value: float) -> void:
		value_changed.emit(value)
	)


## Refreshes the localized label when the active locale changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_localization()


## Applies the exported localization key while keeping the scene preview readable in Chinese.
func _apply_localization() -> void:
	UICore.ensure_localization_ready()
	if not label_key.is_empty():
		label_node.text = UICore.translate(label_key)


## Overrides the visible label text directly.
## Example:
## `row.set_label_text("质量 kg")`
func set_label_text(value: String) -> void:
	label_node.text = value


## Updates the current numeric value.
## Example:
## `row.set_value_number(50.0)`
func set_value_number(value: float) -> void:
	spin_node.value = value


## Returns the current numeric value.
## Example:
## `var mass_kg: float = row.get_value_number()`
func get_value_number() -> float:
	return spin_node.value


## Configures the numeric range and increment behavior.
## Example:
## `row.configure(0.0, 100.0, 0.1, false)`
func configure(minimum: float, maximum: float, step: float, rounded: bool = true) -> void:
	spin_node.min_value = minimum
	spin_node.max_value = maximum
	spin_node.step = step
	spin_node.rounded = rounded
