# PanelCard

带标题和内容容器的卡片模块，用来承载一组高内聚 UI 内容。

## 结构

```text
ui_modules/PanelCard/
  PanelCard.tscn
  PanelCard.gd
  README.md
```

## 能力

- 提供统一卡片边距、标题区和内容区
- 可作为功能块的外层容器
- 适合协议配置段、统计段、文件操作段等复合内容

## 关键接口

- `set_title_text(value: String) -> void`
- `get_content_container() -> VBoxContainer`

## 用法

```gdscript
var card: PanelCard = preload("res://ui_modules/PanelCard/PanelCard.tscn").instantiate() as PanelCard
card.set_title_text(UICore.translate("SEND_FILE_TITLE"))
card.get_content_container().add_child(preload("res://ui_modules/FileDialogPanel/FileDialogPanel.tscn").instantiate())
add_child(card)
```

## 约束

- 卡片本身不处理内部业务状态；内容节点由外层装配。
