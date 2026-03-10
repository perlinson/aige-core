## Editor Commands - P0 编辑器操作
class_name EditorCommands
extends RefCounted

# === 获取当前选择 ===
static func get_selection(_req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "仅在编辑器模式下可用")
	
	# 获取编辑器接口
	var editor_interface = _get_editor_interface()
	if editor_interface == null:
		return CLIResponse.error("NO_INTERFACE", "无法获取编辑器接口")
	
	var selection = editor_interface.get_selection()
	var selected_nodes = editor_interface.get_selected_paths()
	
	var items: Array = []
	for path in selected_nodes:
		items.append({"path": path})
	
	return CLIResponse.success({
		"selected_nodes": items,
		"count": items.size()
	})

# === 保存场景 ===
static func save_scene(req: Dictionary) -> Dictionary:
	var path: String = req.get("path", "")
	
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "仅在编辑器模式下可用")
	
	var editor_interface = _get_editor_interface()
	if editor_interface == null:
		return CLIResponse.error("NO_INTERFACE", "无法获取编辑器接口")
	
	if path.is_empty():
		# 保存当前场景
		var err = editor_interface.save_scene()
		if err != OK:
			return CLIResponse.error("SAVE_FAILED", "保存失败，错误码: " + str(err))
		return CLIResponse.success({"saved": "current_scene"})
	else:
		editor_interface.save_scene_as(path)
		return CLIResponse.success({"saved": path})

# === 获取打开的场景 ===
static func get_open_scenes(_req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "仅在编辑器模式下可用")
	
	var editor_interface = _get_editor_interface()
	if editor_interface == null:
		return CLIResponse.error("NO_INTERFACE", "无法获取编辑器接口")
	
	var open_scenes: Array = editor_interface.get_open_scenes()
	
	return CLIResponse.success({
		"scenes": open_scenes,
		"count": open_scenes.size()
	})

# === 打开场景 ===
static func open_scene(req: Dictionary) -> Dictionary:
	var path: String = req.get("path", "")
	
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "仅在编辑器模式下可用")
	
	if path.is_empty():
		return CLIResponse.error("INVALID_PATH", "路径不能为空")
	
	var editor_interface = _get_editor_interface()
	if editor_interface == null:
		return CLIResponse.error("NO_INTERFACE", "无法获取编辑器接口")
	
	editor_interface.open_scene_from_path(path)
	
	return CLIResponse.success({
		"opened": path
	}, "场景已打开")

# === 辅助函数 ===
static func _get_editor_interface() -> EditorInterface:
	# Godot编辑器中 EditorInterface 是单例
	if Engine.is_editor_hint():
		return EditorInterface.get_singleton()
	return null
