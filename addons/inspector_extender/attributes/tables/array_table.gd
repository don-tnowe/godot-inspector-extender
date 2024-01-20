@tool
class_name ArrayTableAttribute
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
	row_resource = {}
	for i in params.size():
		current = params[i].split(":")
		cols.append(current[0].trim_suffix(" "))
		dtypes.append(current[1].trim_prefix(" "))
		row_resource[cols[i]] = TensorPropertyEditor.default_by_type.get(
			TensorPropertyEditor.type_by_name.get(dtypes[i], dtypes[i]),
			null
		)

	var list = object[property]
	for i in list.size():
		current = []
		current.resize(cols.size())
		list[i].resize(cols.size())
		for j in cols.size():
			current[j] = list[i][j]

		table_rows.append(current)

	update_callback = func(value, editor):
		var pos = _get_cell_pos(editor)
		var object_list = object[property]
		object_list[pos.y][pos.x] = value

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
	super._create_add_button_new(add_callback)


func _edits_properties(_object, property, attribute_name, params) -> Array:
	return [property]
