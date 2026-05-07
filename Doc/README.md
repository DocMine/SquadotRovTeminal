# SquadotRovHub 项目整体说明

本工程已经整理为一个统一的 Godot 根项目，默认启动入口为 `res://Levels/1_WelcomeScene/WelcomScene.tscn`。后续开发、重构和验收均以 [Godot工程通用要求.md](/C:/Users/limit/Desktop/SquadotRovHub/Doc/Godot工程通用要求.md) 为最高约束。

## 1. 功能入口

根入口场景：`Levels/1_WelcomeScene`

- `Tool` 按钮进入 `Levels/6_SquareDotSerial/Scenes/Main/MainWorkspace.tscn`
- `ROV sim` 按钮进入 `Levels/5_rovsim/scenes/main/main.tscn`
- `Demonstration` 按钮进入 `Levels/2_RovSelectScene/selection_page.tscn`
- `PID Teach` 按钮进入 `Levels/4_PIDTeach/scenes/pid_teach.tscn`

二级选择场景：`Levels/2_RovSelectScene`

- `仿真操作` 按钮进入 `Levels/5_rovsim/scenes/main/main.tscn`
- `硬件连接` 按钮进入 `Levels/6_SquareDotSerial/Scenes/Main/MainWorkspace.tscn`
- `返回主菜单` 回到 `Levels/1_WelcomeScene/WelcomScene.tscn`

## 2. 目录职责

- `modules/ui_modules`
  - 根项目共享 UI 模块、基础预制件和核心 UI helper。
  - 本次整合中保留为唯一共享模块来源，不再在子项目中复制一份。
  - `modules/ui_modules/0_Core_Autoload/UICore.gd` 是统一 UI 核心入口；共享本地化、主题和点击音效能力都从这里汇合。
- `addons`
  - 根项目共享插件目录。
  - 当前集成依赖主要包括 `gdserial`、`tau-plot`、`graph_2d`。
- `Levels/5_rovsim`
  - 集成后的 ROV 仿真功能。
  - `scripts/ui/root_control.gd` 已重构为真正的 UI 聚合层，页面级脚本位于 `scripts/ui/panels/`。
- `Levels/6_SquareDotSerial`
  - 串口、协议、收发、图表、自动化工具主功能。
  - 主工作区维持“页面根 + 子面板 + 父节点中介”的结构。
- `Levels/3_RovTestGround`
  - 保留的旧仿真/测试关卡，用于兼容旧资源和对照调试。
- `Levels/4_PIDTeach`
  - 保留的 PID 教学关卡。

## 3. 当前架构约束

- 所有共享实现优先放在 `modules/` 与 `addons/`，不要把同一功能在多个 `Levels/*` 下再复制实现。
- 页面根脚本只负责组装、状态同步、信号转发，不直接持有大批 UI 叶子节点。
- `5_rovsim` 的 `main.gd` 只直接依赖仿真对象、记录器、相机、渲染器和 `RootControl`。
- 入口场景与选择场景中，旧的重复内嵌脚本已经移除，避免并行维护两套按钮跳转逻辑。
- 全项目已清除 `:=`，后续新增脚本继续禁止回退到隐式类型推断写法。
- 文件选择/保存统一走系统对话框；显示给用户的路径必须是绝对路径。

## 4. 本地化与 UI

- 运行时文本必须走本地化入口，不允许长期硬编码用户可见文案。
- 根项目统一翻译表位于 `locale/ui_translations.csv`，`6_SquareDotSerial` 已不再单独维护私有 `Localization/` 副本。
- 编辑器内默认仍应直接显示中文可读文本，而不是翻译 key。
- 高频组合控件优先复用 `modules/ui_modules` 中已有模块，例如：
  - `LabelValueRow`
  - `LabelSpinRow`
  - `LabelOptionRow`
  - `FileDialogPanel`
  - `StatusBadge`
  - `TauRealtimeChart`

## 5. 验证方式

根工程启动验证：

```powershell
.\Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 3
```

欢迎页路由 smoke test：

```powershell
.\Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://Scripts/welcome_navigation_smoke.gd
```

ROV sim 子项目验证：

```powershell
.\Godot_v4.6.2-stable_win64_console.exe --headless --path .\Levels\5_rovsim --quit-after 2
```

Serial Tool 子项目验证：

```powershell
.\Godot_v4.6.2-stable_win64_console.exe --headless --path .\Levels\6_SquareDotSerial --quit-after 2
```

Godot 4.6.1 兼容启动验证：

```powershell
C:\Users\limit\Desktop\Godot_v4.6.1-stable_win64.exe --headless --path . --quit-after 3
```

当前在本机 headless 环境下仍可能看到的非功能性信息：

- Windows 根证书读取失败
- `ObjectDB instances leaked at exit`

这两项目前不阻断场景加载与入口路由。

## 6. 后续维护要求

- 新增功能优先挂接到现有入口，不要再新建平行主场景。
- 新增共享 UI 先评估是否应进入 `modules/ui_modules/<模块名>/`，并补 `README.md`。
- 修改公开 API、信号或页面职责时，必须同步更新脚本 `##` 注释和本目录文档。
- 如果再次整合外部项目，先消除重复实现，再接入按钮路由，不允许保留“旧场景仍藏着另一套逻辑”的状态。
