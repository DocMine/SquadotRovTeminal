## 本脚本负责对应场景或模块的局部逻辑与节点协作。
extends VBoxContainer
# 这是给Container写的脚本，作用是提供两个将子节点滑入和滑出的动画

func _ready() -> void:
	slide_in()

func slide_in():
	# 按次序滑入当前位置
	var child_list:Array[Node] = get_children()
	if child_list.size() > 0:
		for ch:Control in child_list:
			if ch.has_method("play_enter"):
				await get_tree().create_timer(0.13).timeout
				ch.play_enter()
	
func slide_out():
	var child_list:Array[Node] = get_children()
	if child_list.size() > 0:
		for ch:Control in child_list:
			if ch.has_method("play_exit"):
				await get_tree().create_timer(0.13).timeout
				ch.play_exit()
