## 本脚本负责对应场景或模块的局部逻辑与节点协作。
@tool
extends Node

## 暴露整个工程共用的 UI 核心入口。
## 该 autoload 负责聚合共享本地化、主题色与点击音效服务，供页面层和通用模块稳定调用。
## 典型用法：
## `UICore.ensure_localization_ready("zh_CN")`
## `title_label.text = UICore.translate("APP_TITLE")`

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")
const ThemeTokensScript = preload("res://modules/ui_modules/0_Core_Autoload/ThemeTokens.gd")
const UISoundRouterScript = preload("res://modules/ui_modules/0_Core_Autoload/UISoundRouter.gd")

var _sound_router: Node = null


func _ready() -> void:
	ensure_localization_ready()
	_ensure_sound_router()


## 初始化共享翻译表，并可选切换到指定语言。
## 参数 `locale` 允许页面在启动时显式指定语言；留空时沿用当前设置。
## 示例：主页面进入时按用户设置初始化文本。
## `UICore.ensure_localization_ready("en")`
func ensure_localization_ready(locale: String = "") -> void:
	AppLocalizationScript.ensure_ready(locale)


## 获取当前语言下的翻译文本，并支持命名占位符替换。
## 参数 `key` 是翻译 key；参数 `args` 是可选的占位字典。
## 返回值可直接显示到任意 UI 文本节点。
## 示例：更新状态栏里的串口连接信息。
## `status_label.text = UICore.translate("APP_STATUS_CONNECTED", {"port": "COM5"})`
func translate(key: String, args: Dictionary = {}) -> String:
	return AppLocalizationScript.translate(key, args)


## 切换应用当前语言。
## 参数 `locale` 必须来自共享翻译表支持的语言集合。
## 示例：语言菜单点击后切换整个页面文本。
## `UICore.set_app_locale("zh_CN")`
func set_app_locale(locale: String) -> void:
	AppLocalizationScript.set_app_locale(locale)


## 返回共享翻译表当前支持的语言代码列表。
## 返回值通常用于菜单构建和本地配置校验。
## 示例：读取保存设置前先验证语言代码是否合法。
## `if UICore.get_supported_locales().has(saved_locale):`
func get_supported_locales() -> PackedStringArray:
	return AppLocalizationScript.get_supported_locales()


## 返回共享主题中的强调色。
## 示例：把主操作按钮染成统一强调色。
## `start_button.self_modulate = UICore.get_accent_color()`
func get_accent_color() -> Color:
	return ThemeTokensScript.ACCENT


## 返回共享主题中的危险态颜色。
## 示例：把删除按钮或错误状态文本切换为危险色。
## `delete_button.self_modulate = UICore.get_danger_color()`
func get_danger_color() -> Color:
	return ThemeTokensScript.DANGER


## 返回共享主题中的成功态颜色。
## 示例：在线状态徽标显示为成功色。
## `badge.set_state("在线", UICore.get_success_color())`
func get_success_color() -> Color:
	return ThemeTokensScript.SUCCESS


## 返回共享主题中的警告态颜色。
## 示例：高风险提示文本使用统一警告色。
## `warning_label.self_modulate = UICore.get_warning_color()`
func get_warning_color() -> Color:
	return ThemeTokensScript.WARNING


## 返回共享主题中的弱化文本颜色。
## 示例：未连接状态或说明性文本使用弱化色。
## `hint_label.self_modulate = UICore.get_muted_color()`
func get_muted_color() -> Color:
	return ThemeTokensScript.MUTED


## 向共享音效路由注册一个点击播放器。
## 参数 `player` 是需要参与统一播放的音频播放器节点。
## 示例：某个页面拥有自己的按钮点击音频流时完成注册。
## `UICore.register_button_click_player(%ButtonClickPlayer)`
func register_button_click_player(player: AudioStreamPlayer) -> void:
	_ensure_sound_router().register_button_click_player(player)


## 从共享音效路由中移除一个点击播放器。
## 参数 `player` 是此前已经注册过的播放器节点。
## 示例：页面退出前清理注册关系。
## `UICore.unregister_button_click_player(%ButtonClickPlayer)`
func unregister_button_click_player(player: AudioStreamPlayer) -> void:
	if _sound_router == null:
		return
	_sound_router.unregister_button_click_player(player)


## 立即触发共享按钮点击音效。
## 示例：通用组件内部在按钮按下时统一播放点击声。
## `UICore.play_button_click()`
func play_button_click() -> void:
	_ensure_sound_router().play_button_click()


## 保证共享音效路由存在并返回它。
## 返回值是当前 `UICore` 管理的 `UISoundRouter` 实例。
func _ensure_sound_router() -> Node:
	if _sound_router != null and is_instance_valid(_sound_router):
		return _sound_router
	var existing_router: Node = get_node_or_null("UISoundRouter")
	if existing_router != null:
		_sound_router = existing_router
		return _sound_router
	_sound_router = UISoundRouterScript.new()
	_sound_router.name = "UISoundRouter"
	add_child(_sound_router)
	return _sound_router
