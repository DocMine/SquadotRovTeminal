## 摘要

基于 [target.md](file:///c:/Users/limit/Desktop/ROV_Sim/Docs/target.md) 与现有 [plan.md](file:///c:/Users/limit/Desktop/ROV_Sim/Docs/plan.md)，把“ROV 设计与仿真工具（原型版）”落成可执行的工程化步骤清单。该计划以 **Godot 4.6 + Jolt** 为基础，脚本语言 **GDScript**，深度 **向下为正**，记录保存优先 **JSON**。

## 当前状态分析（已勘察）

- 项目目前只有基础 Godot 工程壳： [project.godot](file:///c:/Users/limit/Desktop/ROV_Sim/project.godot) / 图标 / 文档（无 `.tscn/.gd` 实现文件）。
- 未配置主场景（project.godot 里没有 `run/main_scene`）。
- 因此所有 Runtime Builder / Simulation Core / Data Recorder / UI 图表等需要从 0 搭建脚手架与最小可运行闭环。

## 目标（与 target.md 对齐）

- P0：能拼装（至少推进器）→ 能仿真（推进器力 + 浮力/阻力基础）→ 能输出基础状态（ROVState），且不同设计产生可观察差异。
- P1：数据采集（Recorder）+ Dashboard + 实时图表，形成“工程软件感”的主演示路径。
- P2：保存/回放 + 设计评估 + 预设，一键展示与对比。

---

# 决策与约定（已确认）

- **脚本语言**：GDScript
- **深度 depth 定义**：向下为正（UI 直接显示 depth_m）
- **记录文件**：JSON 先落地（便于调试/演示）
- **单位**：m、m/s、rad（UI 显示 °）、N、N·m、s

---

# 具体执行步骤（按依赖顺序）

## Step 1：工程骨架与主场景（必须先做）

### 1.1 新建目录结构（建议）

- `res://scenes/`：场景
- `res://scripts/`：脚本
- `res://scripts/sim/`：仿真核心
- `res://scripts/builder/`：运行时拼装
- `res://scripts/data/`：数据采集/记录/回放
- `res://scripts/ui/`：Dashboard/图表 UI
- `res://resources/`：Resource 定义（状态、预设、记录等）

### 1.2 创建主场景并写入项目设置

- 新建 `res://scenes/main/main.tscn`，建议结构：
  - `Main (Node)`  
    - `World (Node3D)`：海水/地面/光照/相机（先最小）
      - `ROVRoot (Node3D)`：当前 ROV 实例挂载点
      - `ForceDebug (Node3D)`：力可视化容器（后续）
    - `UI (CanvasLayer)`：
      - `BuilderPanel (Control)`：拼装/Inspector（后续逐步完善）
      - `Dashboard (Control)`：实时数值面板
      - `Charts (Control)`：实时图表区
    - `SimulationManager (Node)`：驱动仿真与状态生成
    - `DataRecorder (Node)`：采样与缓存（P1）
    - `PresetManager (Node)`：预设加载（P2）
- 在 `project.godot` 里设置 `run/main_scene="res://scenes/main/main.tscn"`。

### 1.3 验收（Step 1 Done）

- 项目能直接运行到主界面（哪怕 UI 只是占位控件），无报错。

---

## Step 2：状态模型（ROVState / ThrusterState / DataFrame）

> 先定“仿真产出 → UI/记录消费”的稳定接口，避免后续返工。

### 2.1 定义 Resource/脚本数据结构（建议落地为 Resource + Typed 字段）

- `ROVState`：
  - `time_s: float`
  - `position_m: Vector3`
  - `linear_velocity_mps: Vector3`
  - `rotation_quat: Quaternion`
  - `angular_velocity_radps: Vector3`
  - `depth_m: float`（向下为正）
- `ThrusterState`：
  - `id: int` / `name: String`
  - `command: float`（约定 -1..1）
  - `thrust_n: float`
- `DataFrame`：
  - `time_s: float`
  - `state: ROVState`
  - `thrusters: Array[ThrusterState]`

### 2.2 状态生成入口

- 在 `SimulationManager` 内提供 `get_current_state() -> ROVState` 与 `get_thruster_states() -> Array[ThrusterState]`。

### 2.3 验收（Step 2 Done）

- 运行时每秒能采样打印 1 次状态快照（临时输出），字段值合理、单位一致。

---

## Step 3：最小 ROV 仿真闭环（P0 核心先跑起来）

### 3.1 ROV 实体与推进器组件

- 创建 `res://scenes/rov/rov.tscn`（最小模型即可）：
  - `ROVBody (RigidBody3D)`：主体刚体
  - `Thrusters (Node3D)`：推进器容器
    - `Thruster_1..n (Node3D + 脚本)`：提供方向、位置、最大推力等参数

### 3.2 力模型（P0 最小）

- 推进器推力：`F = command * max_thrust`，沿推进器局部轴（例如 -Z）施加到 `ROVBody` 指定点。
- 浮力：按排水体积/浮力系数施加向上力，作用点为浮心。
- 各向异性阻力：按速度分量施加阻力（至少支持 xyz 不同系数）。

### 3.3 “不同设计不同表现”的钩子（P0 必须）

- 重心 COM 可调（RigidBody3D 的质量分布或通过额外力矩近似）。
- 浮心 COB 可调（浮力作用点偏移造成姿态稳定差异）。
- 推进器布局影响力矩（不同安装位置施力点不同）。

### 3.4 验收（Step 3 Done）

- 两个预设（对称/不对称）在相同输入下出现明显差异（偏航/翻滚/漂移至少其一）。

---

## Step 4：Runtime Builder（运行时拼装，P0 收口）

> 当前仓库无实现，计划按“最小可用 → 可视化增强”的顺序推进。

### 4.1 最小可用（必须）

- 添加 Part（推进器）：从列表/按钮添加到 `ROV` 的 Thrusters 容器
- 选择 Part：场景点击或列表点击，选中状态同步
- 移动/旋转：至少支持一套交互（推荐 Gizmo 或简单键鼠操控）
- 删除 Part：删除选中推进器
- Inspector：编辑推进器参数（方向、最大推力、安装偏移）

### 4.2 额外增强（建议）

- 推进器方向可视化（箭头/线段）
- 重心/浮心可视化（点 + 标签）

### 4.3 验收（Step 4 Done）

- 1 分钟内完成“添加 4 推进器 → 调整朝向/位置 → 观察运动变化”的演示路径。

---

## Step 5：Data Recorder（P1：采样/缓存/开关）

### 5.1 采样策略（决定性细节）

- 采样频率可配置（默认提供 10Hz 与 50Hz 两档）
- 与物理帧解耦：使用累计 dt 的方式在 `_physics_process` 中按频率触发采样

### 5.2 缓存策略

- 滑动窗口缓存（用于实时图表）：例如保留最近 `window_seconds`（默认 20s）
- 全量记录缓冲（用于保存/回放）：默认开启，但允许配置关闭（避免内存压力）

### 5.3 API（供 UI 使用）

- `start_recording()` / `stop_recording()` / `clear()`
- `get_window_frames() -> Array[DataFrame]`
- （可选）事件/信号：`frame_recorded(frame)`

### 5.4 验收（Step 5 Done）

- 开关录制：数据增长/停止增长符合预期；改变采样频率后点数变化正确。

---

## Step 6：Dashboard（P1：实时数值面板）

### 6.1 内容

- Depth（m）
- Velocity（m/s）：建议显示速度模长 + xyz（可选）
- Roll/Pitch/Yaw（°）
- 推进器列表：command 与 thrust（N）

### 6.2 UI 刷新节流

- UI 刷新频率跟随采样频率或更低（避免每帧刷新抖动）

### 6.3 验收（Step 6 Done）

- 静止时稳定不闪；运动/输入变化时数值趋势正确。

---

## Step 7：实时图表（P1：专业感核心）

### 7.1 图表清单（必须）

- 深度 depth vs time
- 姿态 roll/pitch/yaw vs time
- 推进器 thrust vs time（多曲线）
- 速度曲线（linear speed 或 xyz）

### 7.2 渲染方案（计划定死，避免分叉）

- 使用 `Control` 自绘：`_draw()` + `draw_polyline()` 绘制折线图
- 仅渲染滑动窗口数据；对点数做上限（例如 1000 点），超出则下采样
- Y 轴自动量程（min/max + margin），后续可加固定量程开关
- 具备曲线开关（至少按“曲线组”开关：深度/姿态/推进器/速度）

### 7.3 验收（Step 7 Done）

- 曲线连续滚动；开关曲线不影响仿真稳定；点数稳定且帧率可接受。

---

## Step 8：力可视化（P1 加强）

### 8.1 必做

- 推进器力（红）
- 阻力（蓝）
- 浮力（绿）

### 8.2 交互

- 可视化开关
- 缩放系数（防止矢量太大/太小）

### 8.3 验收（Step 8 Done）

- 能“看懂为什么在动/在转/为何稳定或不稳定”。

---

## Step 9：保存/回放（P2）

### 9.1 保存（JSON）

- 保存 `Array[DataFrame]` 到 JSON（含版本号字段，便于未来升级）
- 保存时写入：采样频率、单位约定、ROV 配置摘要（可选）

### 9.2 回放

- 回放模式驱动：按时间轴推进，将 `ROVBody` 的 transform/速度设置为记录值（或采用插值）
- 图表与 Dashboard 在回放时读取同一份数据源

### 9.3 验收（Step 9 Done）

- “先跑一段 → 保存 → 立刻回放 → 曲线同步”的演示闭环成立。

---

## Step 10：设计评估 + 预设（P2：展示杀手）

### 10.1 评估项

- 稳定性：角速度过大/翻滚次数/姿态发散（阈值可配置）
- 对称性：推进器位置/方向几何对称粗判
- 重心合理性：COM 偏移、COB-COM 相对位置提示

### 10.2 预设

- 稳定 ROV
- 不稳定 ROV
- 高推力版本
- 一键切换：加载后同时更新 Builder/Simulation/UI

### 10.3 验收（Step 10 Done）

- 10 秒内切换三种预设并呈现明显对比；评估面板能对不稳定预设给出明确警告。

---

# 验证步骤（每个 Step 都要跑的最小自测）

- 运行/停止仿真反复切换无报错
- Recorder 开关/清空反复操作无崩溃，窗口缓存长度稳定
- 图表在 50Hz 采样下仍可用（点数上限/下采样策略生效）
- 预设加载后推进器数量/方向/参数一致，可复现对比效果

---

# 输出物清单（执行时会改动/新增的关键点）

> 下面列的是“将会被创建/改动”的对象类型，用于你核对范围；真正执行阶段会按 Step 顺序逐项落地。

- 修改：`project.godot`（设置主场景；可能增加 Autoload/输入映射）
- 新增：`res://scenes/main/main.tscn`、`res://scenes/rov/rov.tscn`
- 新增：`res://scripts/sim/*`（物理与状态生成）
- 新增：`res://scripts/builder/*`（拼装/Inspector）
- 新增：`res://scripts/data/*`（Recorder/回放/保存）
- 新增：`res://scripts/ui/*`（Dashboard/Charts）

