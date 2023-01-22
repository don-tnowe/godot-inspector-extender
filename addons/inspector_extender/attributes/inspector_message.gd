@tool
extends PanelContainer

const icon_atlas = preload("res://addons/inspector_extender/icons/icons.png")

var icons = {
	&"message" : _create_atlas(icon_atlas, 0, 0, 64, 64),
	&"message_info" : _create_atlas(icon_atlas, 0, 0, 64, 64),
	&"message_warning" : _create_atlas(icon_atlas, 64, 0, 64, 64),
	&"message_error" : _create_atlas(icon_atlas, 0, 64, 64, 64),
}
var object : Object
var expr := Expression.new()


func _initialize(object, property, attribute_name, params, inspector_plugin):
	set_icon(icons[attribute_name])
	self.object = object
	expr.parse(params[0])


func _ready():
	self_modulate = get_theme_color(&"disabled_highlight_color", &"Editor")


func _hides_property():
	return false


func _update_view():
	var text = expr.execute([], object)
	if text is Callable:
		text = text.call()

	if text == null:
		text = "!!! Message func must return a string!."

	visible = text != ""
	set_message(text)


func set_icon(icon):
	get_node("Box/TextureRect").texture = icon


func set_message(text):
	get_node("Box/Label").text = text


static func _create_atlas(img, x, y, w, h):
	var res := AtlasTexture.new()
	res.atlas = img
	res.region = Rect2(Vector2(x, y), Vector2(w, h))
	return res
