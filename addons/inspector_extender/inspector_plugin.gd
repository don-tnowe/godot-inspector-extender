extends EditorInspectorPlugin

var attribute_scenes := {}

var attribute_data := {}
var attribute_nodes := []
var all_properties := []
var hidden_properties := {}
var original_edited_object : Object
var edited_object : Object
var delayed_attribute : Object = null
var delayed_att_params = null
var attr_config = ConfigFile.new()

var plugin : EditorPlugin
var inspector : EditorInspector


func _init(plugin : EditorPlugin):
	self.plugin = plugin
	inspector = plugin.get_editor_interface().get_inspector()
	inspector.property_edited.connect(_on_edited_object_changed)


func _can_handle(object):
	return object.get_script() != null


func _parse_begin(object):
	original_edited_object = object
	if (
		is_instance_valid(edited_object)
		&& edited_object is Node
		&& !edited_object.is_inside_tree()
		&& !edited_object.get_script().is_tool()
	):
		edited_object.free()

	# For params that call methods, create a new object in tool mode (or methods won't be there)
	if !object.get_script().is_tool():
		object = create_editable_copy(object)

	var source = object.get_script().source_code
	edited_object = object

	var parse_found_comments := []
	attribute_data.clear()
	attribute_nodes.clear()
	all_properties.clear()
	hidden_properties.clear()

	# load config file to get available attribute names
	if attr_config.get_sections().size() == 0:
		attr_config.load("res://addons/inspector_extender/attributes/attributes.cfg")
	var template = attr_config.get_value("all_attributes", "template")
	var attr_base_path = attr_config.get_value("all_attributes", "base_resource_path")
	
	for attr_key in attr_config.get_sections():
		if attr_key == "all_attributes":
			continue
		var key_path = attr_config.get_value(attr_key, "resource_path")
		attribute_scenes[StringName(template % attr_key)] = load(attr_base_path + key_path)
	
	# parse all source code lines
	for line in source.split("\n"):
		line = line.strip_edges()
		# ignore blank lines
		if line.is_empty(): continue
		
		# assign detected attributes to variable
		if parse_found_comments.size() > 0 \
		and (line.begins_with("@export ") || line.begins_with("@export_")):
			var prop_name = get_suffix(" var ", line)
			if prop_name.is_empty(): continue

			attribute_data[prop_name] = parse_found_comments
			parse_found_comments = []
			# continue to avoid attempt at parsing comments
			continue

		# check if comment contains an attribute
		if line.unicode_at(0) == "#".unicode_at(0):
			for attr_key in attr_config.get_sections():
				var k = template % attr_key
				if line.begins_with(k):
					parse_found_comments.append([k, get_params(line.substr(line.find("(")))])


func create_editable_copy(object):
	var new_object = object.get_script().new()
	for x in object.get_property_list():
		if x["usage"] == 0:
			continue

		if x["usage"] & (PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP) != 0:
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
						var result = line.substr(i + 1, line.find(" ", i + to_find.length()) - i - 1)
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
	var constructed_nodes = []
	var show_if_node : ShowIfAttribute = null
	for x in attribute_data[name]:
		var prototype = attribute_scenes[x[0]]
		var new_node = prototype.instantiate() if prototype is PackedScene else prototype.new()
		var attr_name = x[0].substr(x[0].find("@@") + 2)
		attr_name = attr_name.left(attr_name.find("("))
		
		if new_node is ShowIfAttribute:
			show_if_node = new_node
			delayed_attribute = new_node
			delayed_att_params = [name, attr_name, x[1]]
			continue
		
		constructed_nodes.append(new_node)
		attribute_nodes.append(new_node)
		
		prop_hidden = _construct_node(new_node, name, prop_hidden, attr_name, x)
		
		if delayed_attribute != null:
			prop_hidden = _construct_node(delayed_attribute, name, prop_hidden, attr_name, delayed_att_params)
			delayed_attribute = null
			delayed_att_params = []
	
	
	if show_if_node != null:
		show_if_node.child_nodes = constructed_nodes
			
	constructed_nodes = []
	_on_edited_object_changed()
	return prop_hidden || hidden_properties.has(name)


func _construct_node(new_node, prop_name, is_prop_hidden, attr_name, params):
	if new_node is ShowIfAttribute:
		new_node._initialize(edited_object, params[0], params[1], params[2], self)
	else:
		new_node._initialize(edited_object, prop_name, attr_name, params[1], self)
	attribute_nodes.append(new_node)
	
	if new_node.has_method("_hides_property"):
		var hides = new_node._hides_property()
		if hides is bool:
			is_prop_hidden = is_prop_hidden || hides
		else:
			for y in hides:
				hidden_properties[y] = true

	if new_node is EditorProperty:
		if new_node.has_method(&"_edits_properties"):
			add_property_editor_for_multiple_properties("", new_node._edits_properties(edited_object, prop_name, attr_name, params[1]), new_node)
		else:
			add_property_editor_for_multiple_properties("", [prop_name], new_node)
	else:
		add_custom_control(new_node)
	
	return is_prop_hidden


func _on_edited_object_changed(prop = ""):
	if prop != "":
		edited_object.set(prop, original_edited_object[prop])

	for x in attribute_nodes:
		if is_instance_valid(x):
			x.call_deferred(&"_update_view")


func _on_object_tree_exited():
	if !edited_object.get_script().is_tool():
		edited_object.free()
