## Project Commands - P1 项目设置
class_name ProjectCommands
extends RefCounted

# === 获取项目设置 ===
static func get_setting(req: Dictionary) -> Dictionary:
	var key: String = req.get("key", "")
	
	if key.is_empty():
		# 返回所有设置
		var settings: Array = []
		for prop in ProjectSettings.get_property_list():
			settings.append({
				"name": prop.name,
				"type": prop.type
			})
		return CLIResponse.success({
			"settings": settings,
			"count": settings.size()
		})
	
	if not ProjectSettings.has_setting(key):
		return CLIResponse.error("SETTING_NOT_FOUND", "设置不存在: " + key)
	
	var value = ProjectSettings.get_setting(key)
	var prop_type = Variant.TYPE_NIL
	
	for prop in ProjectSettings.get_property_list():
		if prop.name == key:
			prop_type = prop.type
			break
	
	return CLIResponse.success({
		"key": key,
		"value": value,
		"type": Variant.type_get_name(prop_type)
	})

# === 设置项目设置 ===
static func set_setting(req: Dictionary) -> Dictionary:
	var key: String = req.get("key", "")
	var value: Variant = req.get("value")
	var info: Dictionary = req.get("info", {})
	
	if key.is_empty():
		return CLIResponse.error("INVALID_KEY", "设置键不能为空")
	
	# 设置初始值（如果不存在）
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, value)
		# 设置类型信息
		if info.has("type"):
			var type_id = int(info["type"])
			ProjectSettings.add_property_info({
				"name": key,
				"type": type_id
			})
	else:
		ProjectSettings.set_setting(key, value)
	
	# 设置属性信息
	if info.has("restart"):
		ProjectSettings.set_restart_if_changed(key, info["restart"])
	if info.has("runtime"):
		ProjectSettings.set_initial_value(key, info.get("initial", value))
	
	return CLIResponse.success({
		"key": key,
		"value": value,
		"set": true
	})

# === 删除设置 ===
static func remove_setting(req: Dictionary) -> Dictionary:
	var key: String = req.get("key", "")
	
	if not ProjectSettings.has_setting(key):
		return CLIResponse.error("SETTING_NOT_FOUND", "设置不存在")
	
	ProjectSettings.set_setting(key, null)
	
	return CLIResponse.success({
		"key": key,
		"removed": true
	})

# === 列出设置 (按分类) ===
static func list_by_category(req: Dictionary) -> Dictionary:
	var category: String = req.get("category", "")
	
	var settings: Array = []
	for prop in ProjectSettings.get_property_list():
		if category.is_empty() or prop.name.begins_with(category):
			settings.append({
				"name": prop.name,
				"type": Variant.type_get_name(prop.type),
				"hint": prop.hint if "hint" in prop else 0
			})
	
	return CLIResponse.success({
		"settings": settings,
		"count": settings.size()
	})

# === 常用设置快捷操作 ===
static func set_display_mode(req: Dictionary) -> Dictionary:
	var width: int = req.get("width", 1280)
	var height: int = req.get("height", 720)
	var mode: String = req.get("mode", "windowed")
	
	match mode:
		"fullscreen":
			ProjectSettings.set_setting("display/window/size/mode", Window.MODE_FULLSCREEN)
		"windowed":
			ProjectSettings.set_setting("display/window/size/mode", Window.MODE_WINDOWED)
		"borderless":
			ProjectSettings.set_setting("display/window/size/mode", Window.MODE_FULLSCREEN)
			ProjectSettings.set_setting("display/window/size/borderless", true)
	
	ProjectSettings.set_setting("display/window/size/viewport_width", width)
	ProjectSettings.set_setting("display/window/size/viewport_height", height)
	
	return CLIResponse.success({
		"width": width,
		"height": height,
		"mode": mode
	})

# === 设置渲染器 ===
static func set_renderer(req: Dictionary) -> Dictionary:
	var renderer: String = req.get("renderer", "forward_plus")
	
	match renderer:
		"forward_plus":
			ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
			ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "forward_plus")
		"mobile":
			ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")
			ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "mobile")
		"compatibility":
			ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
			ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
		_:
			return CLIResponse.error("INVALID_RENDERER", "无效渲染器: " + renderer)
	
	return CLIResponse.success({
		"renderer": renderer,
		"note": "需要重启编辑器生效"
	})

# === 设置主场景 ===
static func set_main_scene(req: Dictionary) -> Dictionary:
	var scene_path: String = req.get("scene", "")
	
	if not FileAccess.file_exists(scene_path):
		return CLIResponse.error("SCENE_NOT_FOUND", "场景文件不存在")
	
	ProjectSettings.set_setting("application/run/main_scene", scene_path)
	
	return CLIResponse.success({
		"main_scene": scene_path
	})

# === 设置项目名称 ===
static func set_project_name(req: Dictionary) -> Dictionary:
	var name: String = req.get("name", "MyProject")
	
	ProjectSettings.set_setting("application/config/name", name)
	
	return CLIResponse.success({
		"name": name
	})

# === 获取项目信息 ===
static func get_project_info(_req: Dictionary) -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load("res://project.godot")
	
	if err != OK:
		return CLIResponse.error("PROJECT_NOT_FOUND", "无法加载项目配置")
	
	var info = {
		"name": config.get_value("application", "config/name", "Untitled"),
		"main_scene": config.get_value("application", "run/main_scene", ""),
		"renderer": config.get_value("rendering", "renderer/rendering_method", "forward_plus"),
		"version": config.get_value("application", "config/version", "0.1.0")
	}
	
	return CLIResponse.success(info)
