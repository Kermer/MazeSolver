
# This script/scene handles... well... the gameplay

extends Node2D

onready var pause_menu = get_node("CL/Pause")

var level = null # holds reference to our level
var level_type = "" # classic/endless
var level_index = -1 # index of 'classic' map, from 'level_selection.gd' 'levels' array
onready var player = get_node("Player")

var player_energy = 100 # 100%
var energy_lose_rate = 3 # amount of energy lost per second

func _ready():
	# StartTimer is used to wait 1 sec before energy starts decreasing
	get_node("StartTimer").connect("timeout",self,"set_process",[true])
	get_node("CL/Analog").connect("value_changed",player,"set_movement")
	get_node("CL/BPause").connect("pressed",self,"_on_BPause_pressed")
	get_parent().connect("resized",self,"_resized")

# Add or remove energy
func add_energy( amount ):
	player_energy += amount
	player_energy = clamp(player_energy,0,100) # keep it between 0 and 100
	update_energy() # update display
	if player_energy == 0:
		_on_lose()

func update_energy():
	get_node("CL/Energy").set_value(round(player_energy)) # Update the % bar
	# modify player's light range (scale of 0.5 to 1.8)
	var light_scale = lerp(0.5,1.8, player_energy/100) 
	light_scale = Vector2(light_scale,light_scale)
	player.get_node("Light").set_scale(light_scale)

# Decrease energy per frame
func _process(delta):
	if player_energy > 0:
		add_energy( -delta*energy_lose_rate ) # lose X energy / second

# Start the infinite maze
func start_endless():
	level_type = "endless"
	level = preload("res://scenes/maze_infinite.tscn").instance()
	level.player = player
	var cell_size = level.get_cell_size()
	var part_height = 16
	var width = Globals.get("display/width")/cell_size + 1 # used to tell 'maze.gd' how wide the maze should be
	add_child(level)
	move_child(level,0)
	level.generate(part_height,width)
	ready_player()

# Start the classic mode
func start_classic( file_name,index=-1 ):
	var level_scene = load("res://levels/"+file_name)
	if level_scene == null:
		dprint(str("Failed to load level. file_name=\"",file_name,"\""))
		return
	level_type = "classic"
	level_index = index
	level = level_scene.instance()
	add_child(level)
	move_child(level,0)
	ready_level()
	ready_player()
	var sizes = get_parent().get_sizes()
	_resized(sizes[0],sizes[1],sizes[2])

# Prepare the "classic" level
func ready_level():
	# connect 'EndPos'
	for end_pos in level.get_node("EndPos").get_children():
		end_pos.connect("player_enter",self,"_on_win")
	# connect 'Collectibles'
	for collectible in get_tree().get_nodes_in_group("Collectibles"):
		collectible.connect("player_enter",self,"_on_pickup")

# Prepare player
func ready_player():
	# move him to start pos
	player.set_pos( level.get_node("StartPos").get_pos() )
	# and enable his movement
	player.set_process(true)
	update_energy()

# Triggered when some Collectible got picked up
func _on_pickup( pickup_type, _player ): # _player probably will stay unused, it just returns player object which collected it
	if pickup_type == "IncEnergy":
		add_energy(20)

# Triggered when some player enters the 'EndPos' area
func _on_win(_player):
	dprint("YOU WIN!")
	get_node("../Menu").game_over()
	if level_index > -1:
		var new_count = level_index+1
		var current_count = Config.get_val("levels_completed")
		if new_count > current_count: # if we completed new level
			# update amount of completed levels
			Config.set_val("levels_completed",new_count)
	queue_free() # delete 'Game' scene

# Triggered when energy == 0
func _on_lose():
	dprint("YOU LOSE!")
	get_node("../Menu").game_over()
	queue_free()

# Currently only triggered when 'BQuit' from 'Pause' menu is pressed
func _on_quit():
	dprint("Going back to menu...")
	get_node("../Menu").game_over()
	queue_free()

# Pause pressed
func _on_BPause_pressed():
	pause_menu.popup()
	get_node("CL/Analog").deactivate() # temporarily hide the analog

const def_camera_zoom = 0.4 * Vector2(1,1)
func _resized(default,current,mult):
	update_camera_limits()
	pause_menu.set_scale(Vector2(mult,mult))
	var psize = pause_menu.get_size() * mult
	var ppos = Vector2(104,228) * mult # (default(from top(Y)): 228)
	ppos.x = (current.x-psize.x)/2
	pause_menu.set_pos(ppos)
	get_node("CL/BPause").set_scale( Vector2(0.8,0.8) * mult ) # (default: 0.8)
	get_node("CL/Analog").set_scale( Vector2(1.3,1.3) * mult ) # (default: 1.2)
	var energy_bar = get_node("CL/Energy")
	energy_bar.set_scale( Vector2(1.5,1.5) * mult )
	energy_bar.set_pos( Vector2(64,current.y - energy_bar.get_size().y*energy_bar.get_scale().y - 64) )
	var camera = player.get_node("Camera")
	camera.set_zoom( def_camera_zoom / mult )

# Get the new camera limits (based on window size) and pass them to player's camera
func update_camera_limits():
	if level == null:
		return
	var level_pos = level.get_pos()
	var cell_size = level.get_cell_size()
	var level_size = level.get_size() * cell_size
	var window_size = OS.get_window_size()
	# if window is bigger than level -> center the camera
	if window_size.x > level_size.x:
		var diff = (window_size.x-level_size.x)
		level_pos.x -= diff/2
		level_size.x += diff
	if window_size.y > level_size.y:
		var diff = (window_size.y-level_size.y)
		level_pos.y -= diff/2
		level_size.y += diff
	player.set_limits( level_pos.x, level_pos.x+level_size.x, cell_size*3, -level_size.y-cell_size*3 )

# all the d(ebug)print functions will have some additional functionality later on (like displaying popup or something like that)
func dprint( s ):
	s = str(s)
	print("[game.gd] ",s)
