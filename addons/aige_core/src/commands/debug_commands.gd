## Debug Commands - P0 调试系统
class_name DebugCommands
extends RefCounted

static var _breakpoints: Array = []

# === 添加断点 ===
static func add_breakpoint(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("script", "")
	var line: int = req.get("line", 1)
	
	if script_path.is_empty():
		return CLIResponse.error("INVALID_SCRIPT", "脚本路径不能为空")
	
	var bp: Dictionary = {
		"script": script_path,
		"line": line,
		"enabled": true,
		"id": _breakpoints.size()
	}
	
	# 检查是否已存在
	for existing in _breakpoints:
		if existing.script == script_path and existing.line == line:
			return CLIResponse.error("BP_EXISTS", "断点已存在")
	
	_breakpoints.append(bp)
	
	# 尝试在脚本中设置断点
	_set_script_breakpoint(script_path, line, true)
	
	return CLIResponse.success({
		"id": bp.id,
		"script": script_path,
		"line": line
	}, "断点已添加")

# === 删除断点 ===
static func remove_breakpoint(req: Dictionary) -> Dictionary:
	var script_path: String = req.get("script", "")
	var line: int = req.get("line", 0)
	
	var removed: bool = false
	var removed_bp: Dictionary = {}
	
	for i in range(_breakpoints.size() - 1, -1, -1):
		var bp = _breakpoints[i]
		if bp.script == script_path and (line == 0 or bp.line == line):
			removed_bp = bp
			_breakpoints.remove_at(i)
			removed = true
			break
	
	if removed:
		_set_script_breakpoint(script_path, line, false)
		return CLIResponse.success({"removed": removed_bp})
	
	return CLIResponse.error("BP_NOT_FOUND", "断点未找到")

# === 列出断点 ===
static func list_breakpoints(_req: Dictionary) -> Dictionary:
	return CLIResponse.success({
		"breakpoints": _breakpoints,
		"total": _breakpoints.size()
	})

# === 获取堆栈追踪 ===
static func get_stacktrace(_req: Dictionary) -> Dictionary:
	var frames: Array = []
	
	# 获取当前调用栈
	var current_frame = get_stack()
	if current_frame:
		for i in range(current_frame.size()):
			var frame = current_frame[i]
			frames.append({
				"level": i,
				"source": frame.get("source", ""),
				"function": frame.get("function", ""),
				"line": frame.get("line", 0)
			})
	
	# 尝试获取脚本调试器的堆栈
	var debugger = Engine.get_meta("ScriptDebugger")
	if debugger:
		# 调试器API可能不同版本有差异
		pass
	
	return CLIResponse.success({
		"frames": frames,
		"count": frames.size()
	})

# === 辅助函数 ===
static func _set_script_breakpoint(script_path: String, line: int, enable: bool) -> void:
	# 这个功能需要访问脚本调试器
	# Godot 4.x 中可以通过脚本系统设置
	# 这里是一个简化的实现
	pass

# === 启用/禁用断点 ===
static func set_breakpoint_enabled(req: Dictionary) -> Dictionary:
	var bp_id: int = req.get("id", -1)
	var enabled: bool = req.get("enabled", true)
	
	if bp_id < 0 or bp_id >= _breakpoints.size():
		return CLIResponse.error("BP_NOT_FOUND", "断点ID无效")
	
	_breakpoints[bp_id].enabled = enabled
	_set_script_breakpoint(
		_breakpoints[bp_id].script,
		_breakpoints[bp_id].line,
		enabled
	)
	
	return CLIResponse.success({
		"id": bp_id,
		"enabled": enabled
	})
