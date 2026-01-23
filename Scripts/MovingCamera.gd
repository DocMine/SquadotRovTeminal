extends Node3D

# 可调整参数
@export var move_speed: float = 0.5  # 移动速度
@export var zoom_speed: float = 2.0 # 缩放速度
@export var sensitivity: float = 0.01 # 鼠标灵敏度
@export var zoom_limit: Vector2 = Vector2(2.0, 20.0) # 缩放范围（最小缩放，最大缩放）

@onready var camera: Camera3D = $Camera3D # 相机
var rotation_delta: Vector2 = Vector2.ZERO
var zoom_level: float = 10.0
var MoveDirection:Vector3 = Vector3.ZERO

func _ready():
	# 获取子节点中的相机
	assert(camera != null, "请确保子节点包含一个 Camera3D！")
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event:InputEvent):
	# 处理鼠标移动控制旋转
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			rotation_delta += event.relative * sensitivity
			rotation += Vector3(-rotation_delta.y, -rotation_delta.x, 0)
			rotation_delta = Vector2.ZERO
		
	# 使用偏移实现视角缩放
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_level = max(zoom_limit.x, zoom_level - zoom_speed)
		camera.translate(Vector3(0, 0, -zoom_level))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_level = min(zoom_limit.y, zoom_level + zoom_speed)
		camera.translate(Vector3(0, 0, zoom_level))
	
	# 

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# 处理相机运动
	if Input.is_action_pressed("ui_up"):
		MoveDirection.z = -1
	elif Input.is_action_pressed("ui_down"):
		MoveDirection.z = 1
	elif Input.is_action_pressed("ui_left"):
		MoveDirection.x = -1
	elif Input.is_action_pressed("ui_right"):
		MoveDirection.x = 1
	else	:
		MoveDirection = Vector3.ZERO
	translate(MoveDirection.normalized()*move_speed)
	#position += MoveDirection.normalized()*move_speed
