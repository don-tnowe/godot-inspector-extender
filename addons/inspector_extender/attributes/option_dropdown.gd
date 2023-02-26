extends EditorProperty

var object : Object
var original_edited_object : Object
var expression : Expression
var dropdown : PopupMenu
var dropdown_button : BaseButton
var options


func _initialize(object, property, attribute_name, params, inspector_plugin):
	self.object = object
	original_edited_object = inspector_plugin.original_edited_object
	expression = Expression.new()
	expression.parse(params[0])

	dropdown_button = OptionButton.new()
	dropdown_button.clip_text = true
	dropdown_button.flat = true
	add_child(dropdown_button)
	add_focusable(dropdown_button)

	dropdown = dropdown_button.get_popup()
	dropdown.about_to_popup.connect(_on_about_to_popup)
	dropdown.index_pressed.connect(_on_index_selected)
	call_deferred(&"update_property")


func _on_about_to_popup():
	options = expression.execute([], original_edited_object)
	dropdown.clear()
	for x in options:
		dropdown.add_item(str(x) if !x is Node else original_edited_object.get_path_to(x))

	if options is Dictionary:
		options = options.values()


func _on_index_selected(index):
	var value = options[index]
	if value is Node:
		original_edited_object.set(
			"metadata/_editor_prop_ptr_" + get_edited_property(),
			original_edited_object.get_path_to(value)
		)

	emit_changed(get_edited_property(), value, "", true)


func _update_property():
	var value = get_edited_object()[get_edited_property()]
	if value == null:
		value = object.get("metadata/_editor_prop_ptr_" + get_edited_property())

	dropdown.clear()
	dropdown_button.text = str(value) if !value is Node else original_edited_object.get_path_to(value)


func _update_view(): pass
func _hides_property(): return true
