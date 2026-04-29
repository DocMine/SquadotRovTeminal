extends Node

## 主入口脚本（Main Scene Orchestrator）
##
## 这个脚本挂在主场景根节点上，职责是“把各个子系统接起来”，而不是实现具体业务逻辑：
## - SimulationManager：仿真步进、状态更新与对外查询接口
## - DataRecorder：以固定采样率从仿真中采样并形成时间窗数据
## - PresetManager：加载/应用预设（推进器参数等）到 ROV/仿真
## - PlaybackManager：回放录制的数据（让仿真按历史帧运行/显示）
## - DesignEvaluator：对设计/配置做评估（指标、得分等）
## - UI（Builder/Dashboard/Charts）：把用户输入与数据展示接到上述模块
##
## 典型流程：
## 1) _ready() 时获取场景中的各个节点引用
## 2) 调用各模块的 setup() 注入依赖关系（避免在模块内部硬编码路径）
## 3) 载入默认预设，使仿真有一个可直接运行的初始配置

@onready var world: Node3D = $World
@onready var rov_root: Node3D = $World/ROVRoot
@onready var simulation_manager: Node = $SimulationManager
@onready var data_recorder: Node = $DataRecorder
@onready var preset_manager: Node = $PresetManager
@onready var playback_manager: Node = $PlaybackManager
@onready var design_evaluator: Node = $DesignEvaluator

@onready var builder_panel: Control = $UI/Root/UILayout/TopRow/BuilderPanel
@onready var dashboard: Control = $UI/Root/UILayout/TopRow/Dashboard
@onready var charts: Control = $UI/Root/UILayout/Charts


func _ready() -> void:
	# 依赖注入：先让各后台模块拿到自己需要的引用
	preset_manager.setup(rov_root, simulation_manager)
	playback_manager.setup(simulation_manager)
	design_evaluator.setup(simulation_manager)
	# UI 模块需要同时拿到“数据源”和“控制器”才能工作
	builder_panel.setup(preset_manager, simulation_manager, data_recorder, playback_manager, design_evaluator)
	dashboard.setup(data_recorder)
	charts.setup(data_recorder)
	# 默认加载一个稳定预设，避免首次启动时参数为空
	preset_manager.load_preset("stable")
