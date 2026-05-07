## Wraps a titled panel section with a stable body container for page assembly.
## Mount on `modules/ui_modules/PanelCard/PanelCard.tscn`, keep the visible title in
## Chinese for editor readability, and use `title_key` for runtime localization.
@tool
class_name PanelCard
extends PanelContainer

@export var title_key: String = "MODULE_PANEL_DEFAULT"

@onready var title_label: Label = %TitleLabel
@onready var body_container: VBoxContainer = %Body


## Initializes the localized title when the card enters the scene tree.
func _ready() -> void:
	_apply_localization()


## Refreshes the localized title when the active locale changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_localization()


## Applies the exported localization key while keeping Chinese defaults visible in the editor.
func _apply_localization() -> void:
	UICore.ensure_localization_ready()
	if not title_key.is_empty():
		title_label.text = UICore.translate(title_key)


## Overrides the visible card title directly.
## Example:
## `card.set_title_text("项目资源")`
func set_title_text(value: String) -> void:
	title_label.text = value


## Returns the body container used by callers to place child controls.
## Example:
## `card.get_content_container().add_child(custom_row)`
func get_content_container() -> VBoxContainer:
	return body_container
