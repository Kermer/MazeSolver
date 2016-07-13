
extends PopupPanel


func _ready():
	for c in get_children():
		if c extends BaseButton:
			c.connect("pressed",self,"_on_"+c.get_name()+"_pressed")

func _on_BContinue_pressed():
	get_tree().set_pause(false)
	hide()

func _on_BQuit_pressed():
	get_tree().set_pause(false)
	get_node("../..")._on_quit() # Game

func popup(): # override
	get_tree().set_pause(true)
	.show()

func show(): # override
	popup()


