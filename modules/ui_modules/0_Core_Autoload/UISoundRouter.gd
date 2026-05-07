## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name UISoundRouter
extends Node

## 统一管理共享 UI 点击音效触发入口。
## 该脚本属于共享核心层，可被 `UICore` 直接托管，也可作为页面内的轻量声音路由节点复用。
## 典型用法：
## `UICore.play_button_click()`
## `sound_router.play_ui(UISoundRouter.SoundType.CLICK)`

enum SoundType {
	CLICK,
	CONFIRM,
	WARNING,
	ERROR,
	TOGGLE,
}

@export var enabled: bool = true

var _button_click_players: Array[AudioStreamPlayer] = []


## 注册一个可复用的按钮点击播放器。
## 参数 `player` 是已挂在场景树中的 `AudioStreamPlayer`。
## 示例：启动页面时把共享按钮音效播放器交给路由器管理。
## `router.register_button_click_player(%ButtonClickPlayer)`
func register_button_click_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	if _button_click_players.has(player):
		return
	_button_click_players.append(player)


## 取消注册一个按钮点击播放器。
## 参数 `player` 是此前已经注册过的播放器实例。
## 示例：页面销毁前移除自身专用的点击播放器。
## `router.unregister_button_click_player(%ButtonClickPlayer)`
func unregister_button_click_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	_button_click_players.erase(player)


## 播放默认按钮点击音效。
## 该方法会自动忽略已失效或未挂载音频流的播放器。
## 示例：通用按钮点击时触发共享音效。
## `router.play_button_click()`
func play_button_click() -> void:
	if not enabled:
		return
	var active_players: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _button_click_players:
		if not is_instance_valid(player):
			continue
		active_players.append(player)
		if player.is_inside_tree() and player.stream != null:
			player.play()
	_button_click_players = active_players


## 按语义类型触发 UI 音效。
## 参数 `sound_type` 是界面事件语义；当前共享实现会把主要按钮事件统一映射到点击声。
## 示例：交互反馈层在按钮抬起时统一调用。
## `router.play_ui(UISoundRouter.SoundType.CLICK)`
func play_ui(sound_type: SoundType) -> void:
	if sound_type == SoundType.CLICK or sound_type == SoundType.CONFIRM or sound_type == SoundType.TOGGLE:
		play_button_click()
