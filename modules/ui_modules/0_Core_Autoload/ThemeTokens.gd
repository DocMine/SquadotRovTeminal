## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ThemeTokens
extends RefCounted

## 定义共享 UI 主题色板和主题构建方法。
## 该脚本属于共享核心层，供主项目、`5_rovsim` 和 `6_SquareDotSerial` 统一生成主题与状态色。
## 典型用法：
## `theme = ThemeTokens.build_theme(1.0)`
## `badge.set_state("在线", ThemeTokens.SUCCESS)`

const BG: Color = Color("10151b")
const PANEL: Color = Color("19212b")
const PANEL_ALT: Color = Color("222b36")
const PANEL_EMPHASIS: Color = Color("2c3746")
const TEXT: Color = Color("e8edf3")
const TEXT_MUTED: Color = Color("8da0b3")
const BORDER: Color = Color("344152")
const ACCENT: Color = Color("59c3c3")
const SUCCESS: Color = Color("4db88f")
const WARNING: Color = Color("e0a458")
const DANGER: Color = Color("de6b69")
const MUTED: Color = TEXT_MUTED


## 按给定字号比例构建共享 UI 主题。
## 参数 `font_scale` 用于整体放大或缩小字体与页签字号。
## 返回值可直接赋给页面根节点的 `theme` 属性。
## 示例：根据用户设置刷新串口工具主题。
## `theme = ThemeTokens.build_theme(1.15)`
static func build_theme(font_scale: float = 1.0) -> Theme:
	var theme: Theme = Theme.new()
	var font_size_small: int = _scaled_font_size(8, font_scale)
	var font_size_normal: int = _scaled_font_size(12, font_scale)
	var font_size_large: int = _scaled_font_size(16, font_scale)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_color", "TextEdit", TEXT)
	theme.set_color("font_color", "RichTextLabel", TEXT)
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color", "MenuButton", TEXT)
	theme.set_color("font_color", "ItemList", TEXT)
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_color", "Tree", TEXT)
	theme.set_color("font_hover_color", "PopupMenu", TEXT)
	theme.set_color("font_disabled_color", "PopupMenu", TEXT_MUTED)

	theme.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	theme.set_color("font_placeholder_color", "TextEdit", TEXT_MUTED)
	theme.set_color("font_readonly_color", "LineEdit", TEXT_MUTED)
	theme.set_color("font_readonly_color", "TextEdit", TEXT_MUTED)

	theme.set_font_size("font_size", "Label", font_size_normal)
	theme.set_font_size("font_size", "LineEdit", font_size_normal)
	theme.set_font_size("font_size", "Button", font_size_normal)
	theme.set_font_size("font_size", "MenuButton", font_size_normal)
	theme.set_font_size("font_size", "ItemList", font_size_small)
	theme.set_font_size("font_size", "PopupMenu", font_size_normal)
	theme.set_font_size("font_size", "RichTextLabel", font_size_small)
	theme.set_font_size("font_size", "Tree", font_size_small)
	theme.set_font_size("font_size", "OptionButton", font_size_normal)
	theme.set_font_size("font_size", "TabBar", font_size_large)

	var panel_sb: StyleBoxFlat = StyleBoxFlat.new()
	panel_sb.bg_color = PANEL
	panel_sb.border_color = BORDER
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(10)
	panel_sb.content_margin_left = 10
	panel_sb.content_margin_top = 8
	panel_sb.content_margin_right = 10
	panel_sb.content_margin_bottom = 8

	var alt_panel_sb: StyleBoxFlat = panel_sb.duplicate()
	alt_panel_sb.bg_color = PANEL_ALT

	var input_sb: StyleBoxFlat = StyleBoxFlat.new()
	input_sb.bg_color = PANEL_ALT
	input_sb.border_color = BORDER
	input_sb.set_border_width_all(1)
	input_sb.set_corner_radius_all(8)
	input_sb.content_margin_left = 8
	input_sb.content_margin_top = 6
	input_sb.content_margin_right = 8
	input_sb.content_margin_bottom = 6

	var focus_sb: StyleBoxFlat = input_sb.duplicate()
	focus_sb.border_color = ACCENT
	focus_sb.shadow_color = ACCENT
	focus_sb.shadow_size = 1

	var button_normal: StyleBoxFlat = StyleBoxFlat.new()
	button_normal.bg_color = PANEL_EMPHASIS
	button_normal.border_color = BORDER
	button_normal.set_border_width_all(1)
	button_normal.set_corner_radius_all(8)
	button_normal.content_margin_left = 12
	button_normal.content_margin_top = 8
	button_normal.content_margin_right = 12
	button_normal.content_margin_bottom = 8

	var button_hover: StyleBoxFlat = button_normal.duplicate()
	button_hover.bg_color = Color(button_normal.bg_color).lightened(0.08)

	var button_pressed: StyleBoxFlat = button_normal.duplicate()
	button_pressed.bg_color = ACCENT.darkened(0.18)
	button_pressed.border_color = ACCENT

	var button_disabled: StyleBoxFlat = button_normal.duplicate()
	button_disabled.bg_color = PANEL.darkened(0.1)
	button_disabled.border_color = BORDER.darkened(0.2)

	theme.set_stylebox("panel", "PanelContainer", panel_sb)
	theme.set_stylebox("panel", "TabContainer", alt_panel_sb)
	theme.set_stylebox("panel", "ColorRect", alt_panel_sb)
	theme.set_stylebox("normal", "LineEdit", input_sb)
	theme.set_stylebox("focus", "LineEdit", focus_sb)
	theme.set_stylebox("read_only", "LineEdit", input_sb)
	theme.set_stylebox("normal", "TextEdit", input_sb)
	theme.set_stylebox("focus", "TextEdit", focus_sb)
	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_stylebox("disabled", "Button", button_disabled)
	theme.set_stylebox("normal", "MenuButton", button_normal)
	theme.set_stylebox("hover", "MenuButton", button_hover)
	theme.set_stylebox("pressed", "MenuButton", button_pressed)
	theme.set_stylebox("disabled", "MenuButton", button_disabled)
	theme.set_stylebox("normal", "OptionButton", button_normal)
	theme.set_stylebox("hover", "OptionButton", button_hover)
	theme.set_stylebox("pressed", "OptionButton", button_pressed)
	theme.set_stylebox("disabled", "OptionButton", button_disabled)
	theme.set_stylebox("panel", "PopupMenu", alt_panel_sb)

	var tab_selected: StyleBoxFlat = button_pressed.duplicate()
	tab_selected.content_margin_left = 18
	var tab_unselected: StyleBoxFlat = button_normal.duplicate()
	tab_unselected.content_margin_left = 18
	var tab_hover: StyleBoxFlat = button_hover.duplicate()
	tab_hover.content_margin_left = 18
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_hover)

	return theme


## 按字号比例计算主题使用的实际字体尺寸。
## 参数 `base_size` 是基准字号；参数 `font_scale` 是当前缩放比例。
## 返回值保证不小于 10，避免界面字体过小。
static func _scaled_font_size(base_size: int, font_scale: float) -> int:
	return max(int(round(base_size * font_scale)), 10)
