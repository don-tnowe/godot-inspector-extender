@tool
class_name ResourceTableAttribute
extends TableAttribute


func _initialize(object, property, attribute_name, params, inspector_plugin):
	super._initialize(object, property, attribute_name, params, inspector_plugin)

	var table_rows : Array = []
	var cols : Array[String] = []
	var dtypes : Array = []

	var update_callback : Callable
	var move_callback : Callable
	var remove_callback : Callable
	var add_callback : Callable

	var row_resource

	if object[property] == null:
		object[property] = []

	var current
	var prop_types = {}
	var prop_hints = {}
	var array_class_name : StringName = _get_array_property_type(object, property)
	if ClassDB.can_instantiate(array_class_name):
		row_resource = ClassDB.instantiate(array_class_name)

	else:
		row_resource = _instantiate_custom_class(array_class_name)

	for x in row_resource.get_property_list():
		if x["usage"] & PROPERTY_USAGE_EDITOR != 0:
			prop_types[x["name"]] = x["type"]
			prop_hints[x["name"]] = x["hint_string"]

	if params.size() > 0:
		for x in params:
			cols.append(x.trim_suffix(" ").trim_prefix(" "))
			dtypes.append(prop_types[cols[-1]])

	else:
		for k in prop_types:
			if (
				k == &"resource_path" || k == &"resource_name"
				|| k == &"resource_local_to_scene" || k == &"script"
			):
				continue

			cols.append(k)
			dtypes.append(prop_types[k])
			if dtypes[-1] == TYPE_OBJECT:
				dtypes[-1] = prop_hints[k]

	var list = object[property]
	for i in list.size():
		current = []
		current.resize(cols.size())
		for j in cols.size():
			current[j] = list[i].get(cols[j])

		table_rows.append(current)

	update_callback = func(value, editor):
		var pos = _get_cell_pos(editor)
		var object_list = object[property]
		object_list[pos.y][cols[pos.x]] = value

		changing = true
		emit_changed(property, object_list, "", true)
		set_deferred(&"changing", false)

	move_callback = func(from_node, to_node):
		var from = _get_cell_pos(from_node).y
		var to = _get_cell_pos(to_node).y
		var object_list = object[property]
		_move_row(from, to)
		object_list.insert(to, object_list.pop_at(from))
		emit_changed(property, object_list, "", false)

	remove_callback = func(button):
		var row = _get_cell_pos(button).y
		var object_list = object[property]
		_remove_row(row)
		object_list.remove_at(row)
		emit_changed(property, object_list, "", false)

	add_callback = func(new_value):
		var new_row = []
		var row_count = object[property].size()
		new_row.resize(dtypes.size())

		_create_row(new_row, dtypes, update_callback, remove_callback, move_callback)
		object[property].append(new_value)
		emit_changed(property, object[property], "", false)


	super._update_pinned_properties(object)
	super._create_table(table_rows, cols, dtypes, update_callback, remove_callback, move_callback)
	super._create_add_button_new(add_callback, [row_resource.duplicate()])


func _edits_properties(_object, property, attribute_name, params) -> Array:
	return [property]
	
func _hides_property(): return true
