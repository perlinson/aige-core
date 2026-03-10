## Physics Commands - P1 物理系统 (2D)
class_name PhysicsCommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")
const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")

# === 创建物理刚体 ===
static func create_body(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var body_type: String = req.get("type", "RigidBody2D")  # RigidBody2D, StaticBody2D, Area2D, CharacterBody2D
	var name: String = req.get("name", body_type)
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("", "父节点PARENT_NOT_FOUND不存在")
	
	var body: Node
	match body_type:
		"RigidBody2D":
			body = RigidBody2D.new()
		"StaticBody2D":
			body = StaticBody2D.new()
		"Area2D":
			body = Area2D.new()
		"CharacterBody2D":
			body = CharacterBody2D.new()
		_:
			return CLIResponse.error("INVALID_TYPE", "无效物理类型: " + body_type)
	
	body.name = name
	parent.add_child(body)
	
	return CLIResponse.success({
		"path": body.get_path(),
		"name": name,
		"type": body_type
	})

# === 添加碰撞形状 ===
static func add_shape(req: Dictionary) -> Dictionary:
	var body_path: String = req.get("body", "")
	var shape_type: String = req.get("shape", "RectangleShape2D")  # RectangleShape2D, CircleShape2D, CapsuleShape2D, PolygonShape2D
	var params: Dictionary = req.get("params", {})
	
	var body: Node = NodeUtils.get_node_safe(body_path)
	if body == null:
		return CLIResponse.error("BODY_NOT_FOUND", "物理体不存在")
	
	# 查找或创建 CollisionShape2D
	var shape_node: CollisionShape2D = null
	for child in body.get_children():
		if child is CollisionShape2D:
			shape_node = child
			break
	
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		body.add_child(shape_node)
	
	# 创建形状
	var shape: Shape2D
	match shape_type:
		"RectangleShape2D":
			shape = RectangleShape2D.new()
			if params.has("size"):
				shape.size = VariantUtils.from_json_value(params["size"], Vector2(32, 32))
			else:
				shape.size = Vector2(32, 32)
		"CircleShape2D":
			shape = CircleShape2D.new()
			if params.has("radius"):
				shape.radius = float(params["radius"])
			else:
				shape.radius = 16
		"CapsuleShape2D":
			shape = CapsuleShape2D.new()
			if params.has("radius"):
				shape.radius = float(params.get("radius", 16))
			if params.has("height"):
				shape.height = float(params.get("height", 48))
		"PolygonShape2D":
			shape = PolygonShape2D.new()
			if params.has("points"):
				var points: PackedVector2Array = []
				for p in params["points"]:
					points.append(VariantUtils.from_json_value(p, Vector2.ZERO))
				shape.points = points
	
	shape_node.shape = shape
	
	return CLIResponse.success({
		"body": body_path,
		"shape_type": shape_type,
		"shape_path": shape_node.get_path()
	})

# === 设置碰撞层/掩码 ===
static func set_collision_layer(req: Dictionary) -> Dictionary:
	var body_path: String = req.get("body", "")
	var layer: int = req.get("layer", 1)
	var mask: int = req.get("mask", 1)
	
	var body: CollisionObject2D = NodeUtils.get_node_safe(body_path) as CollisionObject2D
	if body == null:
		return CLIResponse.error("INVALID_BODY", "不是有效的碰撞体")
	
	body.collision_layer = layer
	body.collision_mask = mask
	
	return CLIResponse.success({
		"body": body_path,
		"layer": layer,
		"mask": mask
	})

# === 射线检测 (2D) ===
static func raycast_2d(req: Dictionary) -> Dictionary:
	var origin: Vector2 = VariantUtils.from_json_value(req.get("origin", [0, 0]), Vector2.ZERO)
	var end: Vector2 = VariantUtils.from_json_value(req.get("end", [100, 100]), Vector2.ZERO)
	var collision_mask: int = req.get("mask", 0xFFFFFFFF)
	
	var space_state = PhysicsServer2D.space_get_direct_state(PhysicsServer2D.area_space_get_world_2d(PhysicsServer2D.area_create()))
	
	if space_state == null:
		return CLIResponse.error("PHYSICS_UNAVAILABLE", "物理世界不可用")
	
	var query = PhysicsRayQueryParameters2D.create(origin, end)
	query.collision_mask = collision_mask
	
	var result = space_state.intersect_ray(query)
	
	if result:
		return CLIResponse.success({
			"collided": true,
			"position": VariantUtils.to_json_value(result.position),
			"normal": VariantUtils.to_json_value(result.normal),
			"collider": result.collider.get_path() if result.collider else "",
			"collider_id": result.collider_id
		})
	else:
		return CLIResponse.success({
			"collided": false
		})

# === 区域检测 ===
static func get_overlapping_bodies(req: Dictionary) -> Dictionary:
	var area_path: String = req.get("area", "")
	
	var area: Area2D = NodeUtils.get_node_safe(area_path) as Area2D
	if area == null:
		return CLIResponse.error("INVALID_AREA", "不是有效的Area2D")
	
	var bodies: Array = []
	for body in area.get_overlapping_bodies():
		bodies.append({
			"path": body.get_path(),
			"name": body.name,
			"type": body.get_class()
		})
	
	return CLIResponse.success({
		"bodies": bodies,
		"count": bodies.size()
	})

# === 物理参数设置 ===
static func set_physics_param(req: Dictionary) -> Dictionary:
	var body_path: String = req.get("body", "")
	var param: String = req.get("param", "")
	var value: Variant = req.get("value")
	
	var body: Node = NodeUtils.get_node_safe(body_path)
	if body == null:
		return CLIResponse.error("BODY_NOT_FOUND", "物理体不存在")
	
	match param:
		"mass":
			if body is RigidBody2D:
				(body as RigidBody2D).mass = float(value)
		"gravity_scale":
			if body is RigidBody2D:
				(body as RigidBody2D).gravity_scale = float(value)
		"linear_damp":
			if body is RigidBody2D:
				(body as RigidBody2D).linear_damp = float(value)
		"angular_damp":
			if body is RigidBody2D:
				(body as RigidBody2D).angular_damp = float(value)
		"locked":
			if body is RigidBody2D:
				(body as RigidBody2D).locked = bool(value)
	
	return CLIResponse.success({
		"body": body_path,
		"param": param,
		"value": value
	})

# === 应用力 ===
static func apply_force(req: Dictionary) -> Dictionary:
	var body_path: String = req.get("body", "")
	var force: Vector2 = VariantUtils.from_json_value(req.get("force", [0, 0]), Vector2.ZERO)
	var position: Vector2 = VariantUtils.from_json_value(req.get("position", [0, 0]), Vector2.ZERO)
	var as_impulse: bool = req.get("impulse", false)
	
	var body: RigidBody2D = NodeUtils.get_node_safe(body_path) as RigidBody2D
	if body == null:
		return CLIResponse.error("INVALID_BODY", "不是有效的RigidBody2D")
	
	if position == Vector2.ZERO:
		if as_impulse:
			body.apply_central_impulse(force)
		else:
			body.apply_central_force(force)
	else:
		if as_impulse:
			body.apply_impulse(force, position)
		else:
			body.apply_force(force, position)
	
	return CLIResponse.success({
		"body": body_path,
		"force": VariantUtils.to_json_value(force),
		"as_impulse": as_impulse
	})
