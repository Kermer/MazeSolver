
extends Control

var sub_menu = [0,"Main"]

func _ready():
	get_tree().set_auto_accept_quit(false)
	for child in get_node("Main").get_children():
		if child extends Button:
			child.connect("pressed",self,"_on_"+child.get_name()+"_pressed")
	for child in get_node("Start").get_children():
		if child extends Button:
			child.connect("pressed",self,"_on_Start_"+child.get_name())
	
	for c in get_children():
		if c.has_method("hide"):
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

func start_level(file_name):
	var game = preload("res://scenes/game.tscn").instance()
	get_parent().add_child(game)
	game.start_classic(file_name)
	hide()

func _notification(what):
	if what == 7: # WM_QUIT_REQUEST
		_go_back()

func _on_BQuit_pressed():
	_go_back()

func _go_back():
	if get_parent().has_node("Game"):
		get_parent().get_node("Game").queue_free()
		show()
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
