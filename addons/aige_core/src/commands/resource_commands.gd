## Resource Commands - P0 资源系统
class_name ResourceCommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")

# === 加载资源 ===
static func load_resource(req: Dictionary) -> Dictionary:
	var path: String = req.get("path", "")
	
	if path.is_empty():
		return CLIResponse.error("INVALID_PATH", "资源路径不能为空")
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path):
		return CLIResponse.error("FILE_NOT_FOUND", "文件不存在: " + path)
	
	var resource: Resource = load(path)
	
	if resource == null:
		return CLIResponse.error("LOAD_FAILED", "资源加载失败")
	
	return CLIResponse.success({
		"path": path,
		"type": resource.get_class(),
		"resource_id": resource.get_rid()
	})

# === 保存资源 ===
static func save_resource(req: Dictionary) -> Dictionary:
	var path: String = req.get("path", "")
	var save_path: String = req.get("save_path", "")
	
	if path.is_empty():
		return CLIResponse.error("INVALID_PATH", "资源路径不能为空")
	
	var resource: Resource = load(path)
	if resource == null:
		return CLIResponse.error("LOAD_FAILED", "资源加载失败")
	
	if save_path.is_empty():
		save_path = path
	
	var err = ResourceSaver.save(resource, save_path)
	
	if err != OK:
		return CLIResponse.error("SAVE_FAILED", "保存失败，错误码: " + str(err))
	
	return CLIResponse.success({
		"original_path": path,
		"saved_path": save_path
	}, "资源保存成功")

# === 获取资源类型 ===
static func get_resource_type(req: Dictionary) -> Dictionary:
	var path: String = req.get("path", "")
	
	if not FileAccess.file_exists(path):
		return CLIResponse.error("FILE_NOT_FOUND", "文件不存在")
	
	var resource: Resource = load(path)
	if resource == null:
		return CLIResponse.error("LOAD_FAILED", "无法确定资源类型")
	
	return CLIResponse.success({
		"path": path,
		"type": resource.get_class(),
		"is_scene": resource is PackedScene
	})

# === 列出资源 (按类型) ===
static func list_by_type(req: Dictionary) -> Dictionary:
	var resource_type: String = req.get("type", "")
	var directory: String = req.get("directory", "res://")
	
	if resource_type.is_empty():
		return CLIResponse.error("INVALID_TYPE", "资源类型不能为空")
	
	var dir = DirAccess.open(directory)
	if dir == null:
		return CLIResponse.error("DIR_OPEN_FAILED", "无法打开目录")
	
	var items: Array = []
	
	dir.list_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = directory + "/" + file_name
			if full_path.ends_with(".tres") or full_path.ends_with(".tscn"):
				var res = load(full_path)
				if res != null and res.get_class() == resource_type:
					items.append({
						"path": full_path,
						"name": file_name
					})
		file_name = dir.get_next()
	
	dir.list_end()
	
	return CLIResponse.list(items)
