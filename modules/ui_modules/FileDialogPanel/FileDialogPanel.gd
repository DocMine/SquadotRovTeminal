## 共享文件路径面板，统一封装路径显示、系统文件对话框、保存/加载请求和外部文件拖入。
## 该脚本属于通用 UI 模块层，适用于记录、配方、导出文件等所有“路径 + 浏览 + 保存/加载”场景。
@tool
class_name FileDialogPanel
extends VBoxContainer

signal save_requested(path: String)
signal load_requested(path: String)
signal path_changed(path: String)
signal external_files_dropped(panel: FileDialogPanel, paths: PackedStringArray)

@export var title_key: String = "FILE_DIALOG_TITLE"
@export var name_label_key: String = "FILE_DIALOG_LABEL_NAME"
@export var path_label_key: String = "FILE_DIALOG_LABEL_PATH"
@export var browse_button_key: String = "FILE_DIALOG_BUTTON_BROWSE"
@export var save_button_key: String = "FILE_DIALOG_BUTTON_SAVE"
@export var load_button_key: String = "FILE_DIALOG_BUTTON_LOAD"
@export var dialog_title_key: String = "FILE_DIALOG_DIALOG_TITLE"
@export var default_path: String = ""
@export var browse_file_mode: FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE
@export var file_filters: PackedStringArray = PackedStringArray()
@export var show_load_button: bool = true
@export var show_save_button: bool = true
@export var enable_system_file_drop: bool = true
@export var emit_load_requested_on_file_drop: bool = true

@onready var title_label: Label = %TitleLabel
@onready var file_name_row: LabelInputRow = %FileNameRow
@onready var path_row: LabelInputRow = %PathRow
@onready var browse_button: Button = %BrowseButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var file_dialog: FileDialog = %FileDialog

var _is_syncing: bool = false
var _pending_action: String = ""
var _uses_default_filters: bool = false
var _is_pointer_inside_panel: bool = false
var _window_for_external_drop: Window = null


func _ready() -> void:
	UICore.ensure_localization_ready()
	mouse_filter = Control.MOUSE_FILTER_PASS
	file_name_row.text_changed.connect(_on_file_name_changed)
	path_row.text_changed.connect(_on_path_changed)
	browse_button.pressed.connect(_open_browse_dialog)
	save_button.pressed.connect(_open_save_dialog)
	load_button.pressed.connect(_open_load_dialog)
	file_dialog.file_selected.connect(_on_dialog_file_selected)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_connect_window_drop_signal()
	_enable_native_dialog_if_available()
	if file_filters.is_empty():
		file_filters = _build_default_filters()
		_uses_default_filters = true
	file_dialog.filters = file_filters
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_apply_translations()
	if not default_path.is_empty():
		set_full_path(default_path)
	else:
		set_full_path(ProjectSettings.globalize_path("user://"))


func _exit_tree() -> void:
	_disconnect_window_drop_signal()


## 设置当前完整路径，并同步刷新路径输入框与文件名输入框。
## 参数 `path` 可以是目录路径、文件路径或 `user://`/系统绝对路径。
## 示例：父级面板加载上次保存位置后回填默认路径。
## `panel.set_full_path("user://square_dot_serial/logs/session.log")`
func set_full_path(path: String) -> void:
	var normalized_path: String = _normalize_path(path)
	_is_syncing = true
	if normalized_path.ends_with("/") or normalized_path.ends_with("\\") or DirAccess.dir_exists_absolute(normalized_path):
		path_row.set_text_value(normalized_path)
		file_name_row.set_text_value("")
	else:
		path_row.set_text_value(normalized_path)
		file_name_row.set_text_value(normalized_path.get_file())
	_is_syncing = false
	_emit_path_changed()


## 读取当前面板拼装出的完整路径。
## 返回值优先使用当前路径行和文件名行拼接得到的最终路径。
## 示例：响应保存按钮时读取用户当前目标路径。
## `var output_path: String = panel.get_full_path()`
func get_full_path() -> String:
	var path_value: String = path_row.get_text_value().strip_edges()
	var file_name: String = file_name_row.get_text_value().strip_edges()
	if path_value.is_empty():
		return file_name
	if file_name.is_empty():
		return path_value
	if path_value.get_file() == file_name:
		return path_value
	var base_dir: String = path_value.get_base_dir()
	if base_dir.is_empty():
		base_dir = path_value
	return base_dir.path_join(file_name)


