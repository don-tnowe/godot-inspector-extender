extends EditorInspectorPlugin

const load_dir := "res://addons/inspector_extender/attributes/"
const attr_template := "# @@%s("

var attribute_scenes := {
	StringName(attr_template % "message") :
		load(load_dir + "inspector_message.tscn"),
	StringName(attr_template % "message_info") :
		load(load_dir + "inspector_message.tscn"),
	StringName(attr_template % "message_warning") :
		load(load_dir + "inspector_message.tscn"),
	StringName(attr_template % "message_error") :
		load(load_dir + "inspector_message.tscn"),

	StringName(attr_template % "buttons") :
		load(load_dir + "button_group.gd"),

	StringName(attr_template % "dict_table") :
		load(load_dir + "table.gd"),
	StringName(attr_template % "resource_table") :
		load(load_dir + "table.gd"),
	StringName(attr_template % "array_table") :
		load(load_dir + "table.gd"),
	StringName(attr_template % "multi_array_table") :
		load(load_dir + "table.gd"),

	StringName(attr_template % "value_dropdown") :
		load(load_dir + "option_dropdown.gd"),
	StringName(attr_template % "tabs") :
		load(load_dir + "tabs.gd"),
	StringName(attr_template % "show_if") :
		load(load_dir + "show_if.gd"),
	StringName(attr_template % "scroll_box") :
		load(load_dir + "scroll_box.gd"),
}

var attribute_data := {}
var attribute_nodes := []
var all_properties := []
var hidden_properties := {}
var original_edited_object : Object
var edited_object : Object
var deferred_init_attributes : Array = []
var constructed_nodes = []

var plugin : EditorPlugin
var inspector : EditorInspector


func _init(plugin : EditorPlugin):
	self.plugin = plugin
	inspector = plugin.get_editor_interface().get_inspector()
	inspector.property_edited.connect(_on_edited_object_changed)


func _can_handle(object : Object):
	_reset_state()
	return object.get_script() != null


func _parse_begin(object : Object):
	original_edited_object = object

	attribute_data.clear()
	attribute_nodes.clear()
	all_properties.clear()
	hidden_properties.clear()
	deferred_init_attributes.clear()

	# For params that call methods, create a new object in tool mode (or methods won't be there)
	if !object.get_script().is_tool():
		object = create_editable_copy(object)

	edited_object = object
	_parse_single_script(object.get_script())


func _parse_single_script(parse_script : Script):
	if parse_script.get_base_script() != null:
		_parse_single_script(parse_script.get_base_script())

	var source : String = parse_script.source_code
	var parse_found_prop := ""
	var parse_found_comments := []
	var illegal_starts = ["#".unicode_at(0), " ".unicode_at(0), "\t".unicode_at(0)]
	for x in source.split("\n"):
		if x == "": continue
		if !x.unicode_at(0) in illegal_starts && ("@export " in x || "@export_" in x):
			var prop_name = get_suffix(" var ", x)
			if prop_name == "": continue

			parse_found_prop = prop_name
			attribute_data[prop_name] = parse_found_comments
			parse_found_comments = []

		for k in attribute_scenes:
			if x.begins_with(k):
				parse_found_comments.append([k, get_params(x.substr(x.find("(")))])


func create_editable_copy(object : Object):
	var new_object = object.get_script().new()
	for x in object.get_property_list():
		if x["usage"] == 0:
			continue

		if x["usage"] & (PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP) != 0:
			continue
		
		if x["name"] == "resource_path":
			continue
		
		new_object.set(x["name"], object[x["name"]])

	return new_object


func get_suffix(to_find : String, line : String):
	var unclosed_quote := 0
	var unclosed_quote_char := -1
	var unclosed_paren := 0
	var unclosed_brackets := 0
	var unclosed_stache := 0

	var string_chars_matched := 0

	for i in line.length():
		match line.unicode_at(i):
			34, 39:
				if unclosed_quote == 0:
					unclosed_quote = 1
					unclosed_quote_char = line.unicode_at(i)

				elif unclosed_quote_char == line.unicode_at(i):
					unclosed_quote = 0

			40: unclosed_paren += 1
			41: unclosed_paren -= 1
			91: unclosed_brackets += 1
			93: unclosed_brackets -= 1
			123: unclosed_stache += 1
			125: unclosed_stache -= 1
			var other:
				if (
					unclosed_quote == 0 && unclosed_paren == 0
					&& unclosed_brackets == 0 && unclosed_stache == 0
					&& other == to_find.unicode_at(string_chars_matched)
				):
					string_chars_matched += 1
					if string_chars_matched == to_find.length():
						var result = line.substr(i + 1, line.find(" ", i + 1) - i - 1)
						if result.ends_with(":"):
							result = result.trim_suffix(":")
						return result

				else:
					string_chars_matched = 0

	return ""


