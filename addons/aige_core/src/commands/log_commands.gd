## Log Commands - P0 日志系统
class_name LogCommands
extends RefCounted

# 日志级别常量
const LEVEL_DEBUG = 0
const LEVEL_INFO = 1
const LEVEL_WARNING = 2
const LEVEL_ERROR = 3

static var _log_cache: Array = []
static var _max_cache_size: int = 1000

# === 查询日志 ===
static func query_logs(req: Dictionary) -> Dictionary:
	var level: int = req.get("level", 0)  # 0=全部
	var lines: int = req.get("lines", 100)
	var source: String = req.get("source", "")
	var pattern: String = req.get("pattern", "")
	
	var results: Array = []
	
	# 从Godot日志系统获取
	var log_strings: Array = OS.get_log_strings()
	var log_colors: Array = OS.get_log_colors()
	
	var start_idx = max(0, log_strings.size() - lines)
	
	for i in range(start_idx, log_strings.size()):
		var msg: String = log_strings[i]
		var color: String = log_colors[i] if i < log_colors.size() else ""
		
		# 解析日志级别
		var msg_level = _parse_level_from_message(msg)
		
		# 过滤
		if level > 0 and msg_level < level:
			continue
		if not source.is_empty() and not msg.contains(source):
			continue
		if not pattern.is_empty() and not msg.contains(pattern):
			continue
		
		results.append({
			"index": i,
			"message": msg,
			"level": msg_level,
			"level_name": _level_to_name(msg_level),
			"color": color
		})
	
	return CLIResponse.list(results)

# === 日志统计 ===
static func get_stats(_req: Dictionary) -> Dictionary:
	var log_strings: Array = OS.get_log_strings()
	
	var stats: Dictionary = {
		"total": log_strings.size(),
		"debug": 0,
		"info": 0,
		"warning": 0,
		"error": 0,
		"by_source": {}
	}
	
	for msg in log_strings:
		var level = _parse_level_from_message(msg)
		match level:
			LEVEL_DEBUG: stats["debug"] += 1
			LEVEL_INFO: stats["info"] += 1
			LEVEL_WARNING: stats["warning"] += 1
			LEVEL_ERROR: stats["error"] += 1
	
	return CLIResponse.success(stats)

# === 写入日志 ===
static func write_log(req: Dictionary) -> Dictionary:
	var message: String = req.get("message", "")
	var level: int = req.get("level", LEVEL_INFO)
	
	match level:
		LEVEL_DEBUG: print_debug(message)
		LEVEL_INFO: print(message)
		LEVEL_WARNING: push_warning(message)
		LEVEL_ERROR: push_error(message)
	
	return CLIResponse.success({
		"written": true,
		"message": message,
		"level": _level_to_name(level)
	})

# === 辅助函数 ===
static func _parse_level_from_message(msg: String) -> int:
	msg = msg.to_lower()
	if msg.contains("error") or msg.contains("err"):
		return LEVEL_ERROR
	if msg.contains("warning") or msg.contains("warn"):
		return LEVEL_WARNING
	if msg.contains("debug"):
		return LEVEL_DEBUG
	return LEVEL_INFO

static func _level_to_name(level: int) -> String:
	match level:
		LEVEL_DEBUG: return "DEBUG"
		LEVEL_INFO: return "INFO"
		LEVEL_WARNING: return "WARNING"
		LEVEL_ERROR: return "ERROR"
		return "UNKNOWN"

# === 添加到日志缓存 (内部使用) ===
static func _add_to_cache(entry: Dictionary) -> void:
	_log_cache.append(entry)
	if _log_cache.size() > _max_cache_size:
		_log_cache.pop_front()

static func get_cached_logs(count: int = 100) -> Array:
	var start = max(0, _log_cache.size() - count)
	return _log_cache.slice(start)
