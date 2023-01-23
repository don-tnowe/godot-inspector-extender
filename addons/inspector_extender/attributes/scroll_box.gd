extends Control

var scrollbox_height := 0.0
var scrollbox_width := 0.0
var for_property : StringName


func _initialize(object, property, attribute_name, params, inspector_plugin):
	for_property = property
	if params.size() >= 1:
		scrollbox_height = params[0].to_float()

	if params.size() >= 2:
		scrollbox_width = params[1].to_float()

	hide()

func _update_view(): pass
func _hides_property(): return false
