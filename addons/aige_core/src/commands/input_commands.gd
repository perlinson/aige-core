## Input Commands - P1 输入系统
class_name InputCommands
extends RefCounted

# === 列出所有输入动作 ===
static func list_actions(_req: Dictionary) -> Dictionary:
	var actions: Array = InputMap.get_actions()
	var result: Array = []
	
	for action in actions:
		var events: Array = InputMap.action_get_events(action)
		var event_list: Array = []
		for event in events:
			event_list.append(_event_to_string(event))
		
		result.append({
			"action": action,
			"events": event_list,
			"deadzone": InputMap.action_get_deadzone(action)
		})
	
	return CLIResponse.success({
		"actions": result,
		"count": result.size()
	})

# === 创建输入动作 ===
static func create_action(req: Dictionary) -> Dictionary:
	var action_name: String = req.get("action", "")
	var deadzone: float = req.get("deadzone", 0.5)
	
	if action_name.is_empty():
		return CLIResponse.error("INVALID_ACTION", "动作名称不能为空")
	
	if InputMap.has_action(action_name):
		return CLIResponse.error("ACTION_EXISTS", "动作已存在: " + action_name)
	
	InputMap.add_action(action_name, deadzone)
	
	return CLIResponse.success({
		"action": action_name,
		"deadzone": deadzone
	})

# === 删除输入动作 ===
static func delete_action(req: Dictionary) -> Dictionary:
	var action_name: String = req.get("action", "")
	
	if not InputMap.has_action(action_name):
		return CLIResponse.error("ACTION_NOT_FOUND", "动作不存在: " + action_name)
	
	# 删除所有事件
	var events = InputMap.action_get_events(action_name)
	for event in events:
		InputMap.action_erase_event(action_name, event)
	
	# 删除动作
	InputMap.erase_action(action_name)
	
	return CLIResponse.success({
		"deleted": action_name
	})

# === 添加输入事件 ===
static func add_event(req: Dictionary) -> Dictionary:
	var action_name: String = req.get("action", "")
	var event_type: String = req.get("type", "key")
	var event_params: Dictionary = req.get("params", {})
	
	if not InputMap.has_action(action_name):
		return CLIResponse.error("ACTION_NOT_FOUND", "动作不存在")
	
	var event: InputEvent = _create_event(event_type, event_params)
	if event == null:
		return CLIResponse.error("INVALID_EVENT", "无法创建输入事件")
	
	InputMap.action_add_event(action_name, event)
	
	return CLIResponse.success({
		"action": action_name,
		"event": _event_to_string(event)
	})

# === 删除输入事件 ===
static func remove_event(req: Dictionary) -> Dictionary:
	var action_name: String = req.get("action", "")
	var event_type: String = req.get("type", "key")
	var event_params: Dictionary = req.get("params", {})
	
	if not InputMap.has_action(action_name):
		return CLIResponse.error("ACTION_NOT_FOUND", "动作不存在")
	
	var event: InputEvent = _create_event(event_type, event_params)
	if event == null:
		return CLIResponse.error("INVALID_EVENT", "无法创建输入事件")
	
	InputMap.action_erase_event(action_name, event)
	
	return CLIResponse.success({
		"action": action_name,
		"removed": true
	})

# === 获取动作状态 ===
static func is_action_pressed(req: Dictionary) -> Dictionary:
	var action_name: String = req.get("action", "")
	var just_pressed: bool = req.get("just_pressed", false)
	
	if not InputMap.has_action(action_name):
		return CLIResponse.error("ACTION_NOT_FOUND", "动作不存在")
	
	var pressed: bool
	if just_pressed:
		pressed = Input.is_action_just_pressed(action_name)
	else:
		pressed = Input.is_action_pressed(action_name)
	
	return CLIResponse.success({
		"action": action_name,
		"pressed": pressed
	})

# === 虚拟按键 (AI控制用) ===
static func simulate_action(req: Dictionary) -> Dictionary:
	var action_name: String = req.get("action", "")
	var pressed: bool = req.get("pressed", true)
	
	if not InputMap.has_action(action_name):
		return CLIResponse.error("ACTION_NOT_FOUND", "动作不存在")
	
	# 使用模拟输入
	Input.action_press(action_name) if pressed else Input.action_release(action_name)
	
	return CLIResponse.success({
		"action": action_name,
		"simulated": pressed
	})

# === 获取向量输入 ===
static func get_vector(req: Dictionary) -> Dictionary:
	var negative_action: String = req.get("negative", "ui_left")
	var positive_action: String = req.get("positive", "ui_right")
	
	var vector = Input.get_vector(negative_action, positive_action, "ui_up", "ui_down")
	
	return CLIResponse.success({
		"x": vector.x,
		"y": vector.y,
		"length": vector.length()
	})

# === 鼠标位置 ===
static func get_mouse_position(_req: Dictionary) -> Dictionary:
	var pos = Input.get_last_mouse_velocity()
	var screen_pos = Input.get_mouse_position()
	
	return CLIResponse.success({
		"velocity": {"x": pos.x, "y": pos.y},
		"screen": {"x": screen_pos.x, "y": screen_pos.y}
	})

# === 辅助函数 ===
static func _event_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event = event as InputEventKey
		return "key:" + str(key_event.keycode)
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		return "mouse_button:" + str(mouse_event.button_index)
	elif event is InputEventJoypadButton:
		var joy_event = event as InputEventJoypadButton
		return "joy_button:" + str(joy_event.button_index)
	elif event is InputEventJoypadMotion:
		var motion_event = event as InputEventJoypadMotion
		return "joy_motion:" + str(motion_event.axis)
	return "unknown"

static func _create_event(event_type: String, params: Dictionary) -> InputEvent:
	match event_type:
		"key":
			var event = InputEventKey.new()
			if params.has("keycode"):
				event.keycode = int(params.keycode)
			elif params.has("physical_keycode"):
				event.physical_keycode = int(params.physical_keycode)
			event.pressed = params.get("pressed", true)
			return event
		
		"mouse_button":
			var event = InputEventMouseButton.new()
			event.button_index = int(params.get("button_index", 1))
			event.pressed = params.get("pressed", true)
			return event
		
		"joy_button":
			var event = InputEventJoypadButton.new()
			event.button_index = int(params.get("button_index", 0))
			event.pressed = params.get("pressed", true)
			return event
		
		"joy_motion":
			var event = InputEventJoypadMotion.new()
			event.axis = int(params.get("axis", 0))
			event.axis_value = float(params.get("value", 0.0))
			return event
	
	return null
