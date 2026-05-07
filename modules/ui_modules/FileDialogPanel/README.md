# FileDialogPanel

Reusable file path panel for save/load workflows.

## Features

- Edit file name and full path in one place
- Open a system file dialog through Godot `FileDialog`
- Emit independent save/load signals with an absolute path
- Accept files dragged directly from the operating system file manager
- Route a window-level file drop to the specific `FileDialogPanel` instance under the cursor
- Supports per-instance label/button localization keys and file filters

## Structure

```text
ui_modules/FileDialogPanel/
  FileDialogPanel.tscn
  FileDialogPanel.gd
  icons/
  styles/
  README.md
```

## Signals

- `save_requested(path: String)`: emitted when the save button is pressed
- `load_requested(path: String)`: emitted when the load button is pressed
- `path_changed(path: String)`: emitted when the effective path changes
- `external_files_dropped(panel: FileDialogPanel, paths: PackedStringArray)`: emitted when this specific panel receives a system file drop

## Inspector Params

- `title_key`
- `name_label_key`
- `path_label_key`
- `browse_button_key`
- `save_button_key`
- `load_button_key`
- `dialog_title_key`
- `default_path`
- `browse_file_mode`
- `file_filters`
- `show_load_button`
- `show_save_button`
- `enable_system_file_drop`
- `emit_load_requested_on_file_drop`

## Usage

Instantiate the scene and connect the signals:

```gdscript
var file_panel: FileDialogPanel = preload("res://ui_modules/FileDialogPanel/FileDialogPanel.tscn").instantiate() as FileDialogPanel
file_panel.default_path = "user://square_dot_serial/recipes/automation.json"
file_panel.browse_file_mode = FileDialog.FILE_MODE_OPEN_FILE
file_panel.file_filters = PackedStringArray(["*.json ; JSON files", "*.* ; All files"])
file_panel.save_requested.connect(_on_save_requested)
file_panel.load_requested.connect(_on_load_requested)
file_panel.external_files_dropped.connect(_on_panel_files_dropped)
add_child(file_panel)
```

If the same screen contains multiple file panels, connect them all to one callback and use the emitted panel parameter to identify the actual drop target:

```gdscript
func _on_panel_files_dropped(panel: FileDialogPanel, paths: PackedStringArray) -> void:
	print(panel.name, paths)
```

## Notes

- Paths emitted by the panel are absolute paths when the input starts from `user://` or `res://`.
- The panel keeps both a file name field and a path field so it can fit desktop-style workflows.
- System file drops are received through Godot's window-level drop signal, then routed to the panel whose subtree is currently hovered.
- When `emit_load_requested_on_file_drop` is enabled, dropping a readable path behaves like a direct load action for that panel.
