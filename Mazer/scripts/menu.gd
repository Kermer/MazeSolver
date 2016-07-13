
# This script handles most of the Menu interactions as well as resizing and rescaling it

extends Control

var sub_menu = [0,"Main"] # holds info about menu being shown right now

func _ready():
	get_tree().set_auto_accept_quit(false) # disable auto app quit on back button (Android) pressed
	get_parent().connect("resized",self,"_resized")
	# Connect all the buttons from 'Main' menu
	for child in get_node("Main").get_children():
		if child extends BaseButton:
			child.connect("pressed",self,"_on_"+child.get_name()+"_pressed")
	# Connect all the buttons from 'Start' menu
	for child in get_node("Start").get_children():
		if child extends BaseButton:
			child.connect("pressed",self,"_on_Start_"+child.get_name())
	
	get_node("LevelSelection/BHome").connect("pressed",self,"_go_back")
	
	# Show 'Main' menu when menu is loaded
	for c in get_children():
		if c extends Control:
			c.hide()
	get_node("Main").show()

# 'Main' menu: play pressed -> Goto 'Start' menu
func _on_BStart_pressed():
	get_node("Main").hide()
	get_node("Start").show()
	sub_menu = [1,"Start"]

# 'Start' menu: endless mode selected -> load game.tscn and start endless mode
func _on_Start_BEndless():
	var game = preload("res://scenes/game.tscn").instance()
	get_parent().add_child(game)
	game.start_endless()
	hide()

# 'Start' menu: classic mode selected -> Goto 'LevelSelection' menu
func _on_Start_BClassic():
	get_node("Start").hide()
	get_node("LevelSelection").show()
	sub_menu = [2,"LevelSel"]

func _on_Start_BHome():
	_go_back()

# 'LevelSelection' menu -> some level has been selected
func start_level(file_name,index=-1):
	var game = preload("res://scenes/game.tscn").instance()
	get_parent().add_child(game)
	game.start_classic(file_name,index)
	hide()

# Triggered from 'game.gd', when we win/lose/quit the game
func game_over():
	if sub_menu[1] == "LevelSel":
		get_node("LevelSelection").show() # this show() is overriden ( check 'level_selection.gd' )
	show()

# Used to handle window related signals like quit request or window minimalize
const QUIT_REQUEST = 7 # Check 'MainLoop' constants
const FOCUS_OUT = 6
func _notification(what):
	if what == QUIT_REQUEST: # WM_QUIT_REQUEST
		_go_back()
	elif what == FOCUS_OUT:
		if get_parent().has_node("Game"):
			# pause the game if got minimalized
			var game = get_parent().get_node("Game")
			game._on_BPause_pressed()

# 'Main' menu: exit button pressed -> behave same as back button was pressed
func _on_BQuit_pressed():
	_go_back()

# This is general "go_back" function.
# It handles almost all of the back/home/quit buttons as well as the android back button/window "X" pressed/etc.
func _go_back():
	if get_parent().has_node("Game"):
		# if we are in game -> show pause menu
		var game = get_parent().get_node("Game")
		game._on_BPause_pressed() # simulate pause button press
	elif sub_menu[0] == 2:
		# if we are at level 2 menu
		if sub_menu[1] == "LevelSel":
			get_node("LevelSelection").hide()
			get_node("Start").show()
			sub_menu = [1,"Start"]
	elif sub_menu[0] == 1:
		# if we are at level 1 menu ( currently 'Start' or 'Settings' )
		get_node(sub_menu[1]).hide()
		get_node("Main").show()
		sub_menu = [0,"Main"]
	elif sub_menu[0] == 0:
		# if we are at main menu -> quit the app
		get_tree().quit()

# Fired after window got resized (this will fire just once on mobile devices) and sizes have been computed inside 'init.gd'
func _resized(default,current,mult):
	var default_scale = current/default # this is scale which might stretch our objects
	var min_scale = Vector2(mult,mult) # this is maximum scale in which we keep the same ratio (1:1)
	
	# Resize(stretch) menu 'Background'
	var scale = default_scale
	get_node("Background").set_scale(scale)
	scale = min_scale
	
	# Resize 'Main' menu
	var logo = get_node("Main/Logo")
	logo.set_scale(scale*0.7) # (default: 0.7) 'scale=min_scale' - keep the ratio of logo
	var logo_size = logo.get_texture().get_size() * logo.get_scale()
	logo.set_pos( Vector2(current.x/2, logo_size.y/2 + (160*mult)) ) # (default(Y): 160px from top) - center the logo on X and move it down a bit from the top edge
	# 	Scale and move 'Main' menu buttons
	var bpos = Vector2(default.x/2,480) * default_scale
	var bseparator = 64 * default_scale.y
	for button in get_node("Main").get_children():
		if button extends BaseButton:
			button.set_texture_scale(scale*0.8)
			button.set_size(Vector2(1,1)) # to update the real size
			var bsize = button.get_size().floor()
			button.set_pos( bpos-Vector2(bsize.x/2,0) )
			bpos += Vector2(0,bsize.y+bseparator)
	
	# Resize 'Start' menu
	var bhome = get_node("Start/BHome")
	bhome.set_texture_scale(0.5*min_scale)
	bhome.set_size(Vector2(1,1))
	bhome.set_global_pos( Vector2(32,current.y-bhome.get_size().y-32) )
	
	# Resize 'LevelSelection' menu
	get_node("LevelSelection").set_scale(min_scale)
	var size = get_node("LevelSelection").get_size()
	get_node("LevelSelection").set_pos(Vector2((current.x-size.x*mult)/2,0))
	var bhome = get_node("LevelSelection/BHome")
	bhome.set_size(Vector2(1,1))
	bhome.set_global_pos( Vector2(32,current.y-bhome.get_size().y*mult-32) )
	
	
