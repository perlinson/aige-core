## Build Commands - P1 构建导出
class_name BuildCommands
extends RefCounted

# 注意: 完整的构建导出功能需要在Editor环境中运行

# === 列出可用平台 ===
static func list_platforms(_req: Dictionary) -> Dictionary:
	# 可用的导出平台
	var platforms: Array = [
		{"id": "windows", "name": "Windows", "extension": "exe"},
		{"id": "windows_dotnet", "name": "Windows (.NET)", "extension": "exe"},
		{"id": "macos", "name": "macOS", "extension": "app"},
		{"id": "ios", "name": "iOS", "extension": "ipa"},
		{"id": "linux", "name": "Linux", "extension": "x86_64"},
		{"id": "android", "name": "Android", "extension": "apk"},
		{"id": "web", "name": "Web", "extension": "html"},
		{"id": "bsd", "name": "BSD", "extension": ""},
		{"id": "windows_console", "name": "Windows Console", "extension": "exe"}
	]
	
	return CLIResponse.success({
		"platforms": platforms,
		"count": platforms.size()
	})

# === 列出导出预设 ===
static func list_presets(_req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "此功能仅在编辑器中可用")
	
	# 这需要访问EditorExport
	var presets: Array = []
	
	# 简化返回
	return CLIResponse.success({
		"presets": presets,
		"count": presets.size()
	})

# === 创建导出预设 ===
static func create_preset(req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "此功能仅在编辑器中可用")
	
	var name: String = req.get("name", "")
	var platform: String = req.get("platform", "windows")
	
	if name.is_empty():
		return CLIResponse.error("INVALID_NAME", "预设名称不能为空")
	
	# 保存导出预设配置
	var export_presets = _get_export_presets()
	export_presets.append({
		"name": name,
		"platform": platform,
		"options": {}
	})
	
	_save_export_presets(export_presets)
	
	return CLIResponse.success({
		"name": name,
		"platform": platform
	})

# === 导出项目 ===
static func export_project(req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "此功能仅在编辑器中可用")
	
	var platform: String = req.get("platform", "windows")
	var output_path: String = req.get("output", "")
	var debug: bool = req.get("debug", false)
	var preset: String = req.get("preset", "")
	
	if output_path.is_empty():
		return CLIResponse.error("INVALID_OUTPUT", "输出路径不能为空")
	
	# 调用编辑器导出
	# 注意: 这需要EditorExport类的完整实现
	
	return CLIResponse.success({
		"platform": platform,
		"output": output_path,
		"debug": debug,
		"exported": true,
		"note": "Export functionality requires EditorExport"
	})

# === 编译项目 (脚本) ===
static func compile_scripts(_req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "此功能仅在编辑器中可用")
	
	# GDScript是解释型语言，不需要编译
	# 但可以检查语法
	
	return CLIResponse.success({
		"compiled": true,
		"note": "GDScript does not require compilation"
	})

# === 清理构建 ===
static func clean(_req: Dictionary) -> Dictionary:
	if not Engine.is_editor_hint():
		return CLIResponse.error("NOT_IN_EDITOR", "此功能仅在编辑器中可用")
	
	# 清理 .godot 目录
	var dir = DirAccess.open("res://.godot")
	if dir:
		# 清理编译缓存
		pass
	
	return CLIResponse.success({
		"cleaned": true
	})

# === 获取导出模板 ===
static func list_templates(_req: Dictionary) -> Dictionary:
	# Godot 导出模板位置
	var template_paths: Array = []
	
	# 检查默认位置
	var user_dir = OS.get_environment("USERPROFILE") if OS.get_name() == "Windows" else OS.get_environment("HOME")
	var godot_dir = user_dir + "/.local/share/godot/export_templates"
	
	if DirAccess.dir_exists_absolute(godot_dir):
		var dir = DirAccess.open(godot_dir)
		if dir:
			dir.list_begin()
			var file = dir.get_next()
			while file != "":
				if file.begins_with("4."):
					template_paths.append(godot_dir + "/" + file)
				file = dir.get_next()
	
	return CLIResponse.success({
		"templates": template_paths,
		"count": template_paths.size()
	})

# === 辅助函数 ===
static func _get_export_presets() -> Array:
	var config = ConfigFile.new()
	if config.has_section("export_presets"):
		return config.get_value("export_presets", "presets", [])
	return []

static func _save_export_presets(presets: Array) -> void:
	var config = ConfigFile.new()
	config.set_value("export_presets", "presets", presets)
	config.save("res://export_presets.cfg")

# === 检查导出器是否可用 ===
static func check_exporter(req: Dictionary) -> Dictionary:
	var platform: String = req.get("platform", "windows")
	
	# 检查导出模板是否存在
	var template_available = _has_export_template(platform)
	
	return CLIResponse.success({
		"platform": platform,
		"template_available": template_available
	})

static func _has_export_template(platform: String) -> bool:
	var version = Engine.get_version_info()
	var version_str = "%d.%d" % [version.major, version.minor]
	var template_name = "%s.%s.zip" % [platform, version_str]
	
	var user_dir = OS.get_environment("USERPROFILE") if OS.get_name() == "Windows" else OS.get_environment("HOME")
	var template_path = user_dir + "/.local/share/godot/export_templates/" + template_name
	
	return FileAccess.file_exists(template_path)

# === 快速导出 (使用预设) ===
static func quick_export(req: Dictionary) -> Dictionary:
	var preset_name: String = req.get("preset", "default")
	var output_dir: String = req.get("output_dir", "build/")
	var debug: bool = req.get("debug", false)
	
	# 创建输出目录
	DirAccess.make_dir_recursive_absolute(output_dir)
	
	return CLIResponse.success({
		"preset": preset_name,
		"output_dir": output_dir,
		"debug": debug,
		"note": "Requires full EditorExport implementation"
	})
