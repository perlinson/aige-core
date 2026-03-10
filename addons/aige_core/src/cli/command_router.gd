## CLI Command Router
extends RefCounted
class_name CLIRouter

# 命令注册表
var commands: Dictionary = {}
var command_help: Dictionary = {}

func _init() -> void:
	_register_commands()

func _register_commands() -> void:
	# === P0: 场景节点管理 ===
	_register_command("node.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return await SceneCommands.create_node(req),
		"创建节点",
		"parent: 父节点路径, type: 节点类型, name: 节点名称"
	))
	
	_register_command("node.delete", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return await SceneCommands.delete_node(req),
		"删除节点",
		"path: 节点路径"
	))
	
	_register_command("node.list", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return SceneCommands.list_nodes(req),
		"列出节点",
		"root: 根路径, filter: 类型过滤"
	))
	
	_register_command("node.get", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return SceneCommands.get_property(req),
		"获取属性",
		"path: 节点路径, property: 属性名"
	))
	
	_register_command("node.set", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return SceneCommands.set_property(req),
		"设置属性",
		"path: 节点路径, property: 属性名, value: 属性值"
	))
	
	_register_command("node.reparent", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return SceneCommands.reparent_node(req),
		"移动节点",
		"path: 节点路径, new_parent: 新父节点路径"
	))
	
	_register_command("node.info", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return SceneCommands.get_node_info(req),
		"获取节点信息",
		"path: 节点路径"
	))
	
	# === P1: 2D 对象系统 ===
	_register_command("2d.sprite.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.create_sprite(req),
		"创建Sprite",
		"parent: 父节点, texture: 纹理路径"
	))
	
	_register_command("2d.camera.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.create_camera(req),
		"创建2D相机",
		"parent: 父节点"
	))
	
	_register_command("2d.tilemap.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.create_tilemap(req),
		"创建TileMap",
		"parent: 父节点, tileset: tileset路径"
	))
	
	_register_command("2d.transform", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.transform_2d(req),
		"2D变换操作",
		"path: 节点, operation: 操作类型, value: 值"
	))
	
	_register_command("2d.light.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.create_light(req),
		"创建灯光",
		"parent: 父节点, type: Light2D/DirectionalLight2D"
	))
	
	_register_command("2d.polygon.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.create_polygon(req),
		"创建多边形",
		"parent: 父节点, points: 顶点数组"
	))
	
	_register_command("2d.line.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return TwoDCommands.create_line(req),
		"创建线条",
		"parent: 父节点, points: 点数组"
	))
	
	# === P1: 物理系统 (2D) ===
	_register_command("physics.create-body", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return PhysicsCommands.create_body(req),
		"创建物理刚体",
		"parent: 父节点, type: RigidBody2D/StaticBody2D/Area2D"
	))
	
	_register_command("physics.add-shape", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return PhysicsCommands.add_shape(req),
		"添加碰撞形状",
		"body: 刚体路径, shape: 形状类型"
	))
	
	_register_command("physics.set-layer", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return PhysicsCommands.set_collision_layer(req),
		"设置碰撞层",
		"body: 刚体路径, layer: 层, mask: 掩码"
	))
	
	_register_command("physics.raycast-2d", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return PhysicsCommands.raycast_2d(req),
		"2D射线检测",
		"origin: 起点, end: 终点"
	))
	
	_register_command("physics.apply-force", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return PhysicsCommands.apply_force(req),
		"施加力",
		"body: 刚体路径, force: 力向量"
	))
	
	# === P1: UI 系统 ===
	_register_command("ui.container.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return UICommands.create_container(req),
		"创建容器",
		"parent: 父节点, type: 容器类型"
	))
	
	_register_command("ui.control.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return UICommands.create_control(req),
		"创建控件",
		"parent: 父节点, type: 控件类型"
	))
	
	_register_command("ui.control.set-prop", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return UICommands.set_control_prop(req),
		"设置控件属性",
		"path: 控件路径, property: 属性, value: 值"
	))
	
	_register_command("ui.container.add", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return UICommands.container_add(req),
		"添加子控件",
		"container: 容器路径, child: 子节点路径"
	))
	
	_register_command("ui.option.add-item", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return UICommands.option_add_item(req),
		"添加选项",
		"path: OptionButton路径, text: 文本"
	))
	
	# === P1: 音频系统 ===
	_register_command("audio.create-player", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AudioCommands.create_player_2d(req),
		"创建音频播放器",
		"parent: 父节点, stream: 音频路径"
	))
	
	_register_command("audio.play", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AudioCommands.play(req),
		"播放音频",
		"player: 播放器路径"
	))
	
	_register_command("audio.pause", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AudioCommands.pause(req),
		"暂停音频",
		"player: 播放器路径"
	))
	
	_register_command("audio.stop", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AudioCommands.stop(req),
		"停止音频",
		"player: 播放器路径"
	))
	
	_register_command("audio.set-volume", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AudioCommands.set_volume(req),
		"设置音量",
		"player: 播放器路径, volume: 分贝值"
	))
	
	_register_command("audio.list-buses", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AudioCommands.list_buses(req),
		"列出音频总线",
		""
	))
	
	# === P1: 导航系统 (2D) ===
	_register_command("nav.create-region", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return NavCommands.create_region(req),
		"创建导航区域",
		"parent: 父节点"
	))
	
	_register_command("nav.bake", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return NavCommands.bake(req),
		"烘焙导航网格",
		"region: 区域路径"
	))
	
	_register_command("nav.get-path", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return NavCommands.get_path(req),
		"获取导航路径",
		"region: 区域, start: 起点, end: 终点"
	))
	
	_register_command("nav.create-agent", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return NavCommands.create_agent(req),
		"创建导航代理",
		"parent: 父节点"
	))
	
	_register_command("nav.set-target", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return NavCommands.set_target(req),
		"设置导航目标",
		"agent: 代理路径, target: 目标位置"
	))
	
	# === P1: 输入系统 ===
	_register_command("input.list-actions", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return InputCommands.list_actions(req),
		"列出输入动作",
		""
	))
	
	_register_command("input.create-action", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return InputCommands.create_action(req),
		"创建输入动作",
		"action: 动作名称"
	))
	
	_register_command("input.add-event", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return InputCommands.add_event(req),
		"添加输入事件",
		"action: 动作, type: 事件类型, params: 事件参数"
	))
	
	_register_command("input.simulate", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return InputCommands.simulate_action(req),
		"模拟输入",
		"action: 动作, pressed: 按下/释放"
	))
	
	_register_command("input.get-vector", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return InputCommands.get_vector(req),
		"获取向量输入",
		"negative: 负向动作, positive: 正向动作"
	))
	
	# === P1: 脚本系统 ===
	_register_command("script.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ScriptCommands.create_script(req),
		"创建脚本",
		"path: 脚本路径, language: 语言, extends: 父类"
	))
	
	_register_command("script.attach", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ScriptCommands.attach_script(req),
		"附加脚本",
		"node: 节点路径, script: 脚本路径"
	))
	
	_register_command("script.detach", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ScriptCommands.detach_script(req),
		"分离脚本",
		"node: 节点路径"
	))
	
	_register_command("script.get-code", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ScriptCommands.get_code(req),
		"获取脚本代码",
		"path: 脚本路径"
	))
	
	_register_command("script.set-code", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ScriptCommands.set_code(req),
		"设置脚本代码",
		"path: 脚本路径, code: 代码"
	))
	
	_register_command("script.validate", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ScriptCommands.validate_script(req),
		"验证脚本",
		"path: 脚本路径"
	))
	
	# === P1: 项目设置 ===
	_register_command("project.get", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ProjectCommands.get_setting(req),
		"获取项目设置",
		"key: 设置键"
	))
	
	_register_command("project.set", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ProjectCommands.set_setting(req),
		"设置项目设置",
		"key: 设置键, value: 值"
	))
	
	_register_command("project.set-display", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ProjectCommands.set_display_mode(req),
		"设置显示模式",
		"width: 宽, height: 高, mode: 模式"
	))
	
	_register_command("project.set-renderer", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ProjectCommands.set_renderer(req),
		"设置渲染器",
		"renderer: 渲染器名称"
	))
	
	_register_command("project.set-main-scene", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ProjectCommands.set_main_scene(req),
		"设置主场景",
		"scene: 场景路径"
	))
	
	_register_command("project.info", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ProjectCommands.get_project_info(req),
		"获取项目信息",
		""
	))
	
	# === P1: 构建导出 ===
	_register_command("build.list-platforms", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return BuildCommands.list_platforms(req),
		"列出导出平台",
		""
	))
	
	_register_command("build.export", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return BuildCommands.export_project(req),
		"导出项目",
		"platform: 平台, output: 输出路径"
	))
	
	_register_command("build.clean", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return BuildCommands.clean(req),
		"清理构建",
		""
	))
	
	_register_command("node.info", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return SceneCommands.get_node_info(req),
		"获取节点信息",
		"path: 节点路径"
	))
	
	# === P0: 动画系统 ===
	_register_command("anim.create", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return await AnimCommands.create_animation(req),
		"创建动画",
		"scene: 场景路径, name: 动画名称"
	))
	
	_register_command("anim.list", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AnimCommands.list_animations(req),
		"列出动画",
		"scene: 场景路径"
	))
	
	_register_command("anim.add-track", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AnimCommands.add_track(req),
		"添加轨道",
		"scene: 场景, anim: 动画名, node_path: 节点路径, property: 属性"
	))
	
	_register_command("anim.add-key", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AnimCommands.add_keyframe(req),
		"添加关键帧",
		"scene: 场景, anim: 动画名, track_index: 轨道索引, time: 时间, value: 值"
	))
	
	_register_command("anim.play", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return AnimCommands.play_animation(req),
		"播放动画",
		"scene: 场景路径, name: 动画名称, speed: 播放速度"
	))
	
	# === P0: 资源系统 ===
	_register_command("resource.load", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ResourceCommands.load_resource(req),
		"加载资源",
		"path: 资源路径"
	))
	
	_register_command("resource.save", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ResourceCommands.save_resource(req),
		"保存资源",
		"path: 资源路径, save_path: 保存路径"
	))
	
	_register_command("resource.type", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return ResourceCommands.get_resource_type(req),
		"获取资源类型",
		"path: 资源路径"
	))
	
	# === P0: 日志系统 ===
	_register_command("log.query", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return LogCommands.query_logs(req),
		"查询日志",
		"level: 日志级别, lines: 行数"
	))
	
	_register_command("log.stats", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return LogCommands.get_stats(req),
		"日志统计",
		""
	))
	
	_register_command("log.write", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return LogCommands.write_log(req),
		"写入日志",
		"message: 消息, level: 级别"
	))
	
	# === P0: 调试系统 ===
	_register_command("debug.breakpoint.add", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return DebugCommands.add_breakpoint(req),
		"添加断点",
		"script: 脚本路径, line: 行号"
	))
	
	_register_command("debug.breakpoint.remove", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return DebugCommands.remove_breakpoint(req),
		"删除断点",
		"script: 脚本路径, line: 行号"
	))
	
	_register_command("debug.breakpoint.list", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return DebugCommands.list_breakpoints(req),
		"列出断点",
		""
	))
	
	_register_command("debug.stacktrace", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return DebugCommands.get_stacktrace(req),
		"获取堆栈",
		""
	))
	
	# === P0: 编辑器操作 ===
	_register_command("editor.get-selection", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return EditorCommands.get_selection(req),
		"获取选择",
		""
	))
	
	_register_command("editor.save-scene", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return await EditorCommands.save_scene(req),
		"保存场景",
		"path: 场景路径"
	))
	
	_register_command("editor.open-scenes", CLICommand.new(
		func(req: Dictionary) -> Dictionary:
			return EditorCommands.get_open_scenes(req),
		"获取打开的场景",
		""
	))

func _register_command(name: String, cmd: CLICommand) -> void:
	commands[name] = cmd
	command_help[name] = cmd.description

func execute(command: String, params: Dictionary) -> Dictionary:
	if commands.has(command):
		var cmd: CLICommand = commands[command]
		var result = cmd.execute(params)
		if result is Callable:
			return await result.call(params)
		return result
	else:
		return CLIResponse.error("UNKNOWN_COMMAND", "未知命令: " + command)

func get_help(command: String = "") -> Dictionary:
	if command.is_empty():
		return CLIResponse.success({
			"commands": command_help.keys(),
			"hint": "使用 /api/help?command=xxx 查看具体帮助"
		})
	if command_help.has(command):
		return CLIResponse.success({
			"command": command,
			"description": command_help[command].description,
			"usage": command_help[command].usage
		})
	return CLIResponse.error("HELP_NOT_FOUND", "命令不存在")
