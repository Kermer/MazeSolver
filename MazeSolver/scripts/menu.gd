
extends Control

var sub_menu = [0,"Main"]

func _ready():
	get_parent().connect("resized",self,"_resized")
	get_tree().set_auto_accept_quit(false)
	for child in get_node("Main").get_children():
		if child extends BaseButton:
			child.connect("pressed",self,"_on_"+child.get_name()+"_pressed")
	for child in get_node("Start").get_children():
		if child extends BaseButton:
			child.connect("pressed",self,"_on_Start_"+child.get_name())
	
	for c in get_children():
		if c extends Control:
			c.hide()
	get_node("Main").show()


func _on_BStart_pressed():
	get_node("Main").hide()
	get_node("Start").show()
	sub_menu = [1,"Start"]

func _on_Start_BEndless():
	var game = preload("res://scenes/game.tscn").instance()
	get_parent().add_child(game)
	game.start_endless()
	hide()

func _on_Start_BClassic():
	get_node("Start").hide()
	get_node("LevelSelection").show()
	sub_menu = [2,"LevelSel"]

func start_level(file_name,index=-1):
	var game = preload("res://scenes/game.tscn").instance()
	get_parent().add_child(game)
	game.start_classic(file_name,index)
	hide()

func game_over():
	if sub_menu[1] == "LevelSel":
		get_node("LevelSelection").show()
	show()

func _notification(what):
	if what == 7: # WM_QUIT_REQUEST
		_go_back()

func _on_BQuit_pressed():
	print("BQuit pressed")
	_go_back()

func _go_back():
	if get_parent().has_node("Game"):
		get_parent().get_node("Game").queue_free()
		show()
		if sub_menu[1] == "LevelSel":
			get_node("LevelSelection").show()
	elif sub_menu[0] == 2:
		if sub_menu[1] == "LevelSel":
			get_node("LevelSelection").hide()
			get_node("Start").show()
			sub_menu = [1,"Start"]
	elif sub_menu[0] == 1:
		get_node(sub_menu[1]).hide()
		get_node("Main").show()
		sub_menu = [0,"Main"]
	elif sub_menu[0] == 0:
		get_tree().quit()

func _resized(default,current,mult):
	var default_scale = current/default
	var min_scale = Vector2(mult,mult)
	
	# Background
	var scale = default_scale
	get_node("Background").set_scale(scale)
	scale = min_scale
	# MAIN MENU
	var logo = get_node("Main/Logo")
	logo.set_scale(scale*0.7) # 0.7 is the default scale
	var logo_size = logo.get_texture().get_size() * logo.get_scale()
	logo.set_pos( Vector2(current.x/2, logo_size.y/2 + (160*mult)) ) # default +160 (y) from the top
		# buttons
	var bpos = Vector2(default.x/2,480) * default_scale
	var bseparator = 64 * default_scale.y
	for button in get_node("Main").get_children():
		if button extends BaseButton:
			button.set_texture_scale(scale*0.8)
			button.set_size(Vector2(1,1)) # update to get the min size
			var bsize = button.get_size().floor()
			button.set_pos( bpos-Vector2(bsize.x/2,0) )
			bpos += Vector2(0,bsize.y+bseparator)
	
	# LEVEL SELECTION
	# laziness loop here ^^
	get_node("LevelSelection/Scaling").set_scale(min_scale)
	get_node("LevelSelection/Scaling").set_pos( current/2 )
#	var labels = [ get_node("LevelSelection/Label"), get_node("LevelSelection/Completed") ] 
#	for i in range(labels.size()):
#		var label = labels[i]
#		label.set_size( Vector2(current.x, label.get_size().y) ) # text will auto-center itself
#		label.set_pos( Vector2(0, 160*mult + i*160*mult) ) # +160 from top
	
	
