## Anim Commands - P0 动画系统
class_name AnimCommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")

# === 创建动画 ===
static func create_animation(req: Dictionary) -> Dictionary:
	var scene_path: String = req.get("scene", "")
	var anim_name: String = req.get("name", "")
	var library: String = req.get("library", "")
	
	if anim_name.is_empty():
		return CLIResponse.error("INVALID_NAME", "动画名称不能为空")
	
	# 获取场景
	var scene: Node = _get_scene_root(scene_path)
	if scene == null:
		return CLIResponse.error("SCENE_NOT_FOUND", "场景未找到: " + scene_path)
	
	# 查找AnimationPlayer
	var anim_player: AnimationPlayer = _find_animation_player(scene)
	if anim_player == null:
		# 自动创建一个
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		scene.add_child(anim_player)
	
	# 检查动画是否已存在
	if anim_player.has_animation(anim_name):
		return CLIResponse.error("ANIM_EXISTS", "动画已存在: " + anim_name)
	
	# 创建新动画
	var anim: Animation = Animation.new()
	anim.length = 1.0  # 默认1秒
	
	# 添加到动画库
	if library.is_empty():
		library = ""
	
	if not anim_player.has_animation_library(library):
		anim_player.add_animation_library(library, AnimationLibrary.new())
	
	anim_player.add_animation(anim_name, anim)
	
	return CLIResponse.success({
		"scene": scene_path,
		"animation": anim_name,
		"library": library,
		"length": anim.length
	}, "动画创建成功")

# === 列出动画 ===
static func list_animations(req: Dictionary) -> Dictionary:
	var scene_path: String = req.get("scene", "")
	
	var scene: Node = _get_scene_root(scene_path)
	if scene == null:
		return CLIResponse.error("SCENE_NOT_FOUND", "场景未找到")
	
	var anim_player: AnimationPlayer = _find_animation_player(scene)
	if anim_player == null:
		return CLIResponse.success({"animations": []})
	
	var animations: Array = []
	for name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(name)
		animations.append({
			"name": name,
			"length": anim.length,
			"loop": anim.loop_mode != Animation.LOOP_DISABLED,
			"track_count": anim.get_track_count()
		})
	
	return CLIResponse.success({"animations": animations})

# === 添加轨道 ===
static func add_track(req: Dictionary) -> Dictionary:
	var scene_path: String = req.get("scene", "")
	var anim_name: String = req.get("anim", "")
	var node_path: String = req.get("node_path", "")
	var property: String = req.get("property", "")
	var track_type: int = req.get("track_type", Animation.TYPE_VALUE)
	
	var scene: Node = _get_scene_root(scene_path)
	if scene == null:
		return CLIResponse.error("SCENE_NOT_FOUND", "场景未找到")
	
	var anim_player: AnimationPlayer = _find_animation_player(scene)
	if anim_player == null or not anim_player.has_animation(anim_name):
		return CLIResponse.error("ANIM_NOT_FOUND", "动画未找到")
	
	var anim: Animation = anim_player.get_animation(anim_name)
	var track_idx: int = anim.add_track(track_type)
	
	# 设置轨道路径
	var full_path = node_path
	if not property.is_empty():
		full_path = node_path + ":" + property
	
	anim.track_set_path(track_idx, full_path)
	
	return CLIResponse.success({
		"scene": scene_path,
		"animation": anim_name,
		"track_index": track_idx,
		"track_path": full_path,
		"track_type": Animation.get_track_type_name(track_type)
	})

# === 添加关键帧 ===
static func add_keyframe(req: Dictionary) -> Dictionary:
	var scene_path: String = req.get("scene", "")
	var anim_name: String = req.get("anim", "")
	var track_index: int = req.get("track_index", 0)
	var time: float = req.get("time", 0.0)
	var value: Variant = req.get("value")
	var transition: float = req.get("transition", 0.5)
	
	var scene: Node = _get_scene_root(scene_path)
	if scene == null:
		return CLIResponse.error("SCENE_NOT_FOUND", "场景未找到")
	
	var anim_player: AnimationPlayer = _find_animation_player(scene)
	if anim_player == null or not anim_player.has_animation(anim_name):
		return CLIResponse.error("ANIM_NOT_FOUND", "动画未找到")
	
	var anim: Animation = anim_player.get_animation(anim_name)
	
	if track_index >= anim.get_track_count():
		return CLIResponse.error("TRACK_NOT_FOUND", "轨道不存在")
	
	# 类型转换
	var converted_value = VariantUtils.from_json_value(value)
	
	# 添加关键帧
	anim.track_insert_key(track_index, time, converted_value, transition)
	
	return CLIResponse.success({
		"scene": scene_path,
		"animation": anim_name,
		"track_index": track_index,
		"time": time,
		"value": VariantUtils.to_json_value(converted_value)
	})

# === 播放动画 ===
static func play_animation(req: Dictionary) -> Dictionary:
	var scene_path: String = req.get("scene", "")
	var name: String = req.get("name", "")
	var speed: float = req.get("speed", 1.0)
	var from_time: float = req.get("from", -1.0)
	
	var scene: Node = _get_scene_root(scene_path)
	if scene == null:
		return CLIResponse.error("SCENE_NOT_FOUND", "场景未找到")
	
	var anim_player: AnimationPlayer = _find_animation_player(scene)
	if anim_player == null:
		return CLIResponse.error("PLAYER_NOT_FOUND", "未找到AnimationPlayer")
	
	if not name.is_empty():
		anim_player.play(name)
		if speed != 1.0:
			anim_player.speed_scale = speed
		if from_time >= 0:
			anim_player.seek(from_time)
	
	return CLIResponse.success({
		"playing": name,
		"speed": speed,
		"current_time": anim_player.current_animation_position
	})

# === 辅助函数 ===
static func _get_scene_root(path: String) -> Node:
	if path.is_empty():
		return Engine.get_main_loop()?.root?.get_child(0)
	
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.root.get_node(path)
	return null

static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null
