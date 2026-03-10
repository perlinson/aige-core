## CLI Command
class_name CLICommand
extends RefCounted

var handler: Callable
var description: String
var usage: String

func _init(_handler: Callable, _desc: String, _usage: String = "") -> void:
	handler = _handler
	description = _desc
	usage = _usage

func execute(params: Dictionary) -> Variant:
	return handler.call(params)
