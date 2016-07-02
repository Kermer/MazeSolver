
extends Node2D

var level = null
var level_type = ""
onready var player = get_node("Player")

var player_energy = 100
var energy_lose_rate = 3

func _ready():
	get_node("StartTimer").connect("timeout",self,"set_process",[true])
	pass

func add_energy( amount ):
	player_energy += amount
	player_energy = clamp(player_energy,0,100)
	update_energy()
	if player_energy == 0:
		_on_lose()

func update_energy():
	get_node("CL/Energy").set_value(round(player_energy))
	var light_scale = lerp(0.4,1.2, player_energy/100)
	player.get_node("Light").set_scale(Vector2(light_scale,light_scale))

func _process(delta):
	if player_energy > 0:
		add_energy( -delta*energy_lose_rate ) # lose 4 energy / second

func start_endless():
	level_type = "endless"
	level = preload("res://scenes/maze_infinite.tscn").instance()
	level.player = player
	var cell_size = level.get_cell_size()
	var part_height = 16
	var width = Globals.get("display/width")/cell_size + 1
	add_child(level)
	move_child(level,0)
	level.generate(part_height,width)
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
	for end_pos in level.get_node("EndPos").get_children():
		end_pos.connect("player_enter",self,"_on_win")
	for collectible in get_tree().get_nodes_in_group("Collectibles"):
		collectible.connect("player_enter",self,"_on_pickup")

func ready_player():
	player.set_pos( level.get_node("StartPos").get_pos() )
	var level_pos = level.get_pos()
	var cell_size = level.get_cell_size()
	var level_size = level.get_size() * cell_size
	player.set_limits( level_pos.x, level_pos.x+level_size.x, level_pos.y+cell_size*3 )
	player.set_process(true)
	update_energy()

func _on_pickup( pickup_type, _player ):
	if pickup_type == "IncEnergy":
		add_energy(20)
		pass

func _on_win(_player):
	dprint("YOU WIN!")
	get_node("../Menu").show()
	queue_free()

func _on_lose():
	dprint("YOU LOSE!")
	get_node("../Menu").show()
	queue_free()


func dprint( s ):
	s = str(s)
	print("[game.gd] ",s)
