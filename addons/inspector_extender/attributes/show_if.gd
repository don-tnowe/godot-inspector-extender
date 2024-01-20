class_name ShowIfAttribute
# using PanelContainer to automatically fit to child elements
extends PanelContainer

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


func _ready():
	# hide default panel color
	self_modulate.a = 0
	# create empty style to remove default margins
	var style = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", style)
	
	for child in get_parent().get_children():
		if child is EditorProperty and attached_prop == null \
		and (child as EditorProperty).get_edited_property() == property:
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
