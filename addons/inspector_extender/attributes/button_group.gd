@tool
extends EditorProperty

var box : HBoxContainer


func _initialize(object, property, attribute_name, params, inspector_plugin):
	var offsetter := Control.new()
	box = HBoxContainer.new()

	offsetter.add_child(box)
	offsetter.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(offsetter)
	set_bottom_editor(offsetter)

	if attribute_name == &"buttons":
		_create_buttons(object, params, inspector_plugin)


func _create_buttons(object, params, inspector_plugin):
	var btn_color := Color.TRANSPARENT
	var btn_text := ""
	for x in params:
		if x.begins_with('"') || x.begins_with("'"):
			btn_text = x.substr(1, x.length() - 2)

		elif x.begins_with("#"):
			btn_color = Color(x)

		else:
			var new_button = Button.new()
			new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if btn_color.a != 0.0:
				call_deferred("_recolor_button", new_button, btn_color)
				btn_color.a = 0.0

			new_button.text = btn_text
			new_button.pressed.connect(_on_button_pressed.bind(object, x, inspector_plugin))
			box.add_child(new_button)


func _on_button_pressed(object, function, inspector_plugin):
	var object_tool = object.get_script().is_tool()
	var last_props := {}
	if !object_tool:
		for y in inspector_plugin.all_properties:
			# If object got duplicated, then changes must be synced.
			# To not spam undo/redo entries, only emit signal for each actual change,
			# not for each and every property.
			last_props[y] = inspector_plugin.original_edited_object.get(y)

	var expr = Expression.new()
	expr.parse(function)
	expr.execute([], object)
	if object_tool:
		# In tool script, only one property needs to change to mark object as unsaved.
		var property = inspector_plugin.all_properties[0]
		emit_changed(property, object.get(property), "", true)

	else:
		for y in inspector_plugin.all_properties:
			if y == "resource_path":
				# A duplicate has no path. Don't make the original's path empty.
				continue

			if object.get(y) != last_props[y]:
				inspector_plugin.original_edited_object.set(y, object.get(y))
				emit_changed(y, object.get(y), "", true)


func _ready():
	get_parent().call_deferred("move_child", self, get_index() + 1)
	self_modulate.a = 0.0
	await get_tree().process_frame
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.position.y -= get_minimum_size().y


func _recolor_button(button : Button, color : Color):
	var style = button.get_theme_stylebox("normal", "Button").duplicate()
	style.bg_color = color
	button.add_theme_stylebox_override("normal", style)

	style = button.get_theme_stylebox("hover", "Button").duplicate()
	style.bg_color = color.blend(Color(1.0, 1.0, 1.0, 0.2))
	button.add_theme_stylebox_override("hover", style)


func _hides_property(): return false
func _update_view(): pass
