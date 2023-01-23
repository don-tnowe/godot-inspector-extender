extends Control

var object : Object
var attached_prop : Control
var expression : Expression


func _initialize(object, property, attribute_name, params, inspector_plugin):
	self.object = object
	expression = Expression.new()
	expression.parse(params[0])


func _ready():
	var cur_index := get_index() - 1
	while !get_parent().get_child(cur_index) is EditorProperty:
		cur_index -= 1

	attached_prop = get_parent().get_child(cur_index)
	hide()


func _update_view():
	var shown = expression.execute([], object)
	await get_tree().process_frame
	attached_prop.visible = shown


func _hides_property(): return false
