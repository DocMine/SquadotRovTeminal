extends Node3D
class_name ThrusterBuild
"""
构建态推进器：
- 只负责“放在哪、用什么参数”
- 不参与物理、不 update
"""

## 推进器参数资源（唯一参数来源）
@export var data: ThrusterData

## 是否显示方向 Gizmo
@export var show_gizmo := true

func get_part_config() -> Dictionary:
	return {
		"type": "thruster",
		"data": data,
		"transform": global_transform
	}
