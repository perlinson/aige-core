## UI Commands - P1 UI系统
class_name UICommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")
const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")

# === 创建容器 ===
static func create_container(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var container_type: String = req.get("type", "VBoxContainer")
	var name: String = req.get("name", container_type)
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	# 支持的容器类型
	var container: Control
	match container_type:
		"HBoxContainer":
			container = HBoxContainer.new()
		"VBoxContainer":
			container = VBoxContainer.new()
		"GridContainer":
			container = GridContainer.new()
			container.columns = req.get("columns", 3)
		"FlowContainer":
			container = FlowContainer.new()
		"CenterContainer":
			container = CenterContainer.new()
		"PanelContainer":
			container = PanelContainer.new()
		"ScrollContainer":
			container = ScrollContainer.new()
		"TabContainer":
			container = TabContainer.new()
		_:
			container = Control.new()  # 默认
	
	container.name = name
	parent.add_child(container)
	
	return CLIResponse.success({
		"path": container.get_path(),
		"name": name,
		"type": container_type
	})

# === 创建基础控件 ===
static func create_control(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var control_type: String = req.get("type", "Control")
	var name: String = req.get("name", control_type)
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var control: Control
	match control_type:
		"Button":
			control = Button.new()
		"Label":
			control = Label.new()
		"TextureRect":
			control = TextureRect.new()
		"ColorRect":
			control = ColorRect.new()
		"CheckBox":
			control = CheckBox.new()
		"CheckButton":
			control = CheckButton.new()
		"LineEdit":
			control = LineEdit.new()
		"TextEdit":
			control = TextEdit.new()
		"RichTextLabel":
			control = RichTextLabel.new()
		"HSlider":
			control = HSlider.new()
		"VSlider":
			control = VSlider.new()
		"ProgressBar":
			control = ProgressBar.new()
		"SpinBox":
			control = SpinBox.new()
		"OptionButton":
			control = OptionButton.new()
		"MenuButton":
			control = MenuButton.new()
		"PopupMenu":
			control = PopupMenu.new()
		"Tree":
			control = Tree.new()
		"ItemList":
			control = ItemList.new()
		_:
			control = Control.new()
	
	control.name = name
	parent.add_child(control)
	
	return CLIResponse.success({
		"path": control.get_path(),
		"name": name,
		"type": control_type
	})

# === 设置控件属性 ===
static func set_control_prop(req: Dictionary) -> Dictionary:
	var control_path: String = req.get("path", "")
	var prop: String = req.get("property", "")
	var value: Variant = req.get("value")
	
	var control: Control = NodeUtils.get_node_safe(control_path) as Control
	if control == null:
		return CLIResponse.error("INVALID_CONTROL", "不是有效的控件")
	
	match prop:
		"text":
			if control is BaseButton:
				(control as BaseButton).text = str(value)
			elif control is Label:
				(control as Label).text = str(value)
			elif control is LineEdit:
				(control as LineEdit).text = str(value)
		
		"placeholder":
			if control is LineEdit:
				(control as LineEdit).placeholder_text = str(value)
		
		"size":
			if value is Array and value.size() >= 2:
				control.custom_minimum_size = Vector2(float(value[0]), float(value[1]))
			elif value is Dictionary:
				control.custom_minimum_size = VariantUtils.from_json_value(value, Vector2.ZERO)
		
		"anchors":
			# 设置锚点 (preset)
			var preset_name = str(value)
			var preset = _get_anchor_preset(preset_name)
			if preset >= 0:
				control.anchors_preset = preset
		
		"visible":
			control.visible = bool(value)
		
		"disabled":
			if control is Control:
				control.process_mode = Node.PROCESS_MODE_DISABLED if bool(value) else Node.PROCESS_MODE_INHERIT
		
		"modulate":
			control.modulate = VariantUtils.from_json_value(value, Color.WHITE)
	
	return CLIResponse.success({
		"path": control_path,
		"property": prop,
		"value": str(value)
	})

# === 容器操作 ===
static func container_add(req: Dictionary) -> Dictionary:
	var container_path: String = req.get("container", "")
	var child_path: String = req.get("child", "")
	
	var container: Control = NodeUtils.get_node_safe(container_path) as Control
	var child: Node = NodeUtils.get_node_safe(child_path)
	
	if container == null:
		return CLIResponse.error("INVALID_CONTAINER", "不是有效的容器")
	if child == null:
		return CLIResponse.error("INVALID_CHILD", "子节点无效")
	
	# 如果子节点已经有父节点，先移除
	if child.get_parent() and child.get_parent() != container:
		child.reparent(container)
	else:
		container.add_child(child)
	
	return CLIResponse.success({
		"container": container_path,
		"child": child_path
	})

# === 添加选项到 OptionButton ===
static func option_add_item(req: Dictionary) -> Dictionary:
	var control_path: String = req.get("path", "")
	var text: String = req.get("text", "")
	var id: int = req.get("id", -1)
	
	var option: OptionButton = NodeUtils.get_node_safe(control_path) as OptionButton
	if option == null:
		return CLIResponse.error("INVALID_OPTION_BUTTON", "不是有效的OptionButton")
	
	if id >= 0:
		option.add_item(text, id)
	else:
		option.add_item(text)
	
	return CLIResponse.success({
		"path": control_path,
		"text": text,
		"id": id
	})

# === Tree 操作 ===
static func tree_add_item(req: Dictionary) -> Dictionary:
	var tree_path: String = req.get("path", "")
	var parent_item: TreeItem = req.get("parent_item", null)
	var text: String = req.get("text", "")
	var icon_path: String = req.get("icon", "")
	
	var tree: Tree = NodeUtils.get_node_safe(tree_path) as Tree
	if tree == null:
		return CLIResponse.error("INVALID_TREE", "不是有效的Tree")
	
	var item: TreeItem
	if parent_item:
		item = tree.create_item(parent_item)
	else:
		item = tree.create_item()
	
	item.set_text(0, text)
	
	if not icon_path.is_empty():
		var icon = load(icon_path)
		if icon:
			item.set_icon(0, icon)
	
	return CLIResponse.success({
		"path": tree_path,
		"text": text
	})

# === ItemList 操作 ===
static func itemlist_add_item(req: Dictionary) -> Dictionary:
	var list_path: String = req.get("path", "")
	var text: String = req.get("text", "")
	var icon_path: String = req.get("icon", "")
	
	var list: ItemList = NodeUtils.get_node_safe(list_path) as ItemList
	if list == null:
		return CLIResponse.error("INVALID_ITEMLIST", "不是有效的ItemList")
	
	var idx = list.add_item(text)
	
	if not icon_path.is_empty():
		var icon = load(icon_path)
		if icon:
			list.set_item_icon(idx, icon)
	
	return CLIResponse.success({
		"path": list_path,
		"text": text,
		"index": idx
	})

# === 辅助函数 ===
static func _get_anchor_preset(name: String) -> int:
	var presets = {
		"preset_left": Control.PRESET_LEFT,
		"preset_top": Control.PRESET_TOP,
		"preset_right": Control.PRESET_RIGHT,
		"preset_bottom": Control.PRESET_BOTTOM,
		"preset_center": Control.PRESET_CENTER,
		"preset_middle": Control.PRESET_MIDDLE,
		"preset_full_rect": Control.PRESET_FULL_RECT,
		"preset_wide": Control.PRESET_WIDE,
		"preset_tall": Control.PRESET_TALL,
		"preset_center_wide": Control.PRESET_CENTER_WIDE,
		"preset_center_tall": Control.PRESET_CENTER_TALL
	}
	return presets.get(name, -1)

# === 获取控件信息 ===
static func get_control_info(req: Dictionary) -> Dictionary:
	var control_path: String = req.get("path", "")
	
	var control: Control = NodeUtils.get_node_safe(control_path) as Control
	if control == null:
		return CLIResponse.error("INVALID_CONTROL", "不是有效的控件")
	
	var info: Dictionary = {
		"path": control.get_path(),
		"name": control.name,
		"type": control.get_class(),
		"size": VariantUtils.to_json_value(control.size),
		"position": VariantUtils.to_json_value(control.position),
		"visible": control.visible,
		"rect": VariantUtils.to_json_value(control.get_rect())
	}
	
	if control is BaseButton:
		info["text"] = (control as BaseButton).text
		info["pressed"] = (control as BaseButton).button_pressed
	elif control is Label:
		info["text"] = (control as Label).text
	elif control is LineEdit:
		info["text"] = (control as LineEdit).text
		info["placeholder"] = (control as LineEdit).placeholder_text
	
	return CLIResponse.success(info)
