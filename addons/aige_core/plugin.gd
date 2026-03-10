## AIGE-Core Plugin
## AI Godot Engine - Core CLI Interface
@tool
extends EditorPlugin

var _cli_server: CLIServer

func _enter_tree() -> void:
	# 创建CLI服务器
	_cli_server = CLIServer.new()
	_cli_server.name = "AIGE-Core"
	add_child(_cli_server)
	
	print("[AIGE-Core] Plugin loaded - AI CLI Server ready on port 8765")

func _exit_tree() -> void:
	if _cli_server:
		_cli_server.stop_server()
		_cli_server.free()
	print("[AIGE-Core] Plugin unloaded")

func _has_main_screen() -> bool:
	return false

func _get_plugin_name() -> String:
	return "AIGE-Core"

func _get_plugin_icon() -> Texture2D:
	return load("res://addons/aige_core/icon.svg")
