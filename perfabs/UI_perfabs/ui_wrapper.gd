## Shared welcome-scene button wrapper.
## Provides a small fade-in / fade-out API so the existing welcome
## transition animation can keep using scene-instanced wrapper nodes.
@tool
extends Control

@export var default_enter_type: int = 0

var _hidden_alpha: float = 0.0
var _visible_alpha: float = 1.0


## Applies the default editor/runtime alpha state for the wrapper.
func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 76.0)
	if Engine.is_editor_hint():
		modulate.a = _visible_alpha
		return
	modulate.a = _hidden_alpha


## Plays the standard entry fade for a wrapped button row.
func play_enter() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", _visible_alpha, 0.18)


## Plays the standard exit fade for a wrapped button row.
func play_exit() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", _hidden_alpha, 0.12)
