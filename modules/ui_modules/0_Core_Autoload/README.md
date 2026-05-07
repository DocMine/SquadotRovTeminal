# 0_Core_Autoload

项目级 UI 核心入口目录，负责集中维护可被多个模块稳定复用的全局服务。

## 结构

```text
ui_modules/0_Core_Autoload/
  UICore.gd
  AppLocalization.gd
  ThemeTokens.gd
  UISoundRouter.gd
  README.md
```

## 设计原则

- 对外只暴露一个 autoload 入口：`UICore`
- `AppLocalization.gd`、`ThemeTokens.gd`、`UISoundRouter.gd` 属于内部实现层
- 其他模块优先调用 `UICore`，不直接分别 `preload` 内部 helper
- 只承接全局服务、全局配置和全局资源入口，不承接局部页面逻辑
- 统一翻译源位于 `res://locale/ui_translations.csv`，子项目不要再维护平行本地化副本

## 对外能力

- `UICore.ensure_localization_ready()`
- `UICore.translate(key: String) -> String`
- `UICore.set_app_locale(locale: String) -> void`
- `UICore.get_supported_locales() -> PackedStringArray`
- `UICore.get_accent_color() -> Color`
- `UICore.get_danger_color() -> Color`
- `UICore.get_success_color() -> Color`
- `UICore.get_warning_color() -> Color`
- `UICore.get_muted_color() -> Color`
- `UICore.register_button_click_player(player: AudioStreamPlayer) -> void`
- `UICore.unregister_button_click_player(player: AudioStreamPlayer) -> void`
- `UICore.play_button_click() -> void`

## 最小示例

```gdscript
func _ready() -> void:
	UICore.ensure_localization_ready()
	start_button.text = UICore.translate("MAIN_BUTTON_START")
	start_button.self_modulate = UICore.get_accent_color()
```

## 注意事项

- 若未来继续扩展全局 UI 服务，应优先扩展 `UICore` 的对外方法，而不是让模块重新散落依赖内部脚本。
- 主题色和本地化入口属于稳定共享能力；业务层状态拼装和页面级交互不要放进这里。
