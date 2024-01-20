@tool
class_name MultiArrayTableAttribute
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
	
	var default_by_type = TensorPropertyEditor.default_by_type
	var type_by_name = TensorPropertyEditor.type_by_name
	var row_count := 0
	var col_values := []
	var col_defaults := []

	for_properties = params.map(func(x): return StringName(x))
	cols.append_array(for_properties)
	var prefix : String = for_properties[0]
	col_values.resize(cols.size())
	col_defaults.resize(cols.size())
	dtypes.resize(cols.size())
	for i in cols.size():
		col_values[i] = object[cols[i]]

		if col_values[i].size() == 0:
			object[cols[i]] = object[cols[i]]
			emit_changed(for_properties[i], col_values[i], "", false)

		if col_values[i].size() > row_count:
			row_count = col_values[i].size()

		for j in min(cols[i].length(), prefix.length()):
			if prefix.unicode_at(j) != cols[i].unicode_at(j):
				prefix = prefix.left(j)
				break

	label = prefix.capitalize()
	for x in object.get_property_list():
		var col_idx = for_properties.find(x["name"])
		if col_idx != -1:
			var split = x["hint_string"].split(":")
			dtypes[col_idx] = split[1]

	for i in cols.size():
		cols[i] = cols[i].substr(prefix.length())
		if col_values[i].size() < row_count:
			col_values[i].resize(row_count)
			for j in col_values[i].size():
				if col_values[i][j] == null:
					col_values[i][j] = default_by_type.get(type_by_name.get(dtypes[i], dtypes[i]), null)

			emit_changed(for_properties[i], col_values[i], "", false)

	table_rows.resize(row_count)
	for i in row_count:
		var cur_row = []
		cur_row.resize(cols.size())
		for j in cols.size():
			cur_row[j] = col_values[j][i]

		table_rows[i] = cur_row

	update_callback = func(value, editor):
		var pos := _get_cell_pos(editor)
		if !is_inside_tree(): pos.x += 1
		col_values[pos.x][pos.y] = value
		changing = true
		emit_changed(for_properties[pos.x], col_values[pos.x], "", true)
		set_deferred(&"changing", false)

	move_callback = func(from_node, to_node):
		var from := _get_cell_pos(from_node).y
		var to := _get_cell_pos(to_node).y
		_move_row(from, to)
		for x in for_properties:
			var array_in_object = object[x]
			array_in_object.insert(to, array_in_object.pop_at(from))
			emit_changed(x, array_in_object, "", false)

	remove_callback = func(button):
		var row := _get_cell_pos(button).y
		_remove_row(row)
		for x in for_properties:
			var array_in_object = object[x]
			array_in_object.remove_at(row)
			emit_changed(x, array_in_object, "", false)

	add_callback = func(new_value):
		var new_row := []
		new_row.resize(dtypes.size())
		_create_row(new_row, dtypes, update_callback, remove_callback, move_callback)
		for i in for_properties.size():
			var array_in_object = object[for_properties[i]]
			if array_in_object.size() > 0:
				array_in_object.append(array_in_object[-1])

			else:
				array_in_object.append(default_by_type.get(type_by_name.get(dtypes[i], dtypes[i]), null))

			emit_changed(for_properties[i], array_in_object, "", false)
	
	super._update_pinned_properties(object)
	super._create_table(table_rows, cols, dtypes, update_callback, remove_callback, move_callback)
	super._create_add_button_new(add_callback)


func _edits_properties(_object, property, attribute_name, params) -> Array:
	return params
