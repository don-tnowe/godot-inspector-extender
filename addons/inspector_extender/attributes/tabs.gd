@tool
extends EditorProperty

var bar : TabBar


func _initialize(object, property, attribute_name, params, inspector_plugin):
	var offsetter := Control.new()
	bar = TabBar.new()
	bar.tab_changed.connect(_on_tab_changed)
	for x in _get_object_hint(object, property):
		bar.add_tab(x)

	bar.current_tab = object[property]

	offsetter.add_child(bar)
	offsetter.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(offsetter)
	set_bottom_editor(offsetter)


func _get_object_hint(object, property):
	for x in object.get_property_list():
		if x[&"name"] == property:
			var result = x[&"hint_string"]
			if result.find(":") != -1 && result.find(":") < result.find(","):
				# Enum as type
				result = result.split(",")
				for i in result.size():
					result[i] = result[i].left(result[i].find(":"))

				return result

			# Enum as @export_enum
			return result.substr(result.rfind(":") + 1).split(",")


func _ready():
	self_modulate.a = 0.0
	await get_tree().process_frame
	bar.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bar.position.y -= get_minimum_size().y
	bar.tab_alignment = TabBar.ALIGNMENT_CENTER


func _on_tab_changed(tab):
	emit_changed(get_edited_property(), tab)


func _hides_property(): return true
func _update_view(): pass
