## CLI Server - HTTP服务器接收AI Agent命令
class_name CLIServer
extends Node

## Godot AI CLI Server
## 嵌入式HTTP服务器，通过CLI控制Godot引擎

@export var port: int = 8765
@export var auto_start: bool = false

var _http_server: HTTPServer
var _router: CLIRouter
var _running: bool = false

signal server_started(port: int)
signal server_stopped()
signal command_received(command: String, params: Dictionary)

func _ready() -> void:
	_init_router()
	
	if auto_start:
		start_server()

func _init_router() -> void:
	_router = CLIRouter.new()

## 启动服务器
func start_server(port_override: int = -1) -> Dictionary:
	if port_override > 0:
		port = port_override
	
	if _running:
		return {"success": false, "error": "Server already running"}
	
	# 创建HTTP服务器
	_http_server = HTTPServer.new()
	
	# 绑定路由
	_http_server.bind_completion(_http_request_completion)
	
	var err = _http_server.listen(port)
	
	if err != OK:
		return {"success": false, "error": "Failed to listen on port " + str(port)}
	
	_running = true
	server_started.emit(port)
	
	print("[CLI Server] Started on port ", port)
	
	return {"success": true, "port": port}

## 停止服务器
func stop_server() -> void:
	if _http_server:
		_http_server.stop()
	_running = false
	server_stopped.emit()
	print("[CLI Server] Stopped")

## 获取服务器状态
func is_running() -> bool:
	return _running

# === HTTP请求处理 ===
func _http_request_completion(request: HTTPRequestResult) -> void:
	var method = request.method
	var path = request.path
	var body = request.body
	
	# 解析路径和查询参数
	var path_parts = path.split("?", false, 1)
	var endpoint = path_parts[0].trim_prefix("/api/")
	var query_params = {}
	
	if path_parts.size() > 1:
		for param in path_parts[1].split("&"):
			var kv = param.split("=", false, 1)
			if kv.size() == 2:
				query_params[kv[0]] = kv[1]
	
	# 解析JSON body
	var json_body = {}
	if body.size() > 0:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			json_body = json.data if json.data is Dictionary else {}
	
	# 合并参数 (query + body)
	var params = query_params.duplicate()
	params.merge(json_body)
	
	# 处理请求
	var response = _handle_request(endpoint, params, method)
	
	# 发送响应
	_send_json_response(request, response)

func _handle_request(endpoint: String, params: Dictionary, method: String) -> Dictionary:
	command_received.emit(endpoint, params)
	
	# 路由命令
	match endpoint:
		"help":
			return _router.get_help(params.get("command", ""))
		
		"start-server":
			return start_server()
		
		"stop-server":
			stop_server()
			return {"success": true, "message": "Server stopped"}
		
		"status":
			return {
				"success": true,
				"running": _running,
				"port": port,
				"version": "1.0.0"
			}
	
	# 解析命令 (支持 /api/node.create 或 /api/node/create )
	var command = endpoint.replace(".", "/")
	
	# 执行命令
	return _router.execute(command, params)

func _send_json_response(request: HTTPRequestResult, response: Dictionary) -> void:
	var json = JSON.new()
	var json_string = json.stringify(response)
	
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"Access-Control-Allow-Origin: *"
	])
	
	request.request_completed.emit(200, headers, json_string.to_utf8_buffer())

# === 便捷方法 ===
func execute_command(command: String, params: Dictionary = {}) -> Dictionary:
	return _router.execute(command, params)

func get_available_commands() -> Array:
	return _router.command_help.keys()
