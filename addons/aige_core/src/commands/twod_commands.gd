## 2D Commands - P1 2D对象系统
class_name TwoDCommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")
const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")

# === 创建 Sprite ===
static func create_sprite(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "Sprite2D")
	var texture_path: String = req.get("texture", "")
	var animated: bool = req.get("animated", false)
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var sprite: Node
	if animated:
		sprite = AnimatedSprite2D.new()
	else:
		sprite = Sprite2D.new()
	
	sprite.name = name
	
	# 设置纹理
	if not texture_path.is_empty():
		var texture = load(texture_path)
		if texture:
			if sprite is AnimatedSprite2D:
				(sprite as AnimatedSprite2D).sprite_frames = texture
			else:
				(sprite as Sprite2D).texture = texture
	
	parent.add_child(sprite)
	
	return CLIResponse.success({
		"path": sprite.get_path(),
		"name": name,
		"type": "Sprite2D" if not animated else "AnimatedSprite2D"
	})

# === 创建 Polygon2D ===
static func create_polygon(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "Polygon2D")
	var points: Array = req.get("points", [])
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var polygon = Polygon2D.new()
	polygon.name = name
	
	# 转换点
	var converted_points: PackedVector2Array = []
	for p in points:
		if p is Array and p.size() >= 2:
			converted_points.append(Vector2(float(p[0]), float(p[1])))
	
	if converted_points.size() > 0:
		polygon.polygon = converted_points
	
	parent.add_child(polygon)
	
	return CLIResponse.success({
		"path": polygon.get_path(),
		"name": name,
		"points_count": converted_points.size()
	})

# === 创建 Line2D ===
static func create_line(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "Line2D")
	var points: Array = req.get("points", [])
	var width: float = req.get("width", 2.0)
	var color: Color = Color.WHITE
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("", "父节点PARENT_NOT_FOUND不存在")
	
	var line = Line2D.new()
	line.name = name
	line.width = width
	
	# 转换颜色
	if req.has("color"):
		color = VariantUtils.from_json_value(req["color"], Color.WHITE)
	line.default_color = color
	
	# 转换点
	var converted_points: PackedVector2Array = []
	for p in points:
		if p is Array and p.size() >= 2:
			converted_points.append(Vector2(float(p[0]), float(p[1])))
	
	if converted_points.size() > 0:
		line.points = converted_points
	
	parent.add_child(line)
	
	return CLIResponse.success({
		"path": line.get_path(),
		"name": name,
		"points_count": converted_points.size()
	})

# === 创建 Camera2D ===
static func create_camera(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "Camera2D")
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var camera = Camera2D.new()
	camera.name = name
	camera.make_current()
	
	parent.add_child(camera)
	
	return CLIResponse.success({
		"path": camera.get_path(),
		"name": name
	})

# === 创建 TileMapLayer (Godot 4.x) ===
static func create_tilemap(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "TileMapLayer")
	var tile_set_path: String = req.get("tileset", "")
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var tilemap = TileMapLayer.new()
	tilemap.name = name
	
	# 加载 tileset
	if not tile_set_path.is_empty():
		var tile_set = load(tile_set_path)
		if tile_set:
			tilemap.tile_set = tile_set
	
	parent.add_child(tilemap)
	
	return CLIResponse.success({
		"path": tilemap.get_path(),
		"name": name
	})

# === 创建 ParallaxLayer ===
static func create_parallax(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "ParallaxLayer")
	var scroll_scale: Vector2 = Vector2(0.5, 0.5)
	var mirror: Vector2 = Vector2.ZERO
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	# 查找或创建 ParallaxBackground
	var parallax: ParallaxBackground = parent as ParallaxBackground
	if parallax == null:
		# 向上查找
		var current = parent
		while current:
			if current is ParallaxBackground:
				parallax = current
				break
			current = current.get_parent()
	
	# 如果没有，创建一个
	if parallax == null:
		parallax = ParallaxBackground.new()
		parent.add_child(parallax)
	
	var layer = ParallaxLayer.new()
	layer.name = name
	layer.motion_scale = scroll_scale
	layer.motion_mirror = mirror
	
	parallax.add_child(layer)
	
	return CLIResponse.success({
		"path": layer.get_path(),
		"name": name,
		"parent": parallax.get_path()
	})

# === 2D 变换操作 ===
static func transform_2d(req: Dictionary) -> Dictionary:
	var node_path: String = req.get("path", "")
	var operation: String = req.get("operation", "")  # position, rotation, scale, z_index
	var value: Variant = req.get("value")
	
	var node: Node = NodeUtils.get_node_safe(node_path)
	if node == null:
		return CLIResponse.error("NODE_NOT_FOUND", "节点不存在")
	
	var canvas_item: CanvasItem = node as CanvasItem
	if canvas_item == null:
		return CLIResponse.error("NOT_2D_NODE", "不是2D节点")
	
	match operation:
		"position":
			if value is Array and value.size() >= 2:
				canvas_item.position = Vector2(float(value[0]), float(value[1]))
			elif value is Dictionary:
				canvas_item.position = VariantUtils.from_json_value(value, Vector2.ZERO)
		
		"rotation":
			var deg = float(value) if value is float else 0.0
			canvas_item.rotation_degrees = deg
		
		"scale":
			if value is Array and value.size() >= 2:
				canvas_item.scale = Vector2(float(value[0]), float(value[1]))
			elif value is Dictionary:
				canvas_item.scale = VariantUtils.from_json_value(value, Vector2.ONE)
		
		"z_index":
			canvas_item.z_index = int(value)
		
		"visible":
			canvas_item.visible = bool(value)
		
		"modulate":
			canvas_item.modulate = VariantUtils.from_json_value(value, Color.WHITE)
	
	return CLIResponse.success({
		"path": node_path,
		"operation": operation,
		"value": VariantUtils.to_json_value(_get_transform_value(canvas_item, operation))
	})

static func _get_transform_value(node: CanvasItem, op: String) -> Variant:
	match op:
		"position": return node.position
		"rotation": return node.rotation_degrees
		"scale": return node.scale
		"z_index": return node.z_index
		"visible": return node.visible
		"modulate": return node.modulate
	return null

# === 创建灯光 ===
static func create_light(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var light_type: String = req.get("type", "Light2D")  # Light2D, DirectionalLight2D
	var name: String = req.get("name", light_type)
	var color: Color = Color.WHITE
	var energy: float = 1.0
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var light: Node
	if light_type == "DirectionalLight2D":
		light = DirectionalLight2D.new()
	else:
		light = Light2D.new()
	
	light.name = name
	
	if req.has("color"):
		color = VariantUtils.from_json_value(req["color"], Color.WHITE)
	light.light_color = color
	
	if req.has("energy"):
		light.light_energy = float(req["energy"])
	
	parent.add_child(light)
	
	return CLIResponse.success({
		"path": light.get_path(),
		"name": name,
		"type": light_type
	})
