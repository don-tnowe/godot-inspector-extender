@tool
class_name TableAttribute
extends EditorProperty

const TensorPropertyEditor := preload("res://addons/inspector_extender/tensor_property_editor.gd")
const ArrayIndex := preload("res://addons/inspector_extender/array_index.gd")

var vbox : VBoxContainer
var grid : GridContainer
var scrollbox : ScrollContainer
var redraw_func : Callable
var for_properties : Array

var changing := false


func _initialize(object, property, attribute_name, params, inspector_plugin):
	for_properties = [property]
	redraw_func = func(): _initialize(object, property, attribute_name, params, inspector_plugin)
	for x in get_children(): x.free()
	_create_containers()


func _update_pinned_properties(object):
	var pinned_props = []
	if &"metadata/_edit_pinned_properties_" in object:
		pinned_props = object.get(&"metadata/_edit_pinned_properties_")

	var pinned_props_init_size : int = pinned_props.size()
	for x in for_properties:
		if !pinned_props.has(x) && object[x].size() == 0:
			pinned_props.append(StringName(x))

	if pinned_props_init_size != pinned_props.size():
		emit_changed(&"metadata/_edit_pinned_properties_", pinned_props, "", false)


func _create_containers():
	vbox = VBoxContainer.new()
	grid = GridContainer.new()
	scrollbox = ScrollContainer.new()
	vbox.add_child(scrollbox)
	scrollbox.add_child(grid)
	add_child(vbox)
	set_bottom_editor(vbox)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.size_flags_horizontal = SIZE_EXPAND_FILL

func _create_add_button_new(add_callback : Callable, arguments : Array = []):
	var add_button := Button.new()
	add_button.pressed.connect(add_callback.bindv(arguments))
	add_button.size_flags_horizontal = SIZE_SHRINK_CENTER
	add_button.text = "Add Row"
	add_button.custom_minimum_size.x = 192.0
	vbox.add_child(add_button)
	if !is_inside_tree(): await ready
	add_button.icon = get_theme_icon(&"Add", &"EditorIcons")


func _create_table(
	rows : Array, cols : Array[String], dtypes : Array,
	update_callback : Callable, remove_callback : Callable, move_callback : Callable
):
	grid.columns = cols.size() + 2
	grid.add_child(Control.new())
	for i in cols.size():
		var new_label = Label.new()
		new_label.text = cols[i].capitalize()
		new_label.clip_text = true
		new_label.tooltip_text = new_label.text
		new_label.mouse_filter = MOUSE_FILTER_PASS
		grid.add_child(new_label)

	grid.add_child(Control.new())

	for i in rows.size():
		_create_row(rows[i], dtypes, update_callback, remove_callback, move_callback)


func _create_row(values, dtypes, update_callback, remove_callback, move_callback):
	var index := ArrayIndex.new(grid.get_child_count() / grid.columns - 1)
	var ed : Control
	index.drop_received.connect(move_callback.bind(index))
	grid.add_child(index)

	for j in dtypes.size():
		ed = _get_new_property_editor(values[j], dtypes[j], update_callback)
		grid.add_child(ed)

	var del_button = Button.new()
	del_button.pressed.connect(remove_callback.bind(del_button))
	grid.add_child(del_button)

	if !is_inside_tree(): await ready
	del_button.icon = get_theme_icon(&"Remove", &"EditorIcons")


func _remove_row(index):
	var row_start = (index + 1) * grid.columns
	for i in grid.columns:
		grid.get_child(row_start + i).queue_free()

	_update_index_display()


func _move_row(from_index, to_index):
	var grabbed_nodes := []
	var down = from_index > to_index
	from_index = (from_index + (2 if down else 1)) * grid.columns + (-1 if down else 1)
	to_index = (to_index + (1 if down else 2)) * grid.columns
	for i in grid.columns:
		grid.move_child(grid.get_child(from_index), to_index)

	_update_index_display()


func _update_index_display():
	for x in grid.get_children():
		if x is ArrayIndex:
			x.text = str(_get_cell_pos(x).y)


func _get_cell_pos(control : Control) -> Vector2i:
	var index = control.get_index()
	return Vector2i(index % grid.columns - 1, index / grid.columns - 1)


