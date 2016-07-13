
# This Scene is mostly used to be parent for key scenes
# You can think of it as a custom "root"

extends Node

signal resized

var DEFAULT # for which resolution was the game made
var CURRENT # what is the current window size
var MULT # maximum scale for keeping the aspect

func _ready():
	get_tree().connect("screen_resized",self,"_screen_resized")
	call_deferred("_screen_resized") # update sizes and scales after everything is initialized

func _screen_resized():
	DEFAULT = Vector2( Globals.get("display/width"), Globals.get("display/height") )
	CURRENT = OS.get_window_size()
	
	var default_mult = CURRENT/DEFAULT
	# MULTiplier - maximum scale for keeping the aspect
	MULT = min(default_mult.x,default_mult.y)
	
	emit_signal("resized",DEFAULT,CURRENT,MULT)

# In case you want to get the "resized" signal data after it fired
# This is already used in 'game.gd' for example ( 'game.tscn' gets loaded and unloaded quite often )
func get_sizes():
	return [DEFAULT,CURRENT,MULT]

