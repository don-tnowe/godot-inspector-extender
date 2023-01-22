@tool
extends GridContainer

enum ComponentId {
	X, Y, Z, W, D,
	SIZE_W, SIZE_H, SIZE_D,
	POSITION_X,
	POSITION_Y,
	POSITION_Z,
	X_X, X_Y, X_Z, X_W,
	Y_X, Y_Y, Y_Z, Y_W,
	Z_X, Z_Y, Z_Z, Z_W,
	W_X, W_Y, W_Z, W_W,
}
const component_letters := [
	"x", "y", "z", "w", "d",
	"w", "h", "d",
	"x", "y", "z", 
	"xx", "xy", "xz", "xw",
	"yx", "yy", "yz", "yw",
	"zx", "zy", "zz", "zw",
	"wx", "wy", "wz", "ww",
]
const component_colors := [
	"property_color_x", "property_color_y", "property_color_z", "property_color_w", "property_color_w",
	"property_color_x", "property_color_y", "property_color_z",
	"property_color_x", "property_color_y", "property_color_z",
	"property_color_x", "property_color_y", "property_color_z", "property_color_w",
	"property_color_x", "property_color_y", "property_color_z", "property_color_w",
	"property_color_x", "property_color_y", "property_color_z", "property_color_w",
	"property_color_x", "property_color_y", "property_color_z", "property_color_w",
]

signal value_changed(new_value)

var value
var type := 0
var float_step := 0.01


func _init(value, type, float_step):
	self.value = value
	self.float_step = float_step
	add_theme_constant_override("h_separation", 0)
	call_deferred("init_" + str(type), value)


func add_field_with_label(component_id, value, is_int = false):
	var new_editor = EditorSpinSlider.new()
	new_editor.step = float_step if !is_int else 1.0
	new_editor.size_flags_horizontal = SIZE_EXPAND_FILL
	new_editor.hide_slider = true
	new_editor.allow_lesser = true
	new_editor.allow_greater = true
	new_editor.value = value
	new_editor.connect("value_changed", _on_field_edited.bind(component_id))

	var new_label = Label.new()
	add_child(new_label)
	add_child(new_editor)

	new_label.text = component_letters[component_id]
	new_label.modulate = Color.WHITE
	new_label.self_modulate = Color.WHITE
	new_label.self_modulate = get_theme_color(component_colors[component_id], "Editor")
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var new_panel = Panel.new()
	new_panel.show_behind_parent = true
	new_panel.modulate = Color(0.75, 0.75, 0.75, 1)
	new_panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	new_label.add_child(new_panel)


func _on_field_edited(new_value, component_id):
	if value is Transform3D:
		if component_id <= ComponentId.Z:
			value.origin = get_with_component_changed(value.origin, new_value, component_id)
		
		else:
			value.basis = get_with_component_changed(value.basis, new_value, component_id)

	elif value is Transform2D:
		if component_id <= ComponentId.Z:
			value.origin = get_with_component_changed(value.origin, new_value, component_id)

		else:
			value = get_with_component_changed(value, new_value, component_id)

	else:
		value = get_with_component_changed(value, new_value, component_id)

	emit_signal("value_changed", value)


func get_with_component_changed(tensor, new_value, component_id):
	match component_id:
		ComponentId.X:
			tensor.x = new_value
		ComponentId.Y:
			tensor.y = new_value
		ComponentId.Z:
			tensor.z = new_value
		ComponentId.W:
			tensor.w = new_value
		ComponentId.D:
			tensor.d = new_value
		ComponentId.POSITION_X:
			tensor.position.x = new_value
		ComponentId.POSITION_Y:
			tensor.position.y = new_value
		ComponentId.POSITION_Z:
			tensor.position.z = new_value
		ComponentId.SIZE_W:
			tensor.size.x = new_value
		ComponentId.SIZE_H:
			tensor.size.y = new_value
		ComponentId.SIZE_D:
			tensor.size.z = new_value

		ComponentId.X_X:
			tensor.x.x = new_value
		ComponentId.X_Y:
			tensor.x.y = new_value
		ComponentId.X_Z:
			tensor.x.z = new_value
		ComponentId.X_W:
			tensor.x.w = new_value

		ComponentId.Y_X:
			tensor.y.x = new_value
		ComponentId.Y_Y:
			tensor.y.y = new_value
		ComponentId.Y_Z:
			tensor.y.z = new_value
		ComponentId.Y_W:
			tensor.y.w = new_value

		ComponentId.Z_X:
			tensor.z.x = new_value
		ComponentId.Z_Y:
			tensor.z.y = new_value
		ComponentId.Z_Z:
			tensor.z.z = new_value
		ComponentId.Z_W:
			tensor.z.w = new_value

		ComponentId.W_X:
			tensor.w.x = new_value
		ComponentId.W_Y:
			tensor.w.y = new_value
		ComponentId.W_Z:
			tensor.w.z = new_value
		ComponentId.W_W:
			tensor.w.w = new_value

	return tensor

# Vector2
func init_5(value):
	columns = 4
	add_field_with_label(ComponentId.X, value.x)
	add_field_with_label(ComponentId.Y, value.y)

# Vector2i
func init_6(value):
	columns = 4
	add_field_with_label(ComponentId.X, value.x, true)
	add_field_with_label(ComponentId.Y, value.y, true)


# Rect2
func init_7(value):
	columns = 4
	add_field_with_label(ComponentId.POSITION_X, value.position.x)
	add_field_with_label(ComponentId.POSITION_Y, value.position.y)
	add_field_with_label(ComponentId.SIZE_W, value.size.x)
	add_field_with_label(ComponentId.SIZE_H, value.size.y)

