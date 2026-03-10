## CLI Response Helper
class_name CLIResponse
extends RefCounted

static func success(data: Variant, message: String = "") -> Dictionary:
	return {
		"success": true,
		"data": data,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	}

static func error(code: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {
		"success": false,
		"error": {
			"code": code,
			"message": message,
			"details": details
		},
		"timestamp": Time.get_unix_time_from_system()
	}

static func list(items: Array, total: int = 0) -> Dictionary:
	return success({
		"items": items,
		"total": total if total > 0 else items.size()
	})
