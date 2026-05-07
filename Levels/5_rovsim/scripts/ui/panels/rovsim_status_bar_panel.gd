## Controls the bottom status bar for the integrated ROV simulator.
## Owns the single status text label shown below the workbench.
## Mount this script on the `StatusBar` PanelContainer in `scenes/main/main.tscn`.
@tool
class_name ROVSimStatusBarPanel
extends PanelContainer

@onready var status_bar_text: Label = get_node("StatusBarMargin/StatusBarText") as Label


## Updates the visible status text shown in the bottom bar.
## Example:
## `status_bar_panel.set_status_text("Simulation running")`
func set_status_text(text_value: String) -> void:
	status_bar_text.text = text_value
