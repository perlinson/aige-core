## Script Commands - P1 脚本系统
class_name ScriptCommands
extends RefCounted

const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")

# === 创建脚本 ===
static func create_script(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var script_path: String = req.get("path", "")
	var language: String = req.get("language", "GDScript")
	var class_name: String = req.get("class_name", "")
	var extends: String = req.get("extends", "Node")
	
	if script_path.is_empty():
		return CLIResponse.error("INVALID_PATH", "脚本路径不能为空")
	
	# 解析扩展类
	var extends_class = extends
	if extends.begins_with("res://"):
		# 是资源路径
		pass
	
	# 创建脚本内容
	var script_code = _generate_template(language, class_name, extends_class)
	
	# 保存脚本文件
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return CLIResponse.error("FILE_CREATE_FAILED", "无法创建脚本文件")
	
	file.store_string(script_code)
	file.close()
	
	# 创建脚本节点并附加
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent != null:
		var script = load(script_path)
		if script:
			parent.set_script(script)
	
	return CLIResponse.success({
		"path": script_path,
		"language": language,
		"class_name": class_name
	})

# === 附加脚本到节点 ===
static func attach_script(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("node", "")
	var script_path: String = req.get("script", "")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在")
	
	if not FileAccess.file_exists(script_path):
		return CLIResponse.error("SCRIPT_NOT_FOUND", "脚本文件不存在")
	
	var script: Script = load(script_path)
	if script == null:
		return CLIResponse.error("LOAD_FAILED", "脚本加载失败")
	
	node.set_script(script)
	
	return CLIResponse.success({
		"node": node_path,
		"script": script_path
	})

# === 分离脚本 ===
static func detach_script(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("node", "")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在")
	
	if node.get_script() == null:
		return CLIResponse.error("NO_SCRIPT", "节点没有脚本")
	
	node.set_script(null)
	
	return CLIResponse.success({
		"node": node_path,
		"detached": true
	})

# === 获取脚本代码 ===
static func get_code(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("path", "")
	
	if not FileAccess.file_exists(script_path):
		return CLIResponse.error("SCRIPT_NOT_FOUND", "脚本文件不存在")
	
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return CLIResponse.error("FILE_OPEN_FAILED", "无法打开脚本文件")
	
	var code = file.get_as_text()
	file.close()
	
	return CLIResponse.success({
		"path": script_path,
		"code": code,
		"lines": code.split("\n").size()
	})

# === 设置/替换脚本代码 ===
static func set_code(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("path", "")
	var code: String = req.get("code", "")
	var append: bool = req.get("append", false)
	
	if not FileAccess.file_exists(script_path):
		return CLIResponse.error("SCRIPT_NOT_FOUND", "脚本文件不存在")
	
	if append:
		var file = FileAccess.open(script_path, FileAccess.READ)
		var existing = file.get_as_text() if file else ""
		file.close()
		code = existing + "\n" + code
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return CLIResponse.error("FILE_WRITE_FAILED", "无法写入脚本文件")
	
	file.store_string(code)
	file.close()
	
	return CLIResponse.success({
		"path": script_path,
		"lines": code.split("\n").size()
	})

# === 验证脚本 ===
static func validate_script(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("path", "")
	
	if not FileAccess.file_exists(script_path):
		return CLIResponse.error("SCRIPT_NOT_FOUND", "脚本文件不存在")
	
	var script: Script = load(script_path)
	if script == null:
		return CLIResponse.error("LOAD_FAILED", "无法加载脚本")
	
	# GDScript 可以通过编译检查
	var is_valid = script.has_method("_ready") or script.get_method_list().size() > 0
	
	return CLIResponse.success({
		"path": script_path,
		"valid": is_valid,
		"class_name": script.get_global_class_name() if "get_global_class_name" in script else "",
		"methods": script.get_method_list().size()
	})

# === 运行脚本 (作为工具) ===
static func run_script(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("path", "")
	var args: Array = req.get("args", [])
	
	if not FileAccess.file_exists(script_path):
		return CLIResponse.error("SCRIPT_NOT_FOUND", "脚本文件不存在")
	
	var script: Script = load(script_path)
	if script == null:
		return CLIResponse.error("LOAD_FAILED", "无法加载脚本")
	
	# 创建脚本实例并运行
	# 注意：这需要在Editor或Play模式下
	if Engine.is_editor_hint():
		return CLIResponse.error("EDITOR_ONLY", "此功能仅在编辑器中可用")
	
	return CLIResponse.success({
		"path": script_path,
		"args": args,
		"note": "Script execution in editor mode not implemented"
	})

# === 获取脚本信息 ===
static func get_script_info(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("path", "")
	
	if not FileAccess.file_exists(script_path):
		return CLIResponse.error("SCRIPT_NOT_FOUND", "脚本文件不存在")
	
	var script: Script = load(script_path)
	if script == null:
		return CLIResponse.error("LOAD_FAILED", "无法加载脚本")
	
	var methods: Array = []
	for m in script.get_method_list():
		methods.append({
			"name": m.name,
			"args": m.args.size(),
			"return_type": m.return_type
		})
	
	var properties: Array = []
	if "get_property_list" in script:
		for p in script.get_property_list():
			properties.append({
				"name": p.name,
				"type": p.type
			})
	
	return CLIResponse.success({
		"path": script_path,
		"language": "GDScript",  # 简化处理
		"methods": methods,
		"properties": properties
	})

# === 辅助函数 ===
static func _generate_template(language: String, class_name: String, extends: String) -> String:
	match language.to_lower():
		"gdscript":
			var code = "extends %s\n\n" % extends
			code += "class_name %s\n\n" % class_name if not class_name.is_empty() else ""
			code += "# Auto-generated script\n\n"
			code += "func _ready():\n\tpass\n"
			return code
		_:
			return "// Auto-generated script\n"
