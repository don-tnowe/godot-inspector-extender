#@tool
extends Resource

# @@message_error(_val1)
@export var var1 := 0
# @@message_error(_val2)
# @@message_warning(_val3)
@export var var2 := ""
# @@message_info(_val_resource())
@export var var3 : Resource
# @@buttons("Stuff", _inc_var1)
@export var var4 := []


func _val1():
	return "" if var1 >= 0 else\
		"Value must be non-negative (currently %s)" % var1


func _val2():
	return "" if var2 != "" else\
		"String must be set."


func _val3():
	return "" if !" " in var2 else\
		"Path must not contain whitespace, bacause some programmers"\
		+ " don't know you can escape whitespace in CLI."


func _val_resource():
	return "" if var3 == null else\
		"That is a nice %s." % var3.get_class()


func _inc_var1():
	var1 += 10
