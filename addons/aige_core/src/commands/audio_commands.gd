## Audio Commands - P1 音频系统
class_name AudioCommands
extends RefCounted

const VariantUtils = preload("res://addons/godot-agent-cli/src/utils/variant_utils.gd")
const NodeUtils = preload("res://addons/godot-agent-cli/src/utils/node_utils.gd")

# === 创建音频播放器 (2D) ===
static func create_player_2d(req: Dictionary) -> Dictionary:
	var parent_path: String = req.get("parent", "/root")
	var name: String = req.get("name", "AudioStreamPlayer2D")
	var stream_path: String = req.get("stream", "")
	
	var parent: Node = NodeUtils.get_node_safe(parent_path)
	if parent == null:
		return CLIResponse.error("PARENT_NOT_FOUND", "父节点不存在")
	
	var player = AudioStreamPlayer2D.new()
	player.name = name
	
	if not stream_path.is_empty():
		var stream = load(stream_path)
		if stream:
			player.stream = stream
	
	parent.add_child(player)
	
	return CLIResponse.success({
		"path": player.get_path(),
		"name": name,
		"type": "AudioStreamPlayer2D"
	})

# === 创建音频播放器 (3D - 仅为兼容) ===
static func create_player_3d(req: Dictionary) -> Dictionary:
	# 3D音频在2D游戏中通常不需要
	return create_player_2d(req)

# === 播放控制 ===
static func play(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	var from_position: float = req.get("from", 0.0)
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	if from_position > 0:
		player.play(from_position)
	else:
		player.play()
	
	return CLIResponse.success({
		"playing": true,
		"player": player_path,
		"position": player.get_playback_position()
	})

# === 暂停 ===
static func pause(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	player.stream_paused = true
	
	return CLIResponse.success({
		"paused": true,
		"player": player_path
	})

# === 停止 ===
static func stop(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	player.stop()
	
	return CLIResponse.success({
		"stopped": true,
		"player": player_path
	})

# === 设置音量 ===
static func set_volume(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	var volume_db: float = req.get("volume", 0.0)  # 分贝
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	player.volume_db = volume_db
	
	return CLIResponse.success({
		"player": player_path,
		"volume_db": volume_db
	})

# === 设置音调 ===
static func set_pitch(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	var pitch: float = req.get("pitch", 1.0)
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	player.pitch_scale = pitch
	
	return CLIResponse.success({
		"player": player_path,
		"pitch_scale": pitch
	})

# === 设置循环 ===
static func set_loop(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	var loop: bool = req.get("loop", false)
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	if player.stream is AudioStreamWAV:
		(player.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_ENABLED if loop else AudioStreamWAV.LOOP_DISABLED
	
	return CLIResponse.success({
		"player": player_path,
		"loop": loop
	})

# === 设置音频总线 ===
static func set_bus(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	var bus_name: String = req.get("bus", "Master")
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return CLIResponse.error("INVALID_BUS", "音频总线不存在: " + bus_name)
	
	player.bus = bus_name
	
	return CLIResponse.success({
		"player": player_path,
		"bus": bus_name
	})

# === 获取播放状态 ===
static func get_status(req: Dictionary) -> Dictionary:
	var player_path: String = req.get("player", "")
	
	var player: AudioStreamPlayer = NodeUtils.get_node_safe(player_path) as AudioStreamPlayer
	if player == null:
		return CLIResponse.error("INVALID_PLAYER", "不是有效的音频播放器")
	
	return CLIResponse.success({
		"playing": player.playing,
		"paused": player.stream_paused,
		"position": player.get_playback_position(),
		"volume_db": player.volume_db,
		"pitch_scale": player.pitch_scale,
		"bus": player.bus
	})

# === 列出音频总线 ===
static func list_buses(_req: Dictionary) -> Dictionary:
	var buses: Array = []
	var bus_count = AudioServer.get_bus_count()
	
	for i in range(bus_count):
		buses.append({
			"index": i,
			"name": AudioServer.get_bus_name(i),
			"volume_db": AudioServer.get_bus_volume_db(i),
			"send": AudioServer.get_bus_send(i)
		})
	
	return CLIResponse.success({
		"buses": buses,
		"count": bus_count
	})

# === 音频总线设置 ===
static func set_bus_volume(req: Dictionary) -> Dictionary:
	var bus_name: String = req.get("bus", "Master")
	var volume_db: float = req.get("volume", 0.0)
	
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return CLIResponse.error("INVALID_BUS", "音频总线不存在")
	
	AudioServer.set_bus_volume_db(bus_idx, volume_db)
	
	return CLIResponse.success({
		"bus": bus_name,
		"volume_db": volume_db
	})
