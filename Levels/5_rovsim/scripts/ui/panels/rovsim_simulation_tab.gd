## Controls the simulation tab overlay area inside the ROV simulator workbench.
## Owns the force legend texts and provides pointer hit testing for the 3D viewport tab.
## Mount this script on the `SimulationTab` Control in `scenes/main/main.tscn`.
@tool
class_name ROVSimSimulationTab
extends Control

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

@onready var force_legend_title: Label = get_node("ForceLegendPanel/ForceLegendMargin/ForceLegendVBox/ForceLegendTitle") as Label
@onready var force_legend_text: RichTextLabel = get_node("ForceLegendPanel/ForceLegendMargin/ForceLegendVBox/ForceLegendText") as RichTextLabel


## Refreshes the legend labels for the current locale.
## Example:
## `simulation_tab.apply_static_texts()`
func apply_static_texts() -> void:
	force_legend_title.text = AppLocalizationScript.translate("FORCE_LEGEND_TITLE")
	force_legend_text.text = AppLocalizationScript.translate("FORCE_LEGEND_TEXT").replace("\\n", "\n")


## Reports whether the pointer is inside the simulation tab rectangle.
## Example:
## `var inside: bool = simulation_tab.is_pointer_active(get_viewport().get_mouse_position())`
func is_pointer_active(screen_position: Vector2) -> bool:
	return get_global_rect().has_point(screen_position)
