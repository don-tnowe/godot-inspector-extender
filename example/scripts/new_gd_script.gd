extends Node2D

# @@message_warning(_negative_message)
@export var var1 := 0
@export var var2 : CompressedTexture2D
# @@buttons(#990000, "Nudge", _move, "Reset", #009900, _reset, "Reset but grey", _reset)
@export var var3 : Array[Sprite2D]


func _negative_message():
	return "" if var1 >= 0 else "Negative values cause unpredictable behaviour."


func _move():
	position.x += 4.0


func _boink():
	var1 = 0
