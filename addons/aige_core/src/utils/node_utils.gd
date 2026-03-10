## Node Utilities
class_name NodeUtils
extends RefCounted

# === 安全获取节点 ===
static func get_node_safe(path: String) -> Node:
	if path.is_empty():
		return Engine.get_main_loop()?.root?.get_child(0)
	
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		# 尝试直接获取
		var node = tree.root.get_node(path)
		if node:
			return node
		
		# 尝试相对路径
		if path.begins_with("/"):
			return tree.root.get_node(path.substr(1))
		else:
			return tree.root.get_node(path)
	
	return null

# === 节点路径解析 ===
static func parse_node_path(path_string: String) -> Dictionary:
	var parts = path_string.split("/")
	var node_name = parts[-1] if parts.size() > 0 else ""
	var parent_path = "/".join(parts.slice(0, -1))
	
	return {
		"full_path": path_string,
		"parent_path": parent_path,
		"node_name": node_name
	}

# === 获取节点树 ===
static func get_tree_as_dict(node: Node, max_depth: int = 3, current_depth: int = 0) -> Dictionary:
	if node == null or current_depth > max_depth:
		return {}
	
	var result: Dictionary = {
		"name": node.name,
		"type": node.get_class(),
		"path": node.get_path()
	}
	
	if current_depth < max_depth:
		var children: Array = []
		for child in node.get_children():
			children.append(get_tree_as_dict(child, max_depth, current_depth + 1))
		result["children"] = children
	
	return result