func _get_new_property_editor(initial_value, dtype, update_callback):
	match dtype:
		"bool", TYPE_BOOL:
			var new_editor = CheckBox.new()
			new_editor.size_flags_horizontal = SIZE_FILL
			if initial_value != null:
				new_editor.button_pressed = initial_value

			new_editor.toggled.connect(update_callback.bind(new_editor))
			return new_editor

		"int", "float", TYPE_INT, TYPE_FLOAT:
			var new_editor = EditorSpinSlider.new()
			new_editor.step = 1.0
			if dtype is int && dtype == TYPE_FLOAT || dtype is String && dtype == "float":
				new_editor.step = 0.001

			new_editor.hide_slider = true
			new_editor.allow_lesser = true
			new_editor.allow_greater = true
			new_editor.size_flags_horizontal = SIZE_EXPAND_FILL
			if initial_value != null:
				new_editor.value = initial_value

			new_editor.value_changed.connect(update_callback.bind(new_editor))
			return new_editor

		"String", "StringName", "NodePath", TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var new_editor = LineEdit.new()
			new_editor.size_flags_horizontal = SIZE_EXPAND_FILL
			new_editor.size_flags_stretch_ratio = 2.0
			if initial_value != null:
				new_editor.text = initial_value

			new_editor.text_changed.connect(update_callback.bind(new_editor))
			return new_editor

		"Color", TYPE_COLOR:
			var new_editor = ColorPickerButton.new()
			if initial_value != null:
				new_editor.color = initial_value

			new_editor.color_changed.connect(update_callback.bind(new_editor))
			return new_editor

		_:
			if dtype is int && dtype == TYPE_OBJECT:
				dtype = "Resource"

			if dtype is String && (ClassDB.class_exists(dtype) || _instantiate_custom_class(dtype)):
				if ClassDB.is_parent_class(dtype, &"Node"):
					return _get_new_property_editor(initial_value, "NodePath", update_callback)

				var new_editor = EditorResourcePicker.new()
				new_editor.base_type = dtype
				new_editor.resource_changed.connect(func (x):
					update_callback.call(x, new_editor)
				)
				new_editor.size_flags_horizontal = SIZE_EXPAND_FILL
				new_editor.size_flags_stretch_ratio = 2.0
				if initial_value != null:
					new_editor.edited_resource = initial_value

				return new_editor

			else:
				var new_editor = TensorPropertyEditor.new(initial_value, dtype, 0.001)
				new_editor.value_changed.connect(update_callback.bind(new_editor))
				new_editor.size_flags_horizontal = SIZE_EXPAND_FILL
				return new_editor


func _get_array_property_type(object, property):
	var property_classname := &"Resource"
	for x in object.get_property_list():
		if x["name"] == property:
			property_classname = x["hint_string"]
			return property_classname.substr(property_classname.rfind(":") + 1)


func _instantiate_custom_class(c : StringName) -> Object:
	var arr := ProjectSettings.get_global_class_list()
	for x in arr:
		if x[&"class"] == c:
			return load(x[&"path"]).new()

	return null


func _get_scrollbox_minsize():
	var scrollbox_height := get_viewport_rect().size.y * 0.75
	var scrollbox_width := 0.0

	var cur_index := get_parent().get_child_count() - 1
	var cur_sibling : Control
	while true:
		cur_sibling = get_parent().get_child(cur_index)
		if &"for_properties" in cur_sibling && for_properties == cur_sibling.for_properties && &"scrollbox_height" in cur_sibling:
			if cur_sibling.scrollbox_height > 0:
				scrollbox_height = cur_sibling.scrollbox_height

			scrollbox_width = cur_sibling.scrollbox_width
			break

		cur_index -= 1
		if cur_index == -1:
			break 

	return Vector2(scrollbox_width, scrollbox_height)


func _update_view():
	if changing: return

	var scrollbox_size = _get_scrollbox_minsize()
	grid.hide()
	grid.show()
	if scrollbox_size.y > 0:
		scrollbox.custom_minimum_size.y = scrollbox_size.y
		scrollbox.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		if grid.get_minimum_size().y < scrollbox_size.y:
			scrollbox.custom_minimum_size.y = 0
			scrollbox.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	else:
		scrollbox.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func _update_property():
	redraw_func.call()
	_update_view()


func _hides_property(): return for_properties


func _edits_properties(_object, property, attribute_name, params) -> Array:
	if attribute_name == &"multi_array_table":
		return params

	return [property]