# Also Rect2
func init_8(value):
	columns = 4
	add_field_with_label(ComponentId.POSITION_X, value.position.x, true)
	add_field_with_label(ComponentId.POSITION_Y, value.position.y, true)
	add_field_with_label(ComponentId.SIZE_W, value.size.x, true)
	add_field_with_label(ComponentId.SIZE_H, value.size.y, true)

# Vector3
func init_9(value):
	columns = 6
	add_field_with_label(ComponentId.X, value.x)
	add_field_with_label(ComponentId.Y, value.y)
	add_field_with_label(ComponentId.Z, value.z)

# Vector3i
func init_10(value):
	columns = 6
	add_field_with_label(ComponentId.X, value.x, true)
	add_field_with_label(ComponentId.Y, value.y, true)
	add_field_with_label(ComponentId.Z, value.z, true)

# Xform2
func init_11(value):
	columns = 4
	add_field_with_label(ComponentId.X_X, value.x.x)
	add_field_with_label(ComponentId.X_Y, value.x.y)
	add_field_with_label(ComponentId.Y_X, value.y.x)
	add_field_with_label(ComponentId.Y_Y, value.y.y)
	add_field_with_label(ComponentId.X, value.origin.x)
	add_field_with_label(ComponentId.Y, value.origin.y)

# Vector4
func init_12(value):
	columns = 8
	add_field_with_label(ComponentId.X, value.x)
	add_field_with_label(ComponentId.Y, value.y)
	add_field_with_label(ComponentId.Z, value.z)
	add_field_with_label(ComponentId.W, value.w)

# Vector4i
func init_13(value):
	columns = 8
	add_field_with_label(ComponentId.X, value.x, true)
	add_field_with_label(ComponentId.Y, value.y, true)
	add_field_with_label(ComponentId.Z, value.z, true)
	add_field_with_label(ComponentId.W, value.w, true)

# ✈
func init_14(value):
	columns = 8
	add_field_with_label(ComponentId.X, value.x)
	add_field_with_label(ComponentId.Y, value.y)
	add_field_with_label(ComponentId.Z, value.z)
	add_field_with_label(ComponentId.D, value.d)

# Quat
func init_15(value):
	columns = 8
	add_field_with_label(ComponentId.X, value.x)
	add_field_with_label(ComponentId.Y, value.y)
	add_field_with_label(ComponentId.Z, value.z)
	add_field_with_label(ComponentId.W, value.w)

# Rect3
func init_16(value):
	columns = 6
	add_field_with_label(ComponentId.POSITION_X, value.position.x)
	add_field_with_label(ComponentId.POSITION_Y, value.position.y)
	add_field_with_label(ComponentId.POSITION_Z, value.position.z)
	add_field_with_label(ComponentId.SIZE_W, value.size.x)
	add_field_with_label(ComponentId.SIZE_H, value.size.y)
	add_field_with_label(ComponentId.SIZE_D, value.size.z)

# Based
func init_17(value):
	columns = 6
	add_field_with_label(ComponentId.X_X, value.x.x)
	add_field_with_label(ComponentId.X_Y, value.x.y)
	add_field_with_label(ComponentId.X_Z, value.x.z)
	add_field_with_label(ComponentId.Y_X, value.y.x)
	add_field_with_label(ComponentId.Y_Y, value.y.y)
	add_field_with_label(ComponentId.Y_Z, value.y.z)
	add_field_with_label(ComponentId.Z_X, value.z.x)
	add_field_with_label(ComponentId.Z_Y, value.z.y)
	add_field_with_label(ComponentId.Z_Z, value.z.z)

# Xform3
func init_18(value):
	columns = 6

	# That's not the biggest type now...
	add_field_with_label(ComponentId.X_X, value.basis.x.x)
	add_field_with_label(ComponentId.X_Y, value.basis.x.y)
	add_field_with_label(ComponentId.X_Z, value.basis.x.z)
	add_field_with_label(ComponentId.Y_X, value.basis.y.x)
	add_field_with_label(ComponentId.Y_Y, value.basis.y.y)
	add_field_with_label(ComponentId.Y_Z, value.basis.y.z)
	add_field_with_label(ComponentId.Z_X, value.basis.z.x)
	add_field_with_label(ComponentId.Z_Y, value.basis.z.y)
	add_field_with_label(ComponentId.Z_Z, value.basis.z.z)
	add_field_with_label(ComponentId.X, value.origin.x)
	add_field_with_label(ComponentId.Y, value.origin.y)
	add_field_with_label(ComponentId.Z, value.origin.z)


func init_19(value):
	columns = 8

	# Absolute unit.
	add_field_with_label(ComponentId.X_X, value.x.x)
	add_field_with_label(ComponentId.X_Y, value.x.y)
	add_field_with_label(ComponentId.X_Z, value.x.z)
	add_field_with_label(ComponentId.X_W, value.x.w)
	add_field_with_label(ComponentId.Y_X, value.y.x)
	add_field_with_label(ComponentId.Y_Y, value.y.y)
	add_field_with_label(ComponentId.Y_Z, value.y.z)
	add_field_with_label(ComponentId.Y_W, value.y.w)
	add_field_with_label(ComponentId.Z_X, value.z.x)
	add_field_with_label(ComponentId.Z_Y, value.z.y)
	add_field_with_label(ComponentId.Z_Z, value.z.z)
	add_field_with_label(ComponentId.Z_W, value.z.w)
	add_field_with_label(ComponentId.W_X, value.w.x)
	add_field_with_label(ComponentId.W_Y, value.w.y)
	add_field_with_label(ComponentId.W_Z, value.w.z)
	add_field_with_label(ComponentId.W_W, value.w.w)
