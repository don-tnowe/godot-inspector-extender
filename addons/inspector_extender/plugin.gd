@tool
extends EditorPlugin

var plugin = load("res://addons/inspector_extender/inspector_plugin.gd").new(self)


func _enter_tree():
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_inspector_plugin(plugin)