## 覆盖当前文件对话框使用的过滤器列表。
## 参数 `filters` 使用 Godot `FileDialog.filters` 兼容格式。
## 示例：导出面板只允许显示 CSV 与全部文件。
## `panel.set_filters(PackedStringArray(["*.csv ; CSV 文件", "*.* ; 所有文件"]))`
func set_filters(filters: PackedStringArray) -> void:
	file_filters = filters
	if file_dialog != null:
		file_dialog.filters = file_filters


## 处理从系统窗口拖入的外部文件。
## 参数 `paths` 是系统拖放事件提供的完整路径列表。
## 返回值为 `true` 表示本面板已接收并消费这次拖入。
## 示例：窗口收到文件拖入后转交给当前激活的文件面板。
## `if panel.accept_external_files(files):`
func accept_external_files(paths: PackedStringArray) -> bool:
	if not enable_system_file_drop:
		return false
	var normalized_paths: PackedStringArray = _normalize_external_paths(paths)
	if normalized_paths.is_empty():
		return false
	var primary_path: String = _resolve_primary_external_path(normalized_paths)
	if primary_path.is_empty():
		return false
	set_full_path(primary_path)
	external_files_dropped.emit(self, normalized_paths)
	if _should_emit_load_for_external_path(primary_path):
		load_requested.emit(get_full_path())
	return true


## 主动刷新当前面板的全部界面文本。
## 示例：语言切换后由父级页面要求面板立即刷新按钮和标题。
## `panel.refresh_ui_texts()`
func refresh_ui_texts() -> void:
	_apply_translations()


## 打开系统保存文件对话框。
## 示例：父级工具栏的“另存为”按钮直接调用该入口。
## `panel.request_save_path()`
func request_save_path() -> void:
	_open_save_dialog()


## 打开系统加载文件对话框。
## 示例：父级工具栏的“打开文件”按钮直接调用该入口。
## `panel.request_load_path()`
func request_load_path() -> void:
	_open_load_dialog()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_translations()


func _on_mouse_entered() -> void:
	_is_pointer_inside_panel = true


func _on_mouse_exited() -> void:
	_is_pointer_inside_panel = false


func _apply_translations() -> void:
	if Engine.is_editor_hint():
		UICore.ensure_localization_ready()
	if _uses_default_filters:
		file_filters = _build_default_filters()
		if file_dialog != null:
			file_dialog.filters = file_filters
	if title_label != null:
		title_label.text = UICore.translate(title_key)
	if file_name_row != null:
		file_name_row.set_label_text(UICore.translate(name_label_key))
	if path_row != null:
		path_row.set_label_text(UICore.translate(path_label_key))
	if browse_button != null:
		browse_button.text = UICore.translate(browse_button_key)
	if save_button != null:
		save_button.text = UICore.translate(save_button_key)
		save_button.visible = show_save_button
	if load_button != null:
		load_button.text = UICore.translate(load_button_key)
		load_button.visible = show_load_button
	if file_dialog != null:
		file_dialog.title = UICore.translate(dialog_title_key)


func _open_browse_dialog() -> void:
	_pending_action = "browse"
	file_dialog.file_mode = browse_file_mode
	_prepare_dialog_state()
	file_dialog.popup_centered_ratio(0.75)


func _open_save_dialog() -> void:
	_pending_action = "save"
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_prepare_dialog_state()
	file_dialog.popup_centered_ratio(0.75)


func _open_load_dialog() -> void:
	_pending_action = "load"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_prepare_dialog_state()
	file_dialog.popup_centered_ratio(0.75)


func _prepare_dialog_state() -> void:
	var current_path: String = get_full_path()
	var normalized_path: String = _normalize_path(current_path if not current_path.is_empty() else default_path)
	file_dialog.current_path = normalized_path
	file_dialog.current_dir = normalized_path.get_base_dir() if not normalized_path.is_empty() else ProjectSettings.globalize_path("user://")
	file_dialog.current_file = normalized_path.get_file()


func _connect_window_drop_signal() -> void:
	if Engine.is_editor_hint():
		return
	var current_window: Window = get_window()
	if current_window == null:
		return
	if _window_for_external_drop == current_window and current_window.files_dropped.is_connected(_on_window_files_dropped):
		return
	_disconnect_window_drop_signal()
	_window_for_external_drop = current_window
	if not current_window.files_dropped.is_connected(_on_window_files_dropped):
		current_window.files_dropped.connect(_on_window_files_dropped)


