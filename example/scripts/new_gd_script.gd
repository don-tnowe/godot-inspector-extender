@tool
extends Node2D

# @@message_warning(_negative_message)
@export var var1 := 0
@export var var2 : CompressedTexture2D
# @@value_dropdown(get_children())
@export var selected_child : Node
# @@tabs()
@export_enum("Show resource_table", "Show dict_table", "Don't show") var var_enum := 0
# @@dict_table(a : int, b : String, c : float, d : Vector2, e : Texture2D)
# @@scroll_box(256)
# @@show_if(var_enum == 1)
@export var var4 : Array[Dictionary]
# @@resource_table()
# @@show_if(var_enum == 0)
@export var var6 : Array[AtlasTexture]
# @@buttons(#009900, "Move(9, 20)", set_position(position + Vector2(9, 20)), "Reset", #990000, _reset())
@export var var3 : Array[Resource]


func _negative_message():
	return "" if var1 >= 0 else "Negative values cause unpredictable behaviour."

func _reset():
	var1 = 0
