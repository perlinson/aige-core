## Navigation Commands - P1 导航系统 (2D)
class_name NavCommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")
const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")

# === 创建导航区域 ===
static func create_region(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "NavigationRegion2D")
	var mode: String = req.get("mode", "2d")  # 2d or 3d
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	if mode == "2d":
		var region = NavigationRegion2D.new()
		region.name = name
		parent.add_child(region)
		return CLIResponse.success({
			"path": region.get_path(),
			"name": name,
			"type": "NavigationRegion2D"
		})
	else:
		return CLIResponse.error("INVALID_MODE", "仅支持2D导航")

# === 烘焙导航网格 ===
static func bake(req: Dictionary) -> Dictionary:
	var region_path: String = req.get("region", "")
	
	var region: NavigationRegion2D = NodeUtils.get_node_safe(region_path) as NavigationRegion2D
	if region == null:
		return CLIResponse.error("INVALID_REGION", "不是有效的NavigationRegion2D")
	
	region.bake_navigation_polygon(true)
	
	return CLIResponse.success({
		"region": region_path,
		"baked": true
	})

# === 获取导航路径 ===
static func get_path(req: Dictionary) -> Dictionary:
	var region_path: String = req.get("region", "")
	var start: Vector2 = VariantUtils.from_json_value(req.get("start", [0, 0]), Vector2.ZERO)
	var end: Vector2 = VariantUtils.from_json_value(req.get("end", [100, 100]), Vector2.ZERO)
	var optimize: bool = req.get("optimize", true)
	
	var region: NavigationRegion2D = NodeUtils.get_node_safe(region_path) as NavigationRegion2D
	if region == null:
		return CLIResponse.error("INVALID_REGION", "不是有效的NavigationRegion2D")
	
	var nav_poly = region.get_navigation_polygon()
	if nav_poly == null:
		return CLIResponse.error("NOT_BAKED", "导航网格未烘焙")
	
	var path = NavigationServer2D.map_get_path(region.get_world_2d().get_map(), start, end, optimize)
	
	var path_array: Array = []
	for point in path:
		path_array.append(VariantUtils.to_json_value(point))
	
	return CLIResponse.success({
		"path": path_array,
		"points": path.size(),
		"start": VariantUtils.to_json_value(start),
		"end": VariantUtils.to_json_value(end)
	})

# === 创建导航代理 (NavigationAgent2D) ===
static func create_agent(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "NavigationAgent2D")
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var agent = NavigationAgent2D.new()
	agent.name = name
	parent.add_child(agent)
	
	return CLIResponse.success({
		"path": agent.get_path(),
		"name": name,
		"type": "NavigationAgent2D"
	})

# === 设置导航目标 ===
static func set_target(req: Dictionary) -> Dictionary:
	var agent_path: String = req.get("agent", "")
	var target: Vector2 = VariantUtils.from_json_value(req.get("target", [0, 0]), Vector2.ZERO)
	
	var agent: NavigationAgent2D = NodeUtils.get_node_safe(agent_path) as NavigationAgent2D
	if agent == null:
		return CLIResponse.error("INVALID_AGENT", "不是有效的NavigationAgent2D")
	
	agent.target_position = target
	
	return CLIResponse.success({
		"agent": agent_path,
		"target": VariantUtils.to_json_value(target)
	})

# === 获取下一位置 ===
static func get_next_position(req: Dictionary) -> Dictionary:
	var agent_path: String = req.get("agent", "")
	
	var agent: NavigationAgent2D = NodeUtils.get_node_safe(agent_path) as NavigationAgent2D
	if agent == null:
		return CLIResponse.error("INVALID_AGENT", "不是有效的NavigationAgent2D")
	
	var next_pos = agent.get_next_path_position()
	var distance_to = agent.distance_to_target()
	var is_finished = agent.is_navigation_finished()
	
	return CLIResponse.success({
		"agent": agent_path,
		"next_position": VariantUtils.to_json_value(next_pos),
		"distance_to_target": distance_to,
		"is_finished": is_finished
	})

# === 导航链接 (NavigationLink2D) ===
static func create_link(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "NavigationLink2D")
	var start: Vector2 = VariantUtils.from_json_value(req.get("start", [0, 0]), Vector2.ZERO)
	var end: Vector2 = VariantUtils.from_json_value(req.get("end", [100, 100]), Vector2.ZERO)
	var two_way: bool = req.get("two_way", true)
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var link = NavigationLink2D.new()
	link.name = name
	link.start_position = start
	link.end_position = end
	link.two_way = two_way
	parent.add_child(link)
	
	return CLIResponse.success({
		"path": link.get_path(),
		"name": name,
		"start": VariantUtils.to_json_value(start),
		"end": VariantUtils.to_json_value(end)
	})
