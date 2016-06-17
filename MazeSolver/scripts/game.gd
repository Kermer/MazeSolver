
extends Node2D

var level = null
var level_type = ""
onready var player = get_node("Player")

func _ready():
	pass

func start_endless():
	level_type = "endless"
	level = preload("res://scenes/maze_infinite.tscn").instance()
	level.player = player
#	get_node("Player/Camera").set_limit(MARGIN_RIGHT,width*CELL_SIZE)
#	get_node("Player/Camera").set_limit(MARGIN_BOTTOM,get_node("Player").get_pos().y+128)
	var cell_size = level.get_cell_size()
	var part_height = 16
	var width = Globals.get("display/width")/cell_size + 1
	add_child(level)
	move_child(level,0)
	level.generate(part_height,width)
#	level.hide()
	ready_player()
	pass

func ready_player():
#	player.set_darkness(true,OS.get_window_size()*3)
	player.set_pos( level.get_node("StartPos").get_pos() )
	var level_pos = level.get_pos()
	var cell_size = level.get_cell_size()
	var level_size = level.get_size() * cell_size
	player.set_limits( level_pos.x, level_pos.x+level_size.x, level_pos.y+cell_size*3 )
	player.set_process(true)
	