func _disconnect_window_drop_signal() -> void:
	if _window_for_external_drop == null:
		return
	if _window_for_external_drop.files_dropped.is_connected(_on_window_files_dropped):
		_window_for_external_drop.files_dropped.disconnect(_on_window_files_dropped)
	_window_for_external_drop = null


func _enable_native_dialog_if_available() -> void:
	for property_info: Dictionary in file_dialog.get_property_list():
		if str(property_info.get("name", "")) == "use_native_dialog":
			file_dialog.set("use_native_dialog", true)
			return


func _on_window_files_dropped(files: PackedStringArray) -> void:
	if not _is_current_drop_target():
		return
	accept_external_files(files)


func _on_dialog_file_selected(path: String) -> void:
	set_full_path(path)
	match _pending_action:
		"save":
			save_requested.emit(get_full_path())
		"load":
			load_requested.emit(get_full_path())
	_pending_action = ""


func _on_file_name_changed(_value: String) -> void:
	if _is_syncing:
		return
	_emit_path_changed()


func _on_path_changed(value: String) -> void:
	if _is_syncing:
		return
	var normalized_path: String = _normalize_path(value)
	if normalized_path.is_empty():
		_emit_path_changed()
		return
	_is_syncing = true
	path_row.set_text_value(normalized_path)
	file_name_row.set_text_value(normalized_path.get_file())
	_is_syncing = false
	_emit_path_changed()


func _emit_path_changed() -> void:
	path_changed.emit(get_full_path())


func _is_current_drop_target() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var hovered_control: Control = viewport.gui_get_hovered_control()
		if hovered_control != null:
			return hovered_control == self or is_ancestor_of(hovered_control)
		var viewport_mouse_position: Vector2 = viewport.get_mouse_position()
		if _is_point_inside_panel(viewport_mouse_position):
			return true
	if _window_for_external_drop != null:
		var window_mouse_position: Vector2 = _window_for_external_drop.get_mouse_position()
		if _is_point_inside_panel(window_mouse_position):
			return true
	return _is_pointer_inside_panel


func _is_point_inside_panel(point: Vector2) -> bool:
	if not is_visible_in_tree():
		return false
	return get_global_rect().has_point(point)


func _normalize_external_paths(paths: PackedStringArray) -> PackedStringArray:
	var normalized_paths: PackedStringArray = PackedStringArray()
	for raw_path: String in paths:
		var normalized_path: String = _normalize_path(raw_path)
		if normalized_path.is_empty():
			continue
		if normalized_paths.has(normalized_path):
			continue
		normalized_paths.append(normalized_path)
	return normalized_paths


func _resolve_primary_external_path(paths: PackedStringArray) -> String:
	if paths.is_empty():
		return ""
	if browse_file_mode == FileDialog.FILE_MODE_OPEN_DIR:
		for path: String in paths:
			if DirAccess.dir_exists_absolute(path):
				return path
		return paths[0]
	if browse_file_mode == FileDialog.FILE_MODE_OPEN_ANY:
		return paths[0]
	for path: String in paths:
		if not DirAccess.dir_exists_absolute(path):
			return path
	return paths[0]


func _should_emit_load_for_external_path(path: String) -> bool:
	if not emit_load_requested_on_file_drop:
		return false
	if path.is_empty():
		return false
	if browse_file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		return false
	if browse_file_mode == FileDialog.FILE_MODE_OPEN_DIR:
		return DirAccess.dir_exists_absolute(path)
	if browse_file_mode == FileDialog.FILE_MODE_OPEN_ANY:
		return true
	return not DirAccess.dir_exists_absolute(path)


func _normalize_path(path: String) -> String:
	var value: String = path.strip_edges()
	if value.is_empty():
		return ""
	if value.begins_with("user://") or value.begins_with("res://"):
		return ProjectSettings.globalize_path(value)
	return value


func _build_default_filters() -> PackedStringArray:
	return PackedStringArray([
		"*.json ; %s" % UICore.translate("FILE_FILTER_JSON"),
		"*.* ; %s" % UICore.translate("FILE_FILTER_ALL_FILES"),
	])
