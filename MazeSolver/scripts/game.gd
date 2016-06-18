
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

func start_classic( file_name ):
	var level_scene = load("res://levels/"+file_name)
	if level_scene == null:
		dprint(str("Failed to load level. file_name=\"",file_name,"\""))
		return
	level_type = "classic"
	level = level_scene.instance()
	add_child(level)
	move_child(level,0)
	ready_level()
	ready_player()
	var top_limit = level.get_pos().y - (level.get_size().y*level.get_cell_size())
	player.update_limit("top",top_limit)

func ready_level():
	level.get_node("EndPos").connect("player_enter",self,"_on_win")
	for collectible in get_tree().get_nodes_in_group("Collectibles"):
		collectible.connect("player_enter",self,"_on_pickup")

func ready_player():
#	player.set_darkness(true,OS.get_window_size()*3)
	player.set_pos( level.get_node("StartPos").get_pos() )
	var level_pos = level.get_pos()
	var cell_size = level.get_cell_size()
	var level_size = level.get_size() * cell_size
	player.set_limits( level_pos.x, level_pos.x+level_size.x, level_pos.y+cell_size*3 )
	player.set_process(true)

func _on_pickup( pickup_type, _player ):
	if pickup_type == "IncEnergy":
		# increase our energy
		pass

func _on_win(_player):
	dprint("YOU WIN!")
	get_node("../Menu").show()
	queue_free()


func dprint( s ):
	s = str(s)
	print("[game.gd] ",s)
