
extends Node

signal resized

func _ready():
	get_tree().connect("screen_resized",self,"_screen_resized")
	call_deferred("_screen_resized")

func _screen_resized():
	var default = Vector2( Globals.get("display/width"), Globals.get("display/height") )
	var current = OS.get_window_size()
	
	var default_mult = current/default
	var min_mult = min(default_mult.x,default_mult.y)
	
	emit_signal("resized",default,current,min_mult)
	
	


