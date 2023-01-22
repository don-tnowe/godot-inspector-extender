@tool
extends Button

signal drop_received(from_container)

var value := 0: set = _set_value


func _set_value(v):
	value = v
	text = str(v)


func _init(position):
	_set_value(position)
	custom_minimum_size.x = 24
	mouse_default_cursor_shape = Control.CURSOR_MOVE


func _get_drag_data(position):
	var preview = HBoxContainer.new()
	var color = ColorRect.new()
	var editor_accent = get_theme_color(&"accent_color", &"Editor")

	color.color = Color(editor_accent, 0.25)
	color.custom_minimum_size.x = get_parent().size.x - size.x

	preview.add_child(duplicate())
	preview.add_child(color)
	set_drag_preview(preview)
	_set_siblings_modulate(editor_accent * 3.0)
	return {"array_move_from": self}


func _can_drop_data(position, data):
	var can = data.has("array_move_from")
	return can


func _drop_data(position, data):
	_set_siblings_modulate(Color.WHITE)
	drop_received.emit(data["array_move_from"])


func _set_siblings_modulate(mod):
	var script = get_script()
	for x in get_parent().get_children():
		if x.get_script() == script:
			x.modulate = mod
