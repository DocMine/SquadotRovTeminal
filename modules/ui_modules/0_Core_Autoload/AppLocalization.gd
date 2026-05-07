## 本脚本负责对应场景或模块的局部逻辑与节点协作。
@tool
extends RefCounted

## 集中管理整个工程的表格式界面文本翻译。
## 该脚本属于共享核心层，供 `UICore`、ROV 仿真主链路和串口工具主链路统一复用。
## 典型用法：
## `AppLocalization.ensure_ready("zh_CN")`
## `var title: String = AppLocalization.translate("APP_TITLE")`

const TRANSLATION_CSV_PATH: String = "res://locale/ui_translations.csv"
const DEFAULT_LOCALE: String = "zh_CN"
const SUPPORTED_LOCALE_CODES: Array[String] = ["zh_CN", "en"]

static var _is_ready: bool = false
static var _table: Dictionary = {}


## 加载翻译表并切换当前语言。
## 参数 `locale` 表示期望切换到的语言；传空字符串时会保留当前语言，若当前语言无效则回退到 `zh_CN`。
## 示例：在页面进入时初始化本地化。
## `AppLocalization.ensure_ready("en")`
static func ensure_ready(locale: String = DEFAULT_LOCALE) -> void:
	if not _is_ready:
		_load_csv_table()
		_is_ready = true
	var target_locale: String = locale
	if target_locale.is_empty():
		target_locale = TranslationServer.get_locale()
	TranslationServer.set_locale(_normalize_locale(target_locale))


## 按当前语言获取翻译文本，并可选地应用命名占位符参数。
## 参数 `key` 是翻译 key；参数 `args` 是 `{name: value}` 形式的占位符字典。
## 返回值是当前语言下可显示的文本；缺失时回退到默认语言，再回退到 key 本身。
## 示例：刷新状态栏文案。
## `status_label.text = AppLocalization.translate("APP_STATUS_CONNECTED", {"port": "COM3"})`
static func translate(key: String, args: Dictionary = {}) -> String:
	if not _is_ready:
		_load_csv_table()
		_is_ready = true
	var locale: String = TranslationServer.get_locale()
	var normalized_locale: String = _normalize_locale(locale)
	var text_value: String = key
	if _table.has(key):
		var row: Dictionary = _table[key]
		if row.has(normalized_locale):
			text_value = _format_translation_text(str(row[normalized_locale]))
		elif row.has(DEFAULT_LOCALE):
			text_value = _format_translation_text(str(row[DEFAULT_LOCALE]))
	if args.is_empty():
		return text_value
	return text_value.format(args)


## 设置当前应用语言。
## 参数 `locale` 是候选语言代码，仅支持 `SUPPORTED_LOCALES` 中声明的值。
## 示例：用户在菜单里切换界面语言。
## `AppLocalization.set_app_locale("zh_CN")`
static func set_app_locale(locale: String) -> void:
	ensure_ready(locale)


## 返回当前支持的语言列表。
## 返回值用于设置菜单、校验用户配置或做回退判断。
## 示例：读取用户配置前检查语言是否合法。
## `var supported: PackedStringArray = AppLocalization.get_supported_locales()`
static func get_supported_locales() -> PackedStringArray:
	return PackedStringArray(SUPPORTED_LOCALE_CODES)


## 判断候选语言是否在共享翻译表支持范围内。
## 参数 `locale` 是待校验的语言代码。
## 返回值为 `true` 表示可直接用于 `set_app_locale()`。
## 示例：加载持久化设置时判断是否可用。
## `if AppLocalization.is_supported_locale(saved_locale):`
static func is_supported_locale(locale: String) -> bool:
	return SUPPORTED_LOCALE_CODES.has(_normalize_locale(locale))


## 从根翻译 CSV 读取整个 key 表。
## 该私有方法只负责载入，不负责设置当前语言。
static func _load_csv_table() -> void:
	_table.clear()
	if not FileAccess.file_exists(TRANSLATION_CSV_PATH):
		return
	var file: FileAccess = FileAccess.open(TRANSLATION_CSV_PATH, FileAccess.READ)
	if file == null:
		return
	var headers: PackedStringArray = file.get_csv_line()
	if headers.size() < 2:
		return
	while not file.eof_reached():
		var row_values: PackedStringArray = file.get_csv_line()
		if row_values.is_empty():
			continue
		var key: String = row_values[0].strip_edges()
		if key.is_empty():
			continue
		var row: Dictionary = {}
		for index: int in range(1, min(headers.size(), row_values.size())):
			var locale_key: String = headers[index].strip_edges()
			if not locale_key.is_empty():
				row[locale_key] = row_values[index]
		_table[key] = row


## 规范化语言代码，统一回到工程内允许的语言集合。
## 参数 `locale` 允许传入 `zh`、`zh_CN`、`en` 等常见值。
## 返回值始终是工程内部使用的标准语言代码。
static func _normalize_locale(locale: String) -> String:
	if locale.begins_with("zh"):
		return "zh_CN"
	if locale.begins_with("en"):
		return "en"
	return DEFAULT_LOCALE


## 处理 CSV 中的转义换行文本。
## 参数 `value` 是原始表格单元格内容。
## 返回值会把 `\n` 形式的换行还原成真正的多行文本。
static func _format_translation_text(value: String) -> String:
	return value.replace("\\n", "\n")
