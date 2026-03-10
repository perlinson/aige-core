## Scene Commands - P0 场景节点管理
class_name SceneCommands
extends RefCounted

const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")
const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")

# === 节点创建 ===
static func create_node(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var node_type: String = req.get("type", "Node")
	var node_name: String = req.get("name", "")
	
	# 获取父节点
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在: " + parent_path)
	
	# 验证节点类型
	if not ClassDB.class_exists(node_type):
		return CLIResponse.error("INVALID_TYPE", "无效节点类型: " + node_type)
	
	# 创建节点
	var new_node: Node = ClassDB.create_instance(node_type)
	if new_node == null:
		return CLIResponse.error("CREATE_FAILED", "无法创建节点类型: " + node_type)
	
	# 设置名称
	if node_name.is_empty():
		node_name = node_type
	new_node.name = node_name
	
	# 添加到父节点
	parent.add_child(new_node)
	
	# 返回结果
	return CLIResponse.success({
		"path": new_node.get_path(),
		"name": new_node.name,
		"type": node_type,
		"parent": parent_path
	}, "节点创建成功")

# === 节点删除 ===
static func delete_node(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("path", "")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在: " + node_path)
	
	# 不允许删除根节点
	if node == node.get_tree().root:
		return CLIResponse.error("CANNOT_DELETE", "无法删除根节点")
	
	var parent_path: String = node.get_parent().get_path() if node.get_parent() else ""
	node.queue_free()
	
	# 等待一帧让queue_free生效
	await node.get_tree().process_frame
	
	return CLIResponse.success({
		"deleted_path": node_path,
		"new_parent": parent_path
	}, "节点已标记删除")

# === 节点列表 ===
static func list_nodes(req: Dictionary) -> Dictionary:
	var root_path: String = req.get("root", "/root")
	var filter_type: String = req.get("filter", "")
	var recursive: bool = req.get("recursive", true)
	
	var root: Node = NodeUtils.get_node_safe(root_path)
	if root == null:
		return CLIResponse.error("ROOT_NOT_FOUND", "根节点不存在: " + root_path)
	
	var items: Array = []
	var queue: Array = [root]
	
	while queue.size() > 0:
		var current: Node = queue.pop_front()
		var add_children: bool = true
		
		# 类型过滤
		if not filter_type.is_empty():
			if current.get_class() != filter_type and not _is_derived_of(current, filter_type):
				add_children = false
		
		# 添加到结果
		items.append({
			"path": current.get_path(),
			"name": current.name,
			"type": current.get_class(),
			"child_count": current.get_child_count()
		})
		
		# 添加子节点到队列
		if recursive and add_children:
			for child in current.get_children():
				queue.append(child)
	
	return CLIResponse.list(items)

static func _is_derived_of(node: Node, class_name: String) -> bool:
	return ClassDB.is_parent_class(node.get_class(), class_name)

# === 获取属性 ===
static func get_property(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("path", "")
	var property: String = req.get("property", "")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在: " + node_path)
	
	if property.is_empty():
		# 返回所有属性
		var props: Array = []
		for p in node.get_property_list():
			props.append({
				"name": p["name"],
				"type": VariantUtils.godot_type_to_string(p["type"])
			})
		return CLIResponse.success({"properties": props})
	
	# 获取单个属性
	if not node.has_property(property):
		return CLIResponse.error("PROPERTY_NOT_FOUND", "属性不存在: " + property)
	
	var value = node.get(property)
	return CLIResponse.success({
		"path": node_path,
		"property": property,
		"value": VariantUtils.to_json_value(value),
		"type": VariantUtils.godot_type_to_string(typeof(value))
	})

# === 设置属性 ===
static func set_property(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("path", "")
	var property: String = req.get("property", "")
	var value: Variant = req.get("value")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在: " + node_path)
	
	if not node.has_property(property):
		return CLIResponse.error("PROPERTY_NOT_FOUND", "属性不存在: " + property)
	
	# 类型转换
	var converted_value = VariantUtils.from_json_value(value, node.get(property))
	
	node.set(property, converted_value)
	
	return CLIResponse.success({
		"path": node_path,
		"property": property,
		"value": VariantUtils.to_json_value(converted_value)
	}, "属性已设置")

# === 移动节点 (Reparent) ===
static func reparent_node(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("path", "")
	var new_parent_path: String = req.get("new_parent", "")
	var keep_global_pos: bool = req.get("keep_global_pos", true)
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在: " + node_path)
	
	var new_parent: Node = NodeUtils.get_node_safe(new_parent_path)
	if new_parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "新父节点不存在: " + new_parent_path)
	
	# 防止循环引用
	if _is_ancestor(node, new_parent):
		return CLIResponse.error("CIRCULAR_REF", "无法将节点移动到其子节点下")
	
	var old_parent_path = node.get_parent().get_path() if node.get_parent() else ""
	node.reparent(new_parent, keep_global_pos)
	
	return CLIResponse.success({
		"node": node_path,
		"old_parent": old_parent_path,
		"new_parent": new_parent_path
	}, "节点已移动")

static func _is_ancestor(parent: Node, child: Node) -> bool:
	var current = child.get_parent()
	while current:
		if current == parent:
			return true
		current = current.get_parent()
	return false

# === 获取节点信息 ===
static func get_node_info(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("path", "")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在: " + node_path)
	
	var info: Dictionary = {
		"path": node.get_path(),
		"name": node.name,
		"type": node.get_class(),
		"parent": node.get_parent().get_path() if node.get_parent() else "",
		"child_count": node.get_child_count(),
		"groups": node.get_groups(),
		"filename": node.scene_file_path if "scene_file_path" in node else ""
	}
	
	# 如果是CanvasItem (2D节点)
	if node is CanvasItem:
		var canvas_item: CanvasItem = node as CanvasItem
		info["visible"] = canvas_item.visible
		info["modulate"] = canvas_item.modulate
		info["z_index"] = canvas_item.z_index
	
	# 如果是Node2D
	if node is Node2D:
		var node2d: Node2D = node as Node2D
		info["position"] = node2d.position
		info["rotation"] = node2d.rotation
		info["scale"] = node2d.scale
	
	return CLIResponse.success(info)