func get_params(string : String):
	var unclosed_paren := 0
	var unclosed_quote := 0
	var unclosed_brackets := 0
	var unclosed_stache := 0

	var param_start = 0
	var param_started = false
	var params = []
	for i in string.length():
		match string.unicode_at(i):
			34, 39:
				if unclosed_quote == 0 && !param_started:
					param_start = i
					param_started = true

				unclosed_quote = 1 - unclosed_quote

			91: unclosed_brackets += 1
			93: unclosed_brackets -= 1
			123: unclosed_stache += 1
			125: unclosed_stache -= 1
			40: unclosed_paren += 1
			41:
				unclosed_paren -= 1
				if unclosed_paren == 0:
					params.append(string.substr(param_start, i - param_start))
					return params if params[0] != "(" else []

			var other:
				if unclosed_paren == 1 && unclosed_quote == 0 && unclosed_brackets == 0 && unclosed_stache == 0:
					match other:
						44:  # comma
							if param_started:
								params.append(string.substr(param_start, i - param_start))

							param_started = false

						32, 40: pass  # space, opening paren
						_:
							if !param_started:
								param_start = i
								param_started = true

	return params


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	all_properties.append(name)
	
	if !attribute_data.has(name): return hidden_properties.has(name)
	var prop_hidden := false
	constructed_nodes = []
	for x in attribute_data[name]:
		var prototype = attribute_scenes[x[0]]
		var new_node = prototype.instantiate() if prototype is PackedScene else prototype.new()
		var attr_name = x[0].substr(x[0].find("@@") + 2)
		attr_name = attr_name.left(attr_name.find("("))
		
		attribute_nodes.append(new_node)
		constructed_nodes.append(new_node)
		if new_node.has_method(&"_deferred_init") && new_node._deferred_init():
			deferred_init_attributes.append([new_node, name, attr_name, x[1]])
			# add container now so it is in the correct position
			add_custom_control(new_node)
			continue

		new_node._initialize(edited_object, name, attr_name, x[1], self)
		if new_node.has_method(&"_hides_property"):
			var hides = new_node._hides_property()
			if hides is bool:
				prop_hidden = prop_hidden || hides

			else:
				for y in hides:
					hidden_properties[y] = true

		if new_node is EditorProperty:
			if new_node.has_method(&"_edits_properties"):
				add_property_editor_for_multiple_properties("", new_node._edits_properties(edited_object, name, attr_name, x[1]), new_node)

			else:
				add_property_editor_for_multiple_properties("", [name], new_node)

		else:
			add_custom_control(new_node)

	_on_edited_object_changed()
	return prop_hidden || hidden_properties.has(name)


func _parse_end(object):
	for x in deferred_init_attributes:
		x[0]._initialize(edited_object, x[1], x[2], x[3], self)
		attribute_nodes.append(x[0])

		_on_edited_object_changed()


func _on_edited_object_changed(prop = ""):
	if edited_object == null:
		return
	
	if prop != "":
		edited_object.set(prop, original_edited_object[prop])

	for x in attribute_nodes:
		if is_instance_valid(x):
			x.call_deferred(&"_update_view")


func _on_object_tree_exited():
	if !edited_object.get_script().is_tool():
		edited_object.free()


func _reset_state() -> void:
	if (
		edited_object != null
		and is_instance_valid(edited_object)
		and edited_object is Node
		and !edited_object.is_inside_tree()
		and !edited_object.get_script().is_tool()
	):
		edited_object.free()

	edited_object = null

	deferred_init_attributes.clear()
	attribute_data.clear()
	attribute_nodes.clear()
	all_properties.clear()
	hidden_properties.clear()
