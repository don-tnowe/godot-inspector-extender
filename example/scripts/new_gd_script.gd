extends Node2D

# @@message(_val10)
@export var var1 = 4
@export var var2 : Resource


func _val10():
	return "" if var1 != 0 else "am zero"
