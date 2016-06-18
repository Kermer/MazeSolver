
extends Control

var sub_menu = [0,"Main"]

func _ready():
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
	start_level("level_001.tscn")

func start_level(file_name):
	var game = preload("res://scenes/game.tscn").instance()
	get_parent().add_child(game)
	game.start_classic(file_name)
	hide()

func _go_back():
	if get_parent().has_node("Game"):
		pass
	elif sub_menu[0] == 1:
		get_node(sub_menu[1]).hide()
		get_node("Main").show()
		sub_menu = [0,"Main"]
