extends MarginContainer

var object : Object
var attached_prop : Control
var expression : Expression
var property : String
var child_nodes = []


func _initialize(object, property, attribute_name, params, inspector_plugin):
	self.object = object
	self.property = property
	expression = Expression.new()
	expression.parse(params[0])

	if !is_inside_tree(): await ready

	for child in get_parent().get_children():
		if (
			child is EditorProperty
			&& attached_prop == null
			&& (child.get_edited_property() == property || (
				child.has_method(&"_edits_properties")
				&& property in child._edits_properties(object, property, &"", params)
			))
		):
			attached_prop = child
			break
	
	for child in child_nodes:
		child.reparent(self)

	if attached_prop == null && child_nodes.size() == 0:
		push_warning("show_if attribute could not find %s property" % property)

	elif attached_prop != null:
		child_nodes.append(attached_prop)
		attached_prop.reparent(self)


func _update_view():
	if child_nodes.size() == 0: return
	var shown = expression.execute([], object)
	await get_tree().process_frame
	self.visible = shown


func _hides_property(): return false

func _deferred_init(): return true
