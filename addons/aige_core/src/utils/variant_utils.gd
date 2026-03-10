## Variant Utilities
class_name VariantUtils
extends RefCounted

# === Godot类型转字符串 ===
static func godot_type_to_string(type: int) -> String:
	match type:
		TYPE_NIL: return "nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_COLOR: return "Color"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		TYPE_CALLABLE: return "Callable"
		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
		_: return "unknown"

# === Variant转JSON兼容值 ===
static func to_json_value(variant: Variant) -> Variant:
	match typeof(variant):
		TYPE_VECTOR2:
			return {"x": variant.x, "y": variant.y}
		TYPE_VECTOR2I:
			return {"x": variant.x, "y": variant.y}
		TYPE_VECTOR3:
			return {"x": variant.x, "y": variant.y, "z": variant.z}
		TYPE_VECTOR3I:
			return {"x": variant.x, "y": variant.y, "z": variant.z}
		TYPE_RECT2:
			return {"x": variant.position.x, "y": variant.position.y, "w": variant.size.x, "h": variant.size.y}
		TYPE_RECT2I:
			return {"x": variant.position.x, "y": variant.position.y, "w": variant.size.x, "h": variant.size.y}
		TYPE_COLOR:
			return {"r": variant.r, "g": variant.g, "b": variant.b, "a": variant.a}
		TYPE_TRANSFORM2D:
			return {"xx": variant.x.x, "xy": variant.x.y, "yx": variant.y.x, "yy": variant.y.y, "ox": variant.origin.x, "oy": variant.origin.y}
		TYPE_BASIS:
			return {"xx": variant[0].x, "xy": variant[0].y, "xz": variant[0].z}
		TYPE_TRANSFORM3D:
			return {"xx": variant.basis[0].x, "xy": variant.basis[0].y, "xz": variant.basis[0].z}
		TYPE_ARRAY, TYPE_DICTIONARY, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			return JSON.stringify(variant)
		TYPE_NODE_PATH:
			return str(variant)
		TYPE_OBJECT:
			if variant is Resource:
				return {"resource_path": variant.resource_path if "resource_path" in variant else ""}
			return {"class": variant.get_class()}
	
	return variant

# === JSON值转Variant ===
static func from_json_value(json: Variant, default: Variant = null) -> Variant:
	if json == null:
		return default
	
	var type = typeof(default)
	
	match type:
		TYPE_VECTOR2:
			if json is Dictionary and json.has("x") and json.has("y"):
				return Vector2(float(json.x), float(json.y))
		TYPE_VECTOR3:
			if json is Dictionary and json.has("x") and json.has("y") and json.has("z"):
				return Vector3(float(json.x), float(json.y), float(json.z))
		TYPE_COLOR:
			if json is Dictionary and json.has("r"):
				return Color(float(json.r), float(json.get("g", 0)), float(json.get("b", 0)), float(json.get("a", 1)))
		TYPE_BOOL:
			return bool(json)
		TYPE_INT:
			return int(json)
		TYPE_FLOAT:
			return float(json)
	
	# 尝试智能解析
	if json is String:
		# 尝试解析为Vector2
		if json.begins_with("(") and json.ends_with(")"):
			var parts = json.substr(1, json.length()-2).split(",")
			if parts.size() == 2:
				return Vector2(float(parts[0]), float(parts[1]))
			elif parts.size() == 3:
				return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	
	return json if json != null else default
