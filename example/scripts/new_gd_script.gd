extends Node2D

# @@message_warning(_negative_message)
@export var var1 := 0
@export var var2 : CompressedTexture2D
# @@buttons(#990000, "Move(9, 20)", set_position(position + Vector2(9, 20)), "Reset", #009900, _reset)
@export var var3 : Array[Sprite2D]


func _negative_message():
	return "" if var1 >= 0 else "Negative values cause unpredictable behaviour."


func _boink():
	var1 = 0
